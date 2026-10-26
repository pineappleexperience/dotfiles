# Autostart tmux: attach to the running server, else start it (tmux-continuum restores the last sessions)
if [ "$TMUX" = "" ]; then
  tmux attach 2>/dev/null || tmux new-session -s projects -c "$HOME/projects"
fi

export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# --- History ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history share_history hist_ignore_dups hist_ignore_space hist_reduce_blanks

# --- Options ---
setopt auto_cd interactive_comments no_beep

# --- Completion ---
fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
autoload -Uz compinit
# rebuild the completion cache once a day, otherwise load it without checks
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Vi mode, block cursor in normal mode, beam cursor in insert mode ---
bindkey -v
# 0.2s for key sequences like ^X^T, short enough for a quick switch to normal mode with Esc
KEYTIMEOUT=20
zle-line-finish zle-line-init zle-keymap-select () {
  if [ $KEYMAP = vicmd ]; then
    echo -ne "\e[2 q"
  else
    echo -ne "\e[5 q"
  fi
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
# edit the command line in NeoVim with v in normal mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
# keep the usual history search and line editing keys in insert mode
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^?' backward-delete-char

# --- Tools ---
# Colours use the terminal's palette, so they follow the terminal theme (dark and light)
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--layout=reverse --border=rounded --height=60% --info=inline-right \
--color=fg:-1,bg:-1,hl:5,fg+:7,bg+:0,hl+:5,border:8,header:4,gutter:-1 \
--color=spinner:3,info:8,pointer:5,marker:1,prompt:4"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
source <(fzf --zsh)
# Alt+C arrives as Esc c (Option types special characters), which would hijack a quick Esc + c in vi mode
bindkey -M viins -r '\ec'

# Java and Node per project (mise.toml, .java-version, .nvmrc, .node-version), defaults in ~/.config/mise
export MISE_STATE_DIR="$HOME/.cache/mise/state"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
eval "$(starship init zsh)"

# --- Aliases and key bindings ---
source ~/.zsh/alias-expansion.zsh
source ~/.zsh/keybindings.zsh

# --- Plugins (syntax highlighting must be last) ---
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
