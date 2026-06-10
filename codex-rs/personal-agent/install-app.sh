#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_TEMPLATE="$SCRIPT_DIR/packaging/crispy-agent.desktop"
DESKTOP_FILE="$APPLICATIONS_DIR/crispy-agent.desktop"

mkdir -p "$APPLICATIONS_DIR"
sed "s|@EXEC_PATH@|$SCRIPT_DIR/launch-app|" "$DESKTOP_TEMPLATE" > "$DESKTOP_FILE"
chmod 0644 "$DESKTOP_FILE"
rm -f "$APPLICATIONS_DIR/personal-agent.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

echo "Installed Crispy Agent in the application menu."
