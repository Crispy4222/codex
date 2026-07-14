#!/bin/bash
# Personal Agent Setup Script

echo "🤖 Personal Agent Setup"
echo "======================"
echo ""

# Check if Docker is running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Start Qdrant vector store
echo "1️⃣  Starting Qdrant vector store..."
if docker ps | grep -q qdrant; then
    echo "   ✓ Qdrant already running"
else
    docker run -d --name qdrant -p 6333:6333 qdrant/qdrant
    echo "   ✓ Qdrant started at http://localhost:6333"
fi

echo ""

# Check Ollama
echo "2️⃣  Checking Ollama..."
if command -v ollama &> /dev/null; then
    if pgrep -x "ollama" > /dev/null; then
        echo "   ✓ Ollama running"
    else
        echo "   ⚠️  Ollama installed but not running"
        echo "   Start with: ollama serve"
    fi
else
    echo "   ⚠️  Ollama not installed"
    echo "   Download: https://ollama.ai"
fi

echo ""

# Pull mistral model if not present
if command -v ollama &> /dev/null; then
    echo "3️⃣  Pulling Mistral model..."
    ollama pull mistral
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Start Ollama: ollama serve"
echo "2. Build: cargo build -p codex-personal-agent"
echo "3. Initialize: personal-agent init"
echo "4. Index: personal-agent index ~/GARAGE/logs"
echo "5. Run: personal-agent repl"
