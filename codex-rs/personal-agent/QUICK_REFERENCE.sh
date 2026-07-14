#!/usr/bin/env bash
# Personal Agent - Quick Reference Card
# Print this or save it

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════╗
║                   PERSONAL AGENT - QUICK REFERENCE                      ║
║           Your AI Command Line Interface (Independent & Local)           ║
╚══════════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 LAUNCH COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

agent              Start chatting (default mode, orca-mini)
agent-menu         Interactive launcher menu
agent-fast         Quick responses (orca-mini, 1.3GB)
agent-smart        Good balance (qwen2.5-coder, 4.7GB)
agent-deep         Deep thinking (c4-personal-runtime, 4.7GB)
agent-wizard       Most intelligent (glm-4.7-flash, 19GB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ SINGLE COMMANDS (CLI)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

agent doctor                    System health check
agent query "question"          Ask a single question
agent exec "command"            Run a shell command
agent help                      Show all commands

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 INSIDE CHAT SESSION (Type these after: agent)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/help              Show all in-chat commands
/doctor            System health check
/ls [path]         List directory contents
/pwd               Show current directory
/cd <path>         Change directory
/cat <file>        Read file content
/exec <cmd>        Run shell command
/models            List available models
/model <name>      Switch to different model
/log               Show conversation history
/clear             Clear conversation log
/exit              Quit agent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 SERVICE MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

agent-service               Show service status
agent-service start         Start Ollama and Qdrant
agent-service stop          Stop services
agent-service restart       Restart services

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 USAGE EXAMPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Chat mode (talk instead of type)
$ agent
agent> what's in my downloads?
agent> /ls ~/Downloads
agent> show me the largest files
agent> /exec "ls -lhS ~/Downloads | head -10"

# Quick coding help
$ agent-smart
agent> can you help debug this error?
agent> /exec "cargo build 2>&1"
agent> [error shown]
agent> what's the fix?

# One-liner questions
$ agent query "what's my public IP?"
$ agent query "do I have enough disk space?"
$ agent exec "df -h"

# System management
$ agent> /ls /var/log
$ agent> show me the 5 largest files
$ agent> /exec "du -sh /var/log/* | sort -h | tail -5"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 FILES & PATHS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

~/.agent/session.log         Chat history (all conversations saved)
~/.agent/                    Agent home directory
~/.bashrc                    Aliases added here (agent, agent-fast, etc)
~/GARAGE/logs/               Your knowledge base (46 files, 719MB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 TIPS & TRICKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DEFAULT MODEL: orca-mini (fast, 1.3GB)
   - Works even with VS Code open
   - Good for quick questions
   - Switch anytime: /model qwen2.5-coder:7b

2. CODING: Use agent-smart
   - Better understanding than orca-mini
   - Still runs with VS Code
   - Good balance of speed vs quality

3. RAM LIMITED? Close VS Code if needed
   - Frees ~1.3GB for larger models
   - orca-mini always works

4. AFTER UPGRADING TO 16GB:
   - All 4 models work smoothly
   - No need to close VS Code
   - Productivity++ 📈

5. CHAT HISTORY:
   - Automatically saved to ~/.agent/session.log
   - Type /log to see in-chat
   - Agent remembers context

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❓ TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Slow response?
  → Model loading to RAM (first time takes 30-60 sec, normal)
  → Type: free -h (check available RAM)
  → Try: agent-fast (orca-mini is fastest)

Agent hangs?
  → Probably loading model (wait 1-2 minutes)
  → Or: close VS Code to free RAM
  → Check services: agent-service

Model not found?
  → Run: agent doctor (shows status)
  → Check Ollama: ollama list

Want to switch models?
  → Inside chat: /model orca-mini
  → Or launch: agent-smart

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ YOUR AGENT IS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Independently Owned     (Your hardware, your control)
✅ Uncensored             (No corporate filters)
✅ Private                (100% local, no cloud)
✅ Knowledgeable          (Access to 46 personal docs)
✅ Helpful                (Chat or command execution)
✅ Always Available        (No API keys, no rate limits)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready? Start with:  agent

Need details? Read:  QUICKSTART.md or SETUP_COMPLETE.md

EOF
