#!/usr/bin/env bash

# List of folders you want to stow
FOLDERS=("aerospace" "ideavim" "nvim" "tmux" "zsh")

# Target directory
TARGET_DIR="$HOME"

echo "Installing dotfiles..."

# Run stow for each folder
for folder in "${FOLDERS[@]}"; do
  echo "🔁 (Re-)stowing $folder -> $TARGET_DIR"
  stow -R -t "$TARGET_DIR" "$folder"
done

chmod +x ~/.tmux-startup.sh

echo "✅ Dotfiles installation complete."

