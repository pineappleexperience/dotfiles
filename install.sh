#!/usr/bin/env bash

set -e

FOLDERS=("aerospace" "bat" "ghostty" "git" "ideavim" "lazygit" "nvim" "sesh" "starship" "tmux" "zsh")

TARGET_DIR="$HOME"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname -s)"

echo "🔍 Checking prerequisites..."

if [[ "$OS" == "Darwin" ]]; then
  echo "🍎 macOS detected."

  if ! command -v brew &>/dev/null; then
    echo "⬇️ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "⬇️ Installing tools, fonts and apps from the Brewfile..."
  brew bundle --file "$DOTFILES_DIR/Brewfile"

else
  echo "🐧 Linux detected."

  # Try apt-get (can extend for other distros)
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    for pkg in stow neovim tmux zsh tree; do
      if ! dpkg -s "$pkg" &>/dev/null; then
        echo "⬇️ Installing $pkg..."
        sudo apt-get install -y "$pkg"
      else
        echo "✅ $pkg already installed."
      fi
    done
  else
    echo "⚠️ Unknown package manager. Please install dependencies manually."
  fi
fi

echo "🚀 Installing dotfiles..."

# Run stow for each folder
for folder in "${FOLDERS[@]}"; do
  echo "🔁 (Re-)stowing $folder -> $TARGET_DIR"
  stow -R -d "$DOTFILES_DIR" -t "$TARGET_DIR" "$folder"
done


# bat and delta load the Rosé Pine themes from bat's cache
if command -v bat &>/dev/null; then
  bat cache --build
fi

echo "✅ Dotfiles installation complete."
