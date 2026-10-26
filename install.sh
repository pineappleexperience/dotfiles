#!/usr/bin/env bash

set -e

FOLDERS=("aerospace" "bat" "ghostty" "git" "ideavim" "lazygit" "mise" "nvim" "sesh" "sketchybar" "starship" "tmux" "zsh")

TARGET_DIR="$HOME"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname -s)"

if [[ "$OS" != "Darwin" ]]; then
  echo "⚠️ Only macOS is supported (Homebrew casks, AeroSpace, Sketchybar)."
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "⬇️ Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "⬇️ Installing tools, fonts and apps from the Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile"

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

# mise uses the installed JDKs and installs the default Node version
export MISE_STATE_DIR="$HOME/.cache/mise/state"
"$DOTFILES_DIR/zsh/scripts/mise-link-jdks.sh"
mise install

echo "✅ Dotfiles installation complete."
