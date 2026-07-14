#!/usr/bin/env python3
"""
Personal Agent - Python Version
A lightweight Ollama + Qdrant wrapper for local personal knowledge search.
"""
import glob
import sys
from pathlib import Path
from typing import Optional

import requests

try:
    import qdrant_client
    from qdrant_client.models import Distance, VectorParams, PointStruct
except ImportError:
    qdrant_client = None
    Distance = None
    VectorParams = None
    PointStruct = None

DEFAULT_OLLAMA_URL = "http://localhost:11434"
DEFAULT_QDRANT_URL = "http://localhost:6333"
DEFAULT_COLLECTION = "personal-knowledge"
PREFERRED_MODELS = ("mistral", "dolphin-mistral", "neural-chat")
SUPPORTED_EXTENSIONS = {
    ".rs",
    ".ts",
    ".js",
    ".py",
    ".md",
    ".txt",
    ".go",
    ".java",
    ".toml",
    ".yaml",
    ".yml",
    ".json",
}
EXCLUDED_PATH_SEGMENTS = {"node_modules", ".git", "target", "dist", "build"}


class PersonalAgent:
    def __init__(self):
        self.ollama_url = DEFAULT_OLLAMA_URL
        self.qdrant_url = DEFAULT_QDRANT_URL
        self.collection = DEFAULT_COLLECTION
        self.model = self._discover_ollama_model()
        self.client = self._init_qdrant_client()
        self._ensure_collection()

    def _discover_ollama_model(self) -> str:
        selected_model = "mistral"
        try:
            r = requests.get(f"{self.ollama_url}/api/tags", timeout=3)
            r.raise_for_status()
            data = r.json()
            models = [
                item.get("name")
                for item in data.get("models", [])
                if isinstance(item, dict) and item.get("name")
            ]
            if models:
                for candidate in PREFERRED_MODELS:
                    if candidate in models:
                        return candidate
                return models[0]
        except Exception as exc:
            print(f"⚠️  Warning: Ollama discovery failed: {exc}")
        return selected_model

    def _init_qdrant_client(self):
        if qdrant_client is None:
            print(
                "⚠️  Warning: qdrant-client is not installed. "
                "Indexing and search are disabled until qdrant-client is installed."
            )
            return None

        try:
            requests.get(f"{self.qdrant_url}/health", timeout=2).raise_for_status()
            return qdrant_client.QdrantClient(url=self.qdrant_url)
        except Exception as exc:
            print(f"⚠️  Warning: Qdrant unavailable at {self.qdrant_url}: {exc}")

        try:
            return qdrant_client.QdrantClient(":memory:")
        except Exception as exc:
            print(f"⚠️  Warning: Failed to initialize in-memory Qdrant client: {exc}")
            return None

    def _ensure_collection(self):
        if self.client is None or PointStruct is None:
            return

        try:
            self.client.create_collection(
                collection_name=self.collection,
                vectors_config=VectorParams(size=384, distance=Distance.COSINE),
            )
            print(f"✓ Created collection: {self.collection}")
        except Exception:
            pass

    def _get_embedding(self, text: str) -> Optional[list]:
        try:
            r = requests.post(
                f"{self.ollama_url}/api/embeddings",
                json={"model": self.model, "input": text},
                timeout=30,
            )
            r.raise_for_status()
            response = r.json()
            embeddings = response.get("embeddings")
            if isinstance(embeddings, list) and embeddings:
                return embeddings[0]
        except Exception as exc:
            print(f"⚠️  Embedding error: {exc}")
        return None

    def _qdrant_ready(self) -> bool:
        if self.client is None:
            return False
        try:
            r = requests.get(f"{self.qdrant_url}/health", timeout=2)
            return r.ok
        except Exception:
            return False

    def index_files(self, path: str) -> int:
        if self.client is None:
            print(
                "Error: Qdrant client is unavailable. "
                "Install qdrant-client and start Qdrant before indexing."
            )
            return 0

        count = 0
        pattern = str(Path(path).resolve() / "**/*")

        for file_path in glob.glob(pattern, recursive=True):
            if any(segment in file_path for segment in EXCLUDED_PATH_SEGMENTS):
                continue
            if not Path(file_path).is_file():
                continue

            ext = Path(file_path).suffix.lower()
            if ext not in SUPPORTED_EXTENSIONS:
                continue

            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                if not content:
                    continue

                words = content.split()
                chunk_size = 512
                for i in range(0, len(words), chunk_size):
                    chunk = " ".join(words[i : i + chunk_size])
                    embedding = self._get_embedding(chunk)
                    if not embedding:
                        continue

                    point = PointStruct(
                        id=hash((file_path, i)) % (2**32),
                        vector=embedding,
                        payload={
                            "file": file_path,
                            "chunk": i // chunk_size,
                            "content": chunk[:500],
                        },
                    )
                    try:
                        self.client.upsert(collection_name=self.collection, points=[point])
                    except Exception:
                        pass

                count += 1
                print(f"  ✓ {file_path}")
            except Exception as exc:
                print(f"  ✗ {file_path}: {exc}")

        return count

    def query(self, question: str, top_k: int = 5) -> str:
        q_embed = self._get_embedding(question)
        if not q_embed:
            return "Error: Could not generate embedding"

        context = ""
        sources = []
        if self._qdrant_ready():
            try:
                results = self.client.search(
                    collection_name=self.collection,
                    query_vector=q_embed,
                    limit=top_k,
                    with_payload=True,
                )
            except Exception:
                results = []

            for result in results:
                payload = getattr(result, "payload", None)
                if payload:
                    context += f"Source: {payload.get('file', 'unknown')}\n"
                    context += f"{payload.get('content', '')}\n\n"
                    sources.append(payload.get('file', 'unknown'))

        prompt = "You are a helpful AI assistant."
        if context:
            prompt += "\n\nContext from knowledge base:\n" + context
        prompt += f"\nUser Question: {question}\n\nProvide a helpful answer based on the context."

        try:
            r = requests.post(
                f"{self.ollama_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.7, "num_predict": 512},
                },
                timeout=60,
            )
            r.raise_for_status()
            response = r.json().get("response", "")
            if sources:
                return f"{response}\n\n📚 Sources: {', '.join(sorted(set(sources)))}"
            return response
        except Exception as exc:
            return f"Error: {exc}"

    def repl(self):
        print("\n🤖 Personal Agent REPL")
        print("Type /help for commands\n")

        while True:
            try:
                q = input("> ").strip()
                if not q:
                    continue
                if q in ["/exit", "/quit"]:
                    print("Goodbye!")
                    break
                if q == "/help":
                    print("Commands:\n  /exit, /quit - Exit\n  Anything else - Query the agent")
                    continue

                print("\n⏳ Thinking...")
                answer = self.query(q)
                print(f"\n{answer}\n")
            except KeyboardInterrupt:
                print("\nGoodbye!")
                break
            except Exception as exc:
                print(f"Error: {exc}")

    def check_ollama(self) -> bool:
        try:
            r = requests.get(f"{self.ollama_url}/api/tags", timeout=2)
            return r.ok
        except Exception:
            return False

    def check_qdrant(self) -> bool:
        return self._qdrant_ready()


def main():
    agent = PersonalAgent()

    if len(sys.argv) < 2:
        print("Usage: python agent.py <command> [args]")
        print("Commands: repl, index <path>, query <question>, doctor")
        return

    cmd = sys.argv[1]

    if cmd == "repl":
        agent.repl()
    elif cmd == "index" and len(sys.argv) > 2:
        path = sys.argv[2]
        print(f"Indexing {path}...")
        count = agent.index_files(path)
        print(f"✓ Indexed {count} files")
    elif cmd == "query" and len(sys.argv) > 2:
        question = " ".join(sys.argv[2:])
        answer = agent.query(question)
        print(f"\n{answer}\n")
    elif cmd == "doctor":
        print("\n🏥 System Check")
        print(f"• Ollama URL: {agent.ollama_url}")
        print(f"• Selected model: {agent.model}")
        print(f"• Qdrant URL: {agent.qdrant_url}")

        print("\nChecking Ollama...")
        print("✓" if agent.check_ollama() else f"✗ Not responding on {agent.ollama_url}")

        print("\nChecking Qdrant...")
        if qdrant_client is None:
            print("⚠️  qdrant-client package is not installed.")
        print("✓" if agent.check_qdrant() else f"✗ Not responding on {agent.qdrant_url}")
        print()
    else:
        print("Unknown command: {}".format(cmd))
        print("Run 'python agent.py doctor' for a quick health check")


if __name__ == "__main__":
    main()