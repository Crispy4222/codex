# Personal Agent - Setup Guide

This guide describes the current Python wrapper for Ollama and optional Qdrant integration.

## What this wrapper does

- Uses Ollama for local LLM generation
- Optionally indexes local files into Qdrant for semantic search
- Provides a small CLI: `doctor`, `query`, `index`, `repl`

## Prerequisites

- Python 3.10+ installed
- `requests` Python package
- Ollama installed and running
- Optional: `qdrant-client` and a running Qdrant service for indexing

## Install dependencies

```bash
cd /home/crispycreations/.codex/codex/codex-rs/personal-agent
python3 -m pip install requests qdrant-client
```

If you only want query/repl without indexing, install just `requests`.

## Start required services

```bash
# Start Ollama
ollama serve
```

Optional Qdrant service for indexing:

```bash
docker run -p 6333:6333 qdrant/qdrant
```

## Run the health check

```bash
python3 agent.py doctor
```

Expected output includes:
- Ollama URL
- Selected Ollama model
- Qdrant URL
- Ollama health status
- Qdrant health status or a warning if the package is missing

## Indexing your files

```bash
python3 agent.py index /path/to/your/files
```

Supported file types:
- `.rs`, `.ts`, `.js`, `.py`, `.go`, `.java`
- `.md`, `.txt`, `.toml`, `.yaml`, `.yml`, `.json`

## Querying

Single question:

```bash
python3 agent.py query "What do I have in my notes?"
```

Interactive REPL:

```bash
python3 agent.py repl
```

Type `/help` inside the REPL for commands.

## What is not supported

- PDF text extraction
- Config file loading or saving
- Plugin loading or Rust plugin architecture
- Automatic service orchestration

## Troubleshooting

### `qdrant-client` missing

If you see a warning that `qdrant-client` is not installed, install it:

```bash
python3 -m pip install qdrant-client
```

### Qdrant service not reachable

If Qdrant is installed but unavailable:

```bash
docker run -p 6333:6333 qdrant/qdrant
```

### Ollama health check fails

Ensure Ollama is running at the default port:

```bash
ollama serve
```

### Models

The wrapper chooses from available Ollama models such as `mistral`, `dolphin-mistral`, or `neural-chat`.
If Ollama is unavailable, the wrapper falls back to `mistral` but generation will fail until Ollama is reachable.

## Implementation note

The current implementation is a single Python file: `agent.py`. It discovers Ollama models and uses Qdrant only when available.
