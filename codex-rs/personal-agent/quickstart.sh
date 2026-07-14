#!/bin/bash
# Quick Start for Personal Agent

set -e

echo "🚀 Personal Agent Quick Start"
echo "============================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Docker
echo -e "${YELLOW}1. Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "  Install: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

# Step 2: Start Qdrant
echo ""
echo -e "${YELLOW}2. Starting Qdrant (vector store)...${NC}"
if docker ps | grep -q qdrant; then
    echo -e "${GREEN}✓ Qdrant already running${NC}"
else
    docker run -d \
        --name qdrant \
        -p 6333:6333 \
        -v qdrant_storage:/qdrant/storage \
        qdrant/qdrant:latest
    echo -e "${GREEN}✓ Qdrant started${NC}"
    sleep 2
fi

# Step 3: Check Ollama
echo ""
echo -e "${YELLOW}3. Checking Ollama (LLM)...${NC}"
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama installed${NC}"
    
    # Check if running
    if pgrep -x ollama > /dev/null; then
        echo -e "${GREEN}✓ Ollama running${NC}"
    else
        echo -e "${YELLOW}⚠  Ollama not running${NC}"
        echo "  Start in another terminal: ollama serve"
        echo "  Then download model: ollama pull mistral"
    fi
else
    echo -e "${RED}✗ Ollama not found${NC}"
    echo "  Install: https://ollama.ai"
    echo "  After installing:"
    echo "    1. ollama serve"
    echo "    2. ollama pull mistral"
fi

# Step 4: Build
echo ""
echo -e "${YELLOW}4. Building personal-agent...${NC}"
cd /home/crispycreations/.codex/codex/codex-rs
cargo build -p codex-personal-agent --release 2>&1 | tail -10

if [ -f target/release/personal-agent ]; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Step 5: Initialize
echo ""
echo -e "${YELLOW}5. Initializing config...${NC}"
./target/release/personal-agent setup
echo ""

# Step 6: Diagnose
echo -e "${YELLOW}6. Checking system...${NC}"
./target/release/personal-agent doctor
echo ""

# Final instructions
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Index your knowledge base:"
echo "   personal-agent index ~/GARAGE/logs"
echo ""
echo "2. Start interactive mode:"
echo "   personal-agent repl"
echo ""
echo "3. Or ask a single question:"
echo "   personal-agent query 'What is in my knowledge base?'"
