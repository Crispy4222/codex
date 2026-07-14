#!/bin/bash
# Add to your .bashrc or .zshrc to activate agent shortcuts

# Personal Agent shortcuts
export AGENT_HOME="$HOME/.agent"
mkdir -p "$AGENT_HOME"

# Main agent alias
alias agent='/home/crispycreations/.codex/codex/codex-rs/personal-agent/agent.sh'

# Quick launchers
alias agent-fast='agent fast'           # Quick chat (1.3GB)
alias agent-smart='agent smart'         # Smart chat (4.7GB)
alias agent-deep='agent deep'           # Deep thinking (4.7GB)
alias agent-wizard='agent wizard'       # Most intelligent (19GB)
alias agent-menu='/home/crispycreations/.codex/codex/codex-rs/personal-agent/launch'
alias agent-doctor='agent doctor'
alias agent-help='agent help'
alias agent-service='/home/crispycreations/.codex/codex/codex-rs/personal-agent/service'

# Auto-completion helper
_agent_complete() {
    COMPREPLY=($(compgen -W "doctor query exec repl chat fast smart deep wizard help" -- "${COMP_WORDS[1]}"))
}
complete -F _agent_complete agent

echo "✓ Personal Agent shortcuts loaded!"
echo ""
echo "Quick start:"
echo "  agent              - Start chatting"
echo "  agent-menu         - Launcher menu"
echo "  agent-fast         - Quick mode"
echo "  agent-smart        - Smart mode"
echo "  agent-deep         - Deep mode"
echo "  agent-wizard       - Maximum intelligence"
echo ""
echo "Once inside, type /help for commands"
