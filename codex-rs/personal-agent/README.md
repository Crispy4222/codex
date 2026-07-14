# Personal Agent - Python Ollama + Qdrant Wrapper

A lightweight Python wrapper for local Ollama and Qdrant-based personal knowledge search.

## What this is

This repository contains a minimal Python implementation of a personal agent shell.
It is not a complete Rust plugin system, and it does not currently support PDF text extraction.

The wrapper provides:
- Ollama-backed local LLM querying
- Optional Qdrant indexing and semantic search
- A small CLI for health checks, indexing, single queries, and an interactive REPL

## Quick Start

### 1. Install dependencies

```bash
cd /home/crispycreations/.codex/codex/codex-rs/personal-agent
python3 -m pip install requests
```

If you want indexing and semantic search, install Qdrant support too:

```bash
python3 -m pip install qdrant-client
```

### 2. Start services

```bash
# Start Ollama
ollama serve

# Optional: start Qdrant if you want to index files and use the knowledge base
# In another terminal:
docker run -p 6333:6333 qdrant/qdrant
```

### 3. Run the agent

```bash
python3 agent.py doctor
python3 agent.py query "What is in my knowledge base?"
python3 agent.py repl
python3 agent.py index ~/GARAGE/logs
```

## Commands

| Command | Purpose |
|---|---|
| `doctor` | Check Ollama and optional Qdrant availability |
| `query <question>` | Ask a single question from the terminal |
| `index <path>` | Index supported files into Qdrant |
| `repl` | Start an interactive terminal REPL |

## How it works

The wrapper does the following:
- Discovers an Ollama model from `http://localhost:11434` and falls back to `mistral`
- Uses Ollama embeddings and generation endpoints
- Uses Qdrant only when `qdrant-client` is installed and the service is reachable
- Indexes supported code/text files; does not extract text from PDFs

If Qdrant is unavailable or `qdrant-client` is not installed, `query` still works by forwarding the question to Ollama without knowledge-base context.

## Supported file extensions for indexing

- `.rs`, `.ts`, `.js`, `.py`, `.go`, `.java`
- `.md`, `.txt`, `.toml`, `.yaml`, `.yml`, `.json`

Excluded paths:
- `node_modules/`, `.git/`, `target/`, `dist/`, `build/`

## Limitations

- No `setup`, `init`, `plugin`, or Rust plugin commands are available in this Python wrapper
- There is no persistent config file built into `agent.py`
- PDF extraction is not implemented
- The collection is created with a fixed 384-dimensional vector schema
- Ollama and Qdrant must be manually started and reachable at the default URLs

## Troubleshooting

### Qdrant not installed or missing

If `qdrant-client` is not installed, the wrapper will still start but indexing is disabled.
Install it with:

```bash
python3 -m pip install qdrant-client
```

### Qdrant unavailable

If the package is installed but the service is not reachable:

```bash
docker run -p 6333:6333 qdrant/qdrant
```

### Ollama not responding

Make sure Ollama is running and reachable at `http://localhost:11434`:

```bash
ollama serve
```

### Slow or failed indexing

Large files and unsupported formats are skipped. Indexing is limited to the supported extensions above.

## Source file

- `agent.py` — the only Python runtime entrypoint for this wrapper

## Notes

This README documents the current Python wrapper behavior. It does not describe a complete Rust-based personal agent or plugin platform.
