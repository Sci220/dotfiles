#!/bin/bash

echo "🔄 Backing up current configurations..."

# Create backup directory with timestamp
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to backup with error handling
backup_config() {
    local source="$1"
    local dest="$2"
    local name="$3"

    if [ -f "$source" ] || [ -d "$source" ]; then
        echo "📁 Backing up $name..."
        cp -r "$source" "$dest/" 2>/dev/null
        echo "✅ $name backed up"
    else
        echo "⚠️  $name not found at $source"
    fi
}

# Backup configurations
backup_config "$HOME/.config/hypr" "./hyprland" "Hyprland"
backup_config "$HOME/.config/waybar" "./waybar" "Waybar"
backup_config "$HOME/.config/kitty" "./kitty" "Kitty"
backup_config "$HOME/.config/rofi" "./rofi" "Rofi"
backup_config "$HOME/wallpapers" "./wallapers"
"Wallpapers"
backup_config "$HOME/.newsboat" "./newsboat" "Newsboat"
#backup_config "$HOME/.config/nvim" "./nvim" "Neovim"
#backup_config "$HOME/.zshrc" "./zsh" "Zsh config"
#backup_config "$HOME/.zsh_aliases" "./zsh" "Zsh aliases"
backup_config "$HOME/.gitconfig" "./git" "Git config"

# Backup custom scripts
if [ -d "$HOME/.local/bin" ]; then
    echo "📜 Backing up custom scripts..."
    cp "$HOME/.local/bin"/* "./scripts/" 2>/dev/null || echo "No custom scripts found"
fi

echo "🎉 Backup completed!"
echo "💡 Review changes with: git status"
echo "💾 Commit changes with: git add . && git commit -m 'Update configs'"
