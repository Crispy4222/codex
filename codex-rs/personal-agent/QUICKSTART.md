# Personal Agent - AI Command Line Interface

Your AI is now your command line. Chat instead of typing commands.

## Quick Start

```bash
# Start interactive chat (after you add the 8GB RAM)
agent

# Or use launcher menu
agent-menu

# Quick one-liner
agent query "list my projects"
agent exec "npm run dev"
```

## Installation (One-time setup)

After installing your 8GB RAM upgrade:

```bash
# The shortcuts are already added to ~/.bashrc
# Just reload your shell:
source ~/.bashrc

# Then you're ready:
agent
```

## Commands

### Launch Modes
- `agent` or `agent-menu` - Interactive menu selector
- `agent fast` - Quick responses (orca-mini, 1.3GB, works with VS Code)
- `agent smart` - Balanced (qwen2.5-coder, 4.7GB, close VS Code)
- `agent deep` - Deep thinking (c4-personal-runtime, 4.7GB)
- `agent wizard` - Most intelligent (glm-4.7-flash, 19GB, requires closing VS Code)

### Single Commands
- `agent doctor` - System health check
- `agent query "question"` - Ask something
- `agent exec "ls -la"` - Run a shell command
- `agent help` - Show all options

## Inside the Chat

Once you're talking to the agent, you have special commands:

```
/help         - Show command list
/doctor       - System check
/ls [path]    - List files (e.g., /ls /tmp)
/pwd          - Current directory
/cd <path>    - Change directory
/cat <file>   - Read a file
/exec <cmd>   - Run a shell command
/models       - List available models
/model <name> - Switch model
/log          - Show chat history
/clear        - Clear chat history
/exit         - Exit the chat
```

## Usage Examples

**Example 1: Chat mode**
```bash
$ agent
agent> what's in my downloads folder?
agent> /ls ~/Downloads

agent> show me the top 10 files
agent> /exec "ls -lhS ~/Downloads | head -10"

agent> can you help me organize these?
```

**Example 2: Smart mode (for coding questions)**
```bash
$ agent-smart
agent> explain this rust error: [paste error]

agent> /exec "cargo build"

agent> how do I fix it?
```

**Example 3: One-liner commands**
```bash
$ agent query "what's my IP?"
$ agent exec "df -h"
$ agent query "am I running out of disk space?"
```

**Example 4: Using with your knowledge base**
The agent has access to your 46 knowledge files in ~/GARAGE/logs
```bash
$ agent
agent> what do you know about my architecture?
agent> look up "Phoenix Mandate" in my knowledge base
agent> show me insights from my notes about codex
```

## System Requirements

With your 16GB RAM upgrade:
- ✓ Run all 4 models while coding
- ✓ orca-mini: 1.3GB (always available)
- ✓ qwen2.5-coder: 4.7GB (good)
- ✓ c4-personal-runtime: 4.7GB (better)
- ✓ glm-4.7-flash: 19GB (best, needs headroom)

## Chat History

All conversations are logged to `~/.agent/session.log`. You can review them anytime:

```bash
$ agent
agent> /log
```

## Troubleshooting

**"model not found" error:**
- Check available: `agent doctor`
- Models take 30-60 seconds to load first time
- If RAM is full, close VS Code: `pkill -9 code-insiders`

**Agent hangs:**
- May be loading model into RAM (normal, takes time)
- Check RAM: `free -h`
- If under 1GB free, close VS Code

**Want to switch models quickly:**
- Inside chat: `/model qwen2.5-coder:7b`
- Or launch directly: `agent-smart`

## Pro Tips

1. **Fastest workflow:** Have two terminals
   - One for `agent` (your AI)
   - One for manual commands if you need them

2. **Save context:** The agent remembers your chat history in the session
   - Ask follow-up questions naturally
   - Reference previous context

3. **Command execution:** You can ask natural language for complex tasks
   - "find all .rs files modified in the last hour"
   - "show me the 5 largest files in my home directory"
   - "what's using all my disk space?"

4. **After RAM upgrade:** All 4 models will work smoothly
   - Default to `agent-fast` for everyday use
   - Use `agent-smart` for coding help
   - Use `agent-wizard` when you need the best answer

## Your Personal Agent is:

✅ **Independently owned** - runs on your hardware  
✅ **Uncensored** - no corporate filters  
✅ **Private** - 100% local, no data sent anywhere  
✅ **Knowledgeable** - has access to all your 46 knowledge files  
✅ **Helpful** - can chat or execute commands  

Enjoy your AI command line!
