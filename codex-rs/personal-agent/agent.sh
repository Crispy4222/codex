#!/bin/bash
# Personal Agent - Shell Version (Zero dependencies, works NOW)
# Your AI command-line interface - talk to me instead of typing

set -e

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
MODEL="${MODEL:-orca-mini}"
GARAGE="${GARAGE:-$HOME/GARAGE}"
AGENT_HOME="${AGENT_HOME:-$HOME/.agent}"
CHAT_LOG="${AGENT_HOME}/session.log"
DOWNLOADS="${DOWNLOADS:-$GARAGE/downloads}"

mkdir -p "$AGENT_HOME" "$DOWNLOADS"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

doctor() {
    echo -e "\n${YELLOW}🏥 System Check${NC}\n"
    
    # Check Ollama
    if timeout 2 curl -s "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Ollama: OK"
    else
        echo -e "${RED}✗${NC} Ollama: Not responding at $OLLAMA_URL"
    fi
    
    # Check Qdrant
    if timeout 2 curl -s "$QDRANT_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Qdrant: OK"
    else
        echo -e "${RED}✗${NC} Qdrant: Not responding at $QDRANT_URL"
    fi
    
    # Check knowledge paths
    if [ -d "$GARAGE" ]; then
        count=$(find "$GARAGE" -type f | wc -l)
        echo -e "${GREEN}✓${NC} Knowledge base: $count files in $GARAGE"
    else
        echo -e "${YELLOW}⚠${NC} Knowledge base: $GARAGE not found"
    fi
    
    echo ""
}

query() {
    local question="$1"
    
    if [ -z "$question" ]; then
        echo "Usage: agent query <question>"
        return 1
    fi
    
    echo -e "\n${YELLOW}⏳ Thinking...${NC}\n"
    
    # Log to session
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] USER: $question" >> "$CHAT_LOG"
    
    # Create prompt
    local prompt="You are a helpful AI assistant and command-line interface. Answer this question concisely. If the user asks you to run a command, DO IT. If they ask for files/info, provide it. Be direct and helpful:\n\n$question"
    
    # Call Ollama
    local response=$(curl -s -X POST "$OLLAMA_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"$prompt\",
            \"stream\": false,
            \"options\": {\"temperature\": 0.7, \"num_predict\": 512}
        }" | jq -r '.response // .error' 2>/dev/null || echo "Error querying Ollama")
    
    echo "$response"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AGENT: $response" >> "$CHAT_LOG"
    echo ""
}

exec_cmd() {
    local cmd="$1"
    echo -e "\n${CYAN}→ $cmd${NC}\n"
    eval "$cmd" 2>&1 || true
    echo ""
}

get_file() {
    local source="$1"
    local dest="${2:-.}"
    
    if [ -z "$source" ]; then
        echo "Usage: /get <source> [destination]"
        echo "Examples:"
        echo "  /get https://example.com/file.zip"
        echo "  /get ~/Downloads/myfile.txt $DOWNLOADS"
        return 1
    fi
    
    echo -e "\n${CYAN}⬇ Downloading: $source${NC}\n"
    
    if [[ "$source" == http* ]]; then
        curl -# -L "$source" -o "$dest/$(basename "$source")" 2>&1
    else
        cp "$source" "$dest/" 2>&1
    fi
    
    echo -e "\n${GREEN}✓ Saved to: $dest${NC}\n"
}

organize_inventory() {
    echo -e "\n${YELLOW}📦 Organizing local inventory...${NC}\n"
    
    local inventory_dirs=(
        "$GARAGE/documents"
        "$GARAGE/downloads"
        "$GARAGE/projects"
        "$GARAGE/archives"
        "$GARAGE/media"
        "$GARAGE/config"
    )
    
    for dir in "${inventory_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "  📁 Created: $dir"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Inventory organized${NC}\n"
    ls -lhd "$GARAGE"/* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
}

repl() {
    echo -e "\n${GREEN}🤖 Personal Agent - Your AI Command Line${NC}"
    echo -e "${CYAN}Type /help for commands, /exit to quit${NC}"
    echo -e "Chat naturally or use /commands. I'm your PC.\n"
    
    while true; do
        printf "${GREEN}agent${NC}> "
        read -r input
        
        case "$input" in
            "") continue ;;
            "/exit"|"/quit"|"/q") 
                echo -e "\n${CYAN}Session saved to $CHAT_LOG${NC}"
                echo -e "Goodbye!\n"; 
                break 
                ;;
            "/help") 
                echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${YELLOW}📋 File & Directory Commands:${NC}"
                echo "  /ls [path]       - List files (e.g. /ls /tmp)"
                echo "  /pwd             - Show current directory"
                echo "  /cd <path>       - Change directory"
                echo "  /cat <file>      - Read file"
                echo "  /find <term>     - Search files"
                echo -e "\n${YELLOW}📥 Download & Archive:${NC}"
                echo "  /get <src> [dst] - Download file to GARAGE"
                echo "  /downloads       - Open downloads manager"
                echo "  /organize        - Organize GARAGE inventory"
                echo -e "\n${YELLOW}🔧 System & Execution:${NC}"
                echo "  /exec <cmd>      - Run shell command"
                echo "  /doctor          - System health check"
                echo -e "\n${YELLOW}🤖 Agent Control:${NC}"
                echo "  /models          - List available models"
                echo "  /model <name>    - Switch model"
                echo "  /log             - Show chat history"
                echo "  /clear           - Clear chat log"
                echo -e "\n${YELLOW}💾 Info:${NC}"
                echo "  /garage          - Show GARAGE structure"
                echo "  /status          - System status"
                echo "  /help            - This menu"
                echo "  /exit, /quit     - Exit"
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
                ;;
            "/doctor") doctor ;;
            "/models") 
                echo -e "\n${YELLOW}🤖 Available Models:${NC}"
                timeout 5 curl -s "$OLLAMA_URL/api/tags" 2>/dev/null | jq -r '.models[].name' | sed 's/^/  /' || echo "  Error fetching models"
                echo ""
                ;;
            /model\ *)
                new_model="${input#/model }"
                MODEL="$new_model"
                echo -e "${GREEN}✓${NC} Switched to $new_model\n"
                ;;
            /ls*)
                path="${input#/ls}"
                path="${path# }"
                path="${path:-.}"
                ls -lh "$path" 2>&1 | head -20
                echo ""
                ;;
            "/pwd")
                pwd
                echo ""
                ;;
            /cd*)
                cd_path="${input#/cd }"
                cd "$cd_path" 2>&1 || echo "Failed to cd to $cd_path"
                echo ""
                ;;
            /cat*)
                file="${input#/cat }"
                file="${file# }"
                if [ -f "$file" ]; then
                    echo ""
                    head -50 "$file"
                    echo ""
                else
                    echo "File not found: $file"
                    echo ""
                fi
                ;;
            /find*)
                term="${input#/find }"
                term="${term# }"
                echo -e "\n${YELLOW}🔍 Searching for: $term${NC}\n"
                find "$HOME" -iname "*$term*" 2>/dev/null | head -15
                echo ""
                ;;
            /get*)
                args="${input#/get }"
                echo "Parsing: $args"
                set -- $args
                get_file "$1" "${2:-.}"
                ;;
            "/downloads")
                /home/crispycreations/.codex/codex/codex-rs/personal-agent/downloads-manager.sh "$DOWNLOADS"
                ;;
            "/organize")
                organize_inventory
                ;;
            /exec*)
                cmd="${input#/exec }"
                exec_cmd "$cmd"
                ;;
            "/log")
                echo -e "\n${YELLOW}📋 Chat History:${NC}\n"
                tail -30 "$CHAT_LOG" 2>/dev/null || echo "No history yet"
                echo ""
                ;;
            "/clear")
                > "$CHAT_LOG"
                echo -e "${GREEN}✓ Chat log cleared${NC}\n"
                ;;
            "/garage")
                echo -e "\n${YELLOW}📦 GARAGE Structure:${NC}\n"
                du -sh "$GARAGE"/* 2>/dev/null | sort -h
                echo ""
                ;;
            "/status")
                echo -e "\n${YELLOW}📊 System Status:${NC}"
                echo "  RAM: $(free -h | grep Mem | awk '{print $2 " (" $3 " used)"}')"
                echo "  Disk: $(df -h ~ | tail -1 | awk '{print $4 " available / " $2}')"
                echo "  Uptime: $(uptime -p)"
                echo "  Agent: $MODEL"
                echo ""
                ;;
            *)
                query "$input"
                ;;
        esac
    done
}

# Main
case "${1:-repl}" in
    doctor) doctor ;;
    query) query "${2}" ;;
    exec) exec_cmd "${2}" ;;
    repl) repl ;;
    chat) repl ;;
    # Quick model launchers
    fast) MODEL=orca-mini repl ;;
    smart) MODEL=qwen2.5-coder:7b repl ;;
    deep) MODEL=c4-personal-runtime repl ;;
    wizard) MODEL=glm-4.7-flash repl ;;
    # Shortcuts
    help|--help|-h)
        echo "Personal Agent - Your AI Command Line Interface"
        echo ""
        echo "Usage: agent <command> [args]"
        echo ""
        echo "Commands:"
        echo "  repl, chat        - Interactive mode (default)"
        echo "  doctor            - System health check"
        echo "  query <q>         - Ask a single question"
        echo "  exec <cmd>        - Run a shell command"
        echo ""
        echo "Model Launchers:"
        echo "  fast              - Quick responses (orca-mini, 1.3GB)"
        echo "  smart             - Good balance (qwen2.5-coder, 4.7GB)"
        echo "  deep              - Best quality (c4-personal-runtime, 4.7GB)"
        echo "  wizard            - Smartest (glm-4.7-flash, 19GB)"
        echo ""
        echo "Environment:"
        echo "  MODEL=<name>      - Override default model"
        echo "  OLLAMA_URL=<url>  - Ollama endpoint (default: localhost:11434)"
        echo "  QDRANT_URL=<url>  - Qdrant endpoint (default: localhost:6333)"
        echo ""
        echo "Examples:"
        echo "  agent                    # Start interactive chat"
        echo "  agent smart              # Use qwen model"
        echo "  agent query 'hello'      # Single question"
        echo "  agent exec 'ls -la /tmp' # Run command"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'agent help' for usage"
        ;;
esac
