# Personal Agent - Setup Complete ✓

Your independent, uncensored AI command-line interface is ready.

## What You Have

✅ **4 AI Models** (loaded locally, ready to use)
- orca-mini (1.3GB) - Fast responses
- qwen2.5-coder (4.7GB) - Good balance
- c4-personal-runtime (4.7GB) - Deep thinking
- glm-4.7-flash (19GB) - Most intelligent

✅ **Vector Knowledge Base** (46 files from ~/GARAGE/logs)
- Semantic search over your personal documents
- Context-aware responses

✅ **Local Services**
- Ollama (LLM inference) running on :11434
- Qdrant (vector database) running on :6333

✅ **Simple Launch Controls**
- Desktop launcher
- Terminal menu
- Aliases for quick access
- Multiple execution modes

## Getting Started (After RAM Upgrade)

### Step 1: Install Your 8GB RAM
Your laptop has an empty DIMM B slot. Add a compatible DDR3-1600 SO-DIMM.

Then you'll have **16GB total** - enough for any model while coding.

### Step 2: Launch the Agent

```bash
# Option A: Desktop menu (easiest)
Click Applications > Personal Agent

# Option B: Terminal menu
agent-menu

# Option C: Direct chat
agent              # Start chatting with default model
agent-fast         # Use orca-mini (1.3GB)
agent-smart        # Use qwen2.5-coder (4.7GB)
agent-deep         # Use c4-personal-runtime (4.7GB)
agent-wizard       # Use glm-4.7-flash (19GB)
```

## How to Use

### Talk Instead of Type

```bash
agent> what's in my downloads folder?
[Agent lists files]

agent> organize these by size
[Agent provides suggestions or executes commands]

agent> show me the largest files
[Agent runs: /exec "ls -lhS ~/Downloads | head -10"]
```

### Special Commands (Inside Chat)

```
/help              Show all commands
/ls [path]         List directory
/pwd               Current directory
/cd <path>         Change directory
/cat <file>        Read file content
/exec <cmd>        Run shell command
/doctor            System health check
/models            List available AI models
/model <name>      Switch to different model
/log               Show conversation history
/clear             Clear conversation history
/exit              Quit
```

### Command Line Use

```bash
# Single queries
agent query "what's my disk usage?"
agent query "explain this error: [error text]"

# Execute commands through agent
agent exec "npm run build"
agent exec "docker ps"

# Get system info
agent doctor

# Get help
agent help
```

## File Locations

```
~/.agent/                  ← Your agent home (chat logs saved here)
~/.agent/session.log       ← Conversation history
/home/crispycreations/.codex/codex/codex-rs/personal-agent/
  ├── agent.sh             ← Main agent script
  ├── launch               ← Interactive menu
  ├── profile.sh           ← Shell aliases
  ├── QUICKSTART.md        ← Usage guide
  └── README.md            ← Full documentation
```

## Performance Tips

### For 16GB RAM (after upgrade)

**Default (orca-mini):**
- ✓ Works with VS Code open
- ✓ Fast responses (~1sec)
- ✓ Always available

**When coding (qwen2.5-coder):**
- ✓ Better responses than orca-mini
- ✓ Works with VS Code open
- ✓ Takes ~2-3 seconds

**For deep thinking (c4-personal-runtime):**
- ✓ Best quality answers
- ✓ Close VS Code for best performance
- ✓ Takes ~5-10 seconds

**Maximum intelligence (glm-4.7-flash):**
- ✓ Smartest responses
- ✓ Requires closing all heavy apps
- ✓ Takes ~10-30 seconds

## Examples

```bash
# Ask about your codebase
agent query "what's the main architecture of my project?"

# Get help with coding
agent smart
agent> /exec "cargo build"
agent> [error output appears]
agent> why did cargo fail?

# System management
agent> /ls ~/projects
agent> show me only directories
agent> /exec "du -sh ~/projects/*"
agent> which folder is taking the most space?

# Knowledge base queries
agent> what's in the Phoenix Mandate document?
agent> summarize my GPT conversations
agent> analyze my codex architecture notes
```

## Your Agent is:

| Feature | Status |
|---------|--------|
| Independently owned | ✅ Runs on your hardware |
| Uncensored | ✅ No corporate filters |
| Private | ✅ 100% local, no cloud |
| Knowledgeable | ✅ Your 46 knowledge files |
| Always available | ✅ No API keys needed |
| Learns from context | ✅ Remembers chat history |
| Can execute commands | ✅ Runs shell/system commands |
| Multi-model | ✅ 4 models to choose from |

## Next Steps

1. **Install 8GB RAM** → Gives you 16GB total
2. **Restart your PC** → New RAM recognized
3. **Launch agent:** `agent` or `agent-menu`
4. **Start chatting** - Type naturally, use `/commands` as needed

## Troubleshooting

**Q: Agent is slow?**
A: Model is loading into RAM (takes 30-60 seconds first time). Check `free -h`. If under 1GB free, close VS Code.

**Q: "Model not found" error?**
A: Check `agent doctor`. Models may still be downloading.

**Q: Want to switch models mid-conversation?**
A: Inside chat, type `/model qwen2.5-coder:7b` to switch instantly.

**Q: Chat history missing?**
A: Check `~/.agent/session.log` - all conversations are saved.

**Q: Can I use this without upgrading RAM?**
A: Yes! orca-mini (1.3GB) works right now with VS Code. After RAM upgrade, use bigger models.

## Support

- See `QUICKSTART.md` for detailed usage examples
- Type `agent help` to see all commands
- Type `/help` inside a chat session for in-chat commands

---

Your independent, private, uncensored AI command-line is ready. **Enjoy!**
