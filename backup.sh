#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counters
TOTAL_CONFIGS=8
CURRENT_CONFIG=0
SUCCESSFUL_BACKUPS=0
FAILED_BACKUPS=0

echo -e "${BLUE}🔄 Backing up current configurations...${NC}"
echo "📅 Backup started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📍 Working directory: $(pwd)"
echo "🏠 Home directory: $HOME"
echo "🖥️  System: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo "👤 User: $USER"
echo "🌿 Git branch: $(git branch --show-current 2>/dev/null || echo 'Not in git repo')"
echo "=========================================="

# Enhanced backup function
backup_config() {
    local source="$1"
    local dest="$2"
    local name="$3"

    CURRENT_CONFIG=$((CURRENT_CONFIG + 1))
    echo -e "${BLUE}[$CURRENT_CONFIG/$TOTAL_CONFIGS]${NC} Processing $name..."

    if [ -f "$source" ] || [ -d "$source" ]; then
        echo "📁 Backing up $name..."
        if cp -r "$source" "$dest/" 2>/dev/null; then
            echo -e "${GREEN}✅ $name backed up successfully${NC}"
            SUCCESSFUL_BACKUPS=$((SUCCESSFUL_BACKUPS + 1))
        else
            echo -e "${RED}❌ Failed to backup $name${NC}"
            FAILED_BACKUPS=$((FAILED_BACKUPS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  $name not found at $source${NC}"
        FAILED_BACKUPS=$((FAILED_BACKUPS + 1))
    fi
    echo ""
}

# ======= backup calls =======
backup_config "$HOME/.config/hypr" "./hyprland" "Hyprland"
backup_config "$HOME/.config/waybar" "./waybar" "Waybar"
backup_config "$HOME/.config/kitty" "./kitty" "Kitty"
backup_config "$HOME/.config/rofi" "./rofi" "Rofi"
backup_config "$HOME/wallpapers" "./wallpapers" "Wallpapers"
backup_config "$HOME/.newsboat/config" "./newsboat" "Newsboat config"
backup_config "$HOME/.newsboat/urls" "./newsboat" "Newsboat URLs"
backup_config "$HOME/.gitconfig" "./git" "Git config"

echo "=========================================="
echo -e "${GREEN}🎉 Backup completed!${NC}"
echo "📊 Summary:"
echo -e "   ${GREEN}✅ Successful: $SUCCESSFUL_BACKUPS${NC}"
echo -e "   ${RED}❌ Failed/Missing: $FAILED_BACKUPS${NC}"
echo -e "   📁 Total processed: $CURRENT_CONFIG"
echo ""

# Show file changes
changes=$(git status --porcelain | wc -l)
if [ $changes -gt 0 ]; then
    echo -e "${YELLOW}📈 Git detected $changes changed files${NC}"
else
    echo -e "${GREEN}📈 No changes detected${NC}"
fi

echo ""
echo "💡 Next steps:"
echo "   🔍 Review changes: git status"
echo "   📝 See differences: git diff"
echo "   💾 Commit changes: git add . && git commit -m 'Update configs $(date +%Y-%m-%d)'"
echo "   🚀 Push to GitHub: git push"
echo ""
echo "🔗 Repository: $(git remote get-url origin 2>/dev/null || echo 'No remote configured')"
echo "⏰ Backup completed at: $(date '+%Y-%m-%d %H:%M:%S')"
