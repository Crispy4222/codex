#!/bin/bash
# Downloads Manager - Organize and access your files
# Lives in ~/GARAGE/downloads

set -e

DOWNLOADS_HOME="${1:-$HOME/GARAGE/downloads}"
mkdir -p "$DOWNLOADS_HOME"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Downloads Manager                 ║${NC}"
    echo -e "${GREEN}║     $DOWNLOADS_HOME${NC}${GREEN}      ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1${NC} - Browse downloads"
    echo -e "${CYAN}2${NC} - Show by type (images, docs, code, etc)"
    echo -e "${CYAN}3${NC} - Show recent (last 30 days)"
    echo -e "${CYAN}4${NC} - Show largest files"
    echo -e "${CYAN}5${NC} - Search downloads"
    echo -e "${CYAN}6${NC} - Open in file manager"
    echo -e "${CYAN}7${NC} - Archive old files"
    echo -e "${CYAN}8${NC} - Organize by date"
    echo -e "${CYAN}0${NC} - Exit"
    echo ""
}

browse() {
    echo -e "\n${YELLOW}Downloads:${NC}\n"
    ls -lhS "$DOWNLOADS_HOME" | tail -n +2 || echo "No files"
    echo ""
}

by_type() {
    echo -e "\n${YELLOW}Files by Type:${NC}\n"
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f 2>/dev/null | while read -r file; do
        ext="${file##*.}"
        case "$ext" in
            jpg|jpeg|png|gif|webp|svg) echo "  📷 $(basename "$file")" ;;
            pdf|doc|docx|txt|md) echo "  📄 $(basename "$file")" ;;
            mp4|mkv|avi|mov|webm) echo "  🎬 $(basename "$file")" ;;
            mp3|wav|flac|aac) echo "  🎵 $(basename "$file")" ;;
            zip|tar|gz|rar|7z) echo "  📦 $(basename "$file")" ;;
            py|rs|js|ts|go|c|cpp|java) echo "  💻 $(basename "$file")" ;;
            *) echo "  📎 $(basename "$file")" ;;
        esac
    done | sort
    echo ""
}

recent() {
    echo -e "\n${YELLOW}Recent (last 30 days):${NC}\n"
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f -mtime -30 -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | cut -d' ' -f2- | xargs -I{} basename {} | while read -r f; do
        echo "  $(ls -lh "$DOWNLOADS_HOME/$f" | awk '{print $5, $9}')"
    done
    echo ""
}

largest() {
    echo -e "\n${YELLOW}Largest files:${NC}\n"
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f -exec ls -lhS {} + | awk '{print $5 "\t" $9}' | head -15
    echo ""
}

search() {
    printf "${YELLOW}Search term:${NC} "
    read -r term
    echo -e "\n${YELLOW}Results:${NC}\n"
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f -iname "*$term*" -exec ls -lh {} \; | awk '{print $5 "\t" $9}'
    echo ""
}

open_file_manager() {
    if command -v xdg-open &>/dev/null; then
        xdg-open "$DOWNLOADS_HOME"
    elif command -v open &>/dev/null; then
        open "$DOWNLOADS_HOME"
    else
        echo "Open in terminal: cd $DOWNLOADS_HOME"
    fi
}

archive_old() {
    echo -e "\n${YELLOW}Archiving files older than 90 days...${NC}\n"
    ARCHIVE_DIR="$DOWNLOADS_HOME/.archive/$(date +%Y-%m)"
    mkdir -p "$ARCHIVE_DIR"
    count=0
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f -mtime +90 -exec sh -c 'mv "$1" "'$ARCHIVE_DIR'" && ((count++))' _ {} \;
    echo "Archived files. Archive: $ARCHIVE_DIR"
    echo ""
}

organize_by_date() {
    echo -e "\n${YELLOW}Organizing files by date...${NC}\n"
    find "$DOWNLOADS_HOME" -maxdepth 1 -type f | while read -r file; do
        date_dir="$DOWNLOADS_HOME/$(stat -c %y "$file" | cut -d' ' -f1 | tr '-' '/')"
        mkdir -p "$date_dir"
        mv "$file" "$date_dir/"
    done
    echo "Done!"
    echo ""
}

# Main loop
while true; do
    show_menu
    printf "${MAGENTA}Choose [0-8]:${NC} "
    read -r choice
    
    case "$choice" in
        1) browse ;;
        2) by_type ;;
        3) recent ;;
        4) largest ;;
        5) search ;;
        6) open_file_manager ;;
        7) archive_old ;;
        8) organize_by_date ;;
        0) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
        *) echo -e "${YELLOW}Invalid choice${NC}"; sleep 1 ;;
    esac
    
    read -p "Press Enter to continue..."
done
