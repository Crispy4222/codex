#!/bin/bash
# Build Personal Agent in Docker (no Rust needed on host)

echo "🐳 Building Personal Agent in Docker..."
echo ""

cd /home/crispycreations/.codex/codex/codex-rs

# Build using Rust Docker image
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -e CARGO_HOME=/workspace/.cargo \
  rust:latest \
  cargo build -p codex-personal-agent --release

if [ -f target/release/personal-agent ]; then
    echo "✓ Build successful!"
    echo ""
    echo "Binary location: $(pwd)/target/release/personal-agent"
    echo ""
    echo "To use:"
    echo "  ./target/release/personal-agent setup"
    echo "  ./target/release/personal-agent doctor"
    echo "  ./target/release/personal-agent repl"
else
    echo "✗ Build failed"
    exit 1
fi
