#!/usr/bin/env python3
"""Crispy Agent: a small local desktop client for Ollama."""

from dataclasses import asdict, dataclass
import json
import os
from pathlib import Path
import subprocess
import threading
import tkinter as tk
from tkinter import messagebox, ttk
from urllib import error, request


OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434").rstrip("/")
CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "crispy-agent"
SETTINGS_PATH = CONFIG_DIR / "settings.json"


@dataclass(frozen=True)
class Settings:
    model: str = "mistral:latest"
    response_tokens: int = 512
    session_tokens: int = 8192


@dataclass(frozen=True)
class Workspace:
    name: str
    path: Path
    description: str


WORKSPACE_CANDIDATES = (
    Workspace("General", Path.home(), "General local assistant"),
    Workspace(
        "C4 Construct",
        Path.home() / "PROJECTS/felix/c4_construct_ap",
        "C4 pipeline, runtime surfaces, training corpus, and operational logs",
    ),
    Workspace(
        "Roughdraft City",
        Path.home() / "CRISPYcustoms-Finesse.os/PROJECTS/games/RoughdraftCity",
        "Moto-first game project and design assets",
    ),
    Workspace(
        "Game Garage",
        Path.home() / "GARAGE/GAMES",
        "Playable prototypes, Unreal projects, Godot projects, and game hubs",
    ),
    Workspace(
        "C4 Racing & Repair",
        Path.home() / "CRISPYcustoms-Finesse.os-recover",
        "C4 racing identity, mobile mechanic copy, launch plans, and recovery tree",
    ),
    Workspace(
        "Bike Repair Lane",
        Path.home() / "GARAGE/bike_lane",
        "Measurements, photos, parts decisions, receipts, and repair notes",
    ),
    Workspace(
        "C4 Model Mesh",
        Path.home() / "GARAGE/DEVSPACE/c4_models",
        "Local models, adapters, mesh status, memory, and receipts",
    ),
)


@dataclass
class BudgetState:
    session_limit: int
    response_limit: int
    used: int = 0

    @property
    def remaining(self) -> int:
        return max(0, self.session_limit - self.used)

    @property
    def next_request_limit(self) -> int:
        return min(self.response_limit, self.remaining)

    @property
    def exhausted(self) -> bool:
        return self.remaining == 0

    def record(self, tokens: int) -> None:
        self.used = min(self.session_limit, self.used + max(0, tokens))


def load_settings(path: Path = SETTINGS_PATH) -> Settings:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return Settings(
            model=str(data.get("model", Settings.model)),
            response_tokens=max(1, int(data.get("response_tokens", Settings.response_tokens))),
            session_tokens=max(1, int(data.get("session_tokens", Settings.session_tokens))),
        )
    except (FileNotFoundError, json.JSONDecodeError, TypeError, ValueError):
        return Settings()


def save_settings(path: Path, settings: Settings) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(asdict(settings), indent=2) + "\n", encoding="utf-8")


def build_generate_payload(model: str, prompt: str, token_limit: int) -> dict:
    return {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "num_predict": token_limit,
        },
    }


def discover_workspaces(candidates=WORKSPACE_CANDIDATES) -> list[Workspace]:
    return [workspace for workspace in candidates if workspace.path.is_dir()]


def build_chat_prompt(
    history: list[tuple[str, str]], prompt: str, workspace: Workspace
) -> str:
    recent = history[-8:]
    transcript = "\n".join(f"{role}: {text}" for role, text in recent)
    return (
        "You are Crispy Agent, a direct local assistant. Be accurate, practical, and concise.\n"
        f"Selected workspace: {workspace.name}\n"
        f"Workspace path: {workspace.path}\n"
        f"Workspace purpose: {workspace.description}\n"
        "Do not claim to have inspected workspace files unless their contents were provided.\n"
        f"Recent conversation:\n{transcript}\nUser: {prompt}\nAssistant:"
    )


class OllamaClient:
    def __init__(self, base_url: str = OLLAMA_URL, timeout: int = 300):
        self.base_url = base_url
        self.timeout = timeout

    def _json_request(self, path: str, payload: dict | None = None) -> dict:
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        headers = {"Content-Type": "application/json"} if data else {}
        req = request.Request(f"{self.base_url}{path}", data=data, headers=headers)
        try:
            with request.urlopen(req, timeout=self.timeout) as response:
                return json.loads(response.read().decode("utf-8"))
        except error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Ollama returned HTTP {exc.code}: {detail}") from exc
        except error.URLError as exc:
            raise RuntimeError(f"Ollama is not reachable at {self.base_url}") from exc

    def models(self) -> list[str]:
        data = self._json_request("/api/tags")
        return [item["name"] for item in data.get("models", []) if item.get("name")]

    def generate(self, model: str, prompt: str, token_limit: int) -> tuple[str, int]:
        data = self._json_request(
            "/api/generate",
            build_generate_payload(model=model, prompt=prompt, token_limit=token_limit),
        )
        if data.get("error"):
            raise RuntimeError(str(data["error"]))
        text = str(data.get("response", "")).strip()
        tokens = max(0, int(data.get("eval_count", 0)))
        return text, tokens


class CrispyAgentApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.client = OllamaClient()
        self.settings = load_settings()
        self.budget = BudgetState(
            session_limit=self.settings.session_tokens,
            response_limit=self.settings.response_tokens,
        )
        self.history: list[tuple[str, str]] = []
        self.workspaces = discover_workspaces()
        self.workspace_by_name = {workspace.name: workspace for workspace in self.workspaces}
        self.busy = False

        self.model_var = tk.StringVar(value=self.settings.model)
        self.workspace_var = tk.StringVar(value=self.workspaces[0].name)
        self.response_var = tk.IntVar(value=self.settings.response_tokens)
        self.session_var = tk.IntVar(value=self.settings.session_tokens)
        self.status_var = tk.StringVar(value="Starting local agent...")
        self.budget_var = tk.StringVar()

        self._build_window()
        self._refresh_budget_label()
        self._run_background(self._load_models, self._models_loaded)

    def _build_window(self) -> None:
        self.root.title("Crispy Agent")
        self.root.geometry("980x700")
        self.root.minsize(760, 520)
        self.root.configure(bg="#111318")

        style = ttk.Style()
        style.theme_use("clam")
        style.configure("App.TFrame", background="#111318")
        style.configure("Panel.TFrame", background="#1a1e26")
        style.configure("Title.TLabel", background="#111318", foreground="#f5f7fa", font=("Sans", 18, "bold"))
        style.configure("Meta.TLabel", background="#111318", foreground="#8fa3b8")
        style.configure("Panel.TLabel", background="#1a1e26", foreground="#d7e0ea")
        style.configure("Accent.TButton", font=("Sans", 10, "bold"))

        main = ttk.Frame(self.root, padding=18, style="App.TFrame")
        main.pack(fill="both", expand=True)

        header = ttk.Frame(main, style="App.TFrame")
        header.pack(fill="x", pady=(0, 12))
        ttk.Label(header, text="Crispy Agent", style="Title.TLabel").pack(side="left")
        ttk.Label(header, text="LOCAL OLLAMA / NO TOKEN BILL", style="Meta.TLabel").pack(side="right")

        controls = ttk.Frame(main, padding=12, style="Panel.TFrame")
        controls.pack(fill="x", pady=(0, 12))

        ttk.Label(controls, text="Workspace", style="Panel.TLabel").grid(row=0, column=0, sticky="w")
        self.workspace_box = ttk.Combobox(
            controls,
            textvariable=self.workspace_var,
            values=[workspace.name for workspace in self.workspaces],
            state="readonly",
            width=24,
        )
        self.workspace_box.grid(row=1, column=0, padx=(0, 8), sticky="ew")
        ttk.Button(controls, text="Open folder", command=self.open_workspace).grid(
            row=1, column=1, padx=(0, 16)
        )

        ttk.Label(controls, text="Model", style="Panel.TLabel").grid(row=0, column=2, sticky="w")
        self.model_box = ttk.Combobox(controls, textvariable=self.model_var, state="readonly", width=28)
        self.model_box.grid(row=1, column=2, padx=(0, 16), sticky="ew")

        ttk.Label(controls, text="Max response tokens", style="Panel.TLabel").grid(row=0, column=3, sticky="w")
        ttk.Spinbox(controls, from_=64, to=8192, increment=64, textvariable=self.response_var, width=12).grid(
            row=1, column=3, padx=(0, 16), sticky="w"
        )

        ttk.Label(controls, text="Session output budget", style="Panel.TLabel").grid(
            row=0, column=4, sticky="w"
        )
        ttk.Spinbox(controls, from_=256, to=131072, increment=256, textvariable=self.session_var, width=12).grid(
            row=1, column=4, padx=(0, 16), sticky="w"
        )

        ttk.Button(controls, text="Apply budget", command=self.apply_budget).grid(row=1, column=5, padx=(0, 8))
        ttk.Button(controls, text="New session", command=self.new_session).grid(row=1, column=6)
        controls.columnconfigure(0, weight=1)
        controls.columnconfigure(2, weight=1)

        self.chat = tk.Text(
            main,
            wrap="word",
            state="disabled",
            bg="#0d0f14",
            fg="#e8edf3",
            insertbackground="#ffffff",
            selectbackground="#315a7d",
            relief="flat",
            padx=16,
            pady=16,
            font=("Sans", 11),
        )
        self.chat.pack(fill="both", expand=True)
        self.chat.tag_configure("user", foreground="#70c0ff", spacing1=12, font=("Sans", 11, "bold"))
        self.chat.tag_configure("agent", foreground="#a8f0c6", spacing1=12, font=("Sans", 11, "bold"))
        self.chat.tag_configure("body", foreground="#e8edf3", spacing3=8)
        self._append_message("agent", "Crispy Agent", "I am local and ready. Pick a model, set your budget, and type below.")

        composer = ttk.Frame(main, style="App.TFrame")
        composer.pack(fill="x", pady=(12, 0))
        self.input = tk.Text(
            composer,
            height=4,
            wrap="word",
            bg="#1a1e26",
            fg="#ffffff",
            insertbackground="#ffffff",
            relief="flat",
            padx=12,
            pady=10,
            font=("Sans", 11),
        )
        self.input.pack(side="left", fill="x", expand=True)
        self.input.bind("<Control-Return>", self._send_event)
        self.send_button = ttk.Button(composer, text="Send", command=self.send, style="Accent.TButton")
        self.send_button.pack(side="right", padx=(12, 0), fill="y")

        footer = ttk.Frame(main, style="App.TFrame")
        footer.pack(fill="x", pady=(8, 0))
        ttk.Label(footer, textvariable=self.status_var, style="Meta.TLabel").pack(side="left")
        ttk.Label(footer, textvariable=self.budget_var, style="Meta.TLabel").pack(side="right")

    def _run_background(self, work, done) -> None:
        def runner() -> None:
            try:
                result = work()
            except Exception as exc:  # UI boundary: display a useful error.
                self.root.after(0, lambda: self._show_error(str(exc)))
            else:
                self.root.after(0, lambda: done(result))

        threading.Thread(target=runner, daemon=True).start()

    def _load_models(self) -> list[str]:
        return self.client.models()

    def _models_loaded(self, models: list[str]) -> None:
        if not models:
            self._show_error("Ollama is running but no local models were found.")
            return
        self.model_box["values"] = models
        if self.model_var.get() not in models:
            self.model_var.set(models[0])
        self.status_var.set(f"Connected to Ollama at {OLLAMA_URL}")

    def _show_error(self, detail: str) -> None:
        self.busy = False
        self.send_button.configure(state="normal")
        self.status_var.set(detail)
        messagebox.showerror("Crispy Agent", detail)

    def open_workspace(self) -> None:
        workspace = self.workspace_by_name[self.workspace_var.get()]
        try:
            subprocess.Popen(["xdg-open", str(workspace.path)])
        except OSError as exc:
            self._show_error(f"Could not open {workspace.path}: {exc}")

    def _append_message(self, role: str, label: str, body: str) -> None:
        self.chat.configure(state="normal")
        self.chat.insert("end", f"{label}\n", role)
        self.chat.insert("end", f"{body}\n", "body")
        self.chat.configure(state="disabled")
        self.chat.see("end")

    def _refresh_budget_label(self) -> None:
        self.budget_var.set(
            f"Output: {self.budget.used:,} used / {self.budget.session_limit:,} | "
            f"{self.budget.remaining:,} remaining"
        )

    def apply_budget(self) -> bool:
        try:
            response_limit = max(1, int(self.response_var.get()))
            session_limit = max(1, int(self.session_var.get()))
        except (tk.TclError, TypeError, ValueError):
            messagebox.showwarning("Crispy Agent", "Token budgets must be whole numbers.")
            return False
        if session_limit < self.budget.used:
            messagebox.showwarning("Crispy Agent", "Session budget cannot be lower than tokens already used.")
            self.session_var.set(self.budget.session_limit)
            return False
        self.budget.response_limit = response_limit
        self.budget.session_limit = session_limit
        self.settings = Settings(
            model=self.model_var.get(),
            response_tokens=response_limit,
            session_tokens=session_limit,
        )
        save_settings(SETTINGS_PATH, self.settings)
        self._refresh_budget_label()
        self.status_var.set("Budget saved locally")
        return True

    def new_session(self) -> None:
        if self.busy:
            return
        self.history.clear()
        self.budget.used = 0
        self.chat.configure(state="normal")
        self.chat.delete("1.0", "end")
        self.chat.configure(state="disabled")
        self._append_message("agent", "Crispy Agent", "New session. The token counter is reset.")
        self._refresh_budget_label()

    def _send_event(self, _event) -> str:
        self.send()
        return "break"

    def send(self) -> None:
        if self.busy:
            return
        prompt = self.input.get("1.0", "end").strip()
        if not prompt:
            return
        if not self.apply_budget():
            return
        if self.budget.exhausted:
            messagebox.showinfo("Crispy Agent", "This session budget is exhausted. Start a new session or raise it.")
            return

        self.input.delete("1.0", "end")
        self._append_message("user", "You", prompt)
        self.busy = True
        self.send_button.configure(state="disabled")
        self.status_var.set("Thinking locally...")

        model = self.model_var.get()
        token_limit = self.budget.next_request_limit
        workspace = self.workspace_by_name[self.workspace_var.get()]
        full_prompt = build_chat_prompt(self.history, prompt, workspace)

        def generate() -> tuple[str, str, int]:
            text, tokens = self.client.generate(model, full_prompt, token_limit)
            return prompt, text, tokens

        self._run_background(generate, self._response_ready)

    def _response_ready(self, result: tuple[str, str, int]) -> None:
        prompt, text, tokens = result
        self.history.extend((("User", prompt), ("Assistant", text)))
        self.budget.record(tokens)
        self._append_message("agent", self.model_var.get(), text or "The model returned an empty response.")
        self.busy = False
        self.send_button.configure(state="normal")
        self.status_var.set(f"Response used {tokens:,} generated tokens")
        self._refresh_budget_label()
        self.input.focus_set()


def main() -> None:
    root = tk.Tk()
    CrispyAgentApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
