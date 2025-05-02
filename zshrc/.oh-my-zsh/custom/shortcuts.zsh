# Define widgets
clear-ls-all() {
  clear
  eza -al
  zle reset-prompt
}
zle -N clear-ls-all

clear-tree-2() {
  clear
  tree -L 2
  zle reset-prompt
}
zle -N clear-tree-2

clear-tree-3() {
  clear
  tree -L 3
  zle reset-prompt
}
zle -N clear-tree-3

fzf-buffer() {
  local selected
  selected=$(find . -type f 2> /dev/null | fzf)
  if [[ -n "$selected" ]]; then
    LBUFFER+="$selected"
  fi
}
zle -N fzf-buffer

fzf-vim() {
  clear
  local selected
  selected=$(find . -type f 2> /dev/null | fzf)
  if [[ -n "$selected" ]]; then
    vim "$selected"
  fi
  zle reset-prompt
}
zle -N fzf-vim

fzf-cd() {
  clear
  local selected
  selected=$(find . -type d 2> /dev/null | fzf)
  if [[ -n "$selected" ]]; then
    cd "$selected"
  fi
  zle reset-prompt
}
zle -N fzf-cd

print-current-date() {
  LBUFFER+=$(date -I)
}
zle -N print-current-date

print-unix-timestamp() {
  LBUFFER+=$(date +%s)
}
zle -N print-unix-timestamp

git-status() {
  clear
  git status
  zle reset-prompt
}
zle -N git-status

vi-append-clip-selection() {
  char=${RBUFFER:0:1}
  RBUFFER=${RBUFFER:1}
  RBUFFER=$char$(clippaste)$RBUFFER
}
zle -N vi-append-clip-selection

bindkey '^B' clear-ls-all
bindkey '^U' clear-tree-2
bindkey '^Z' clear-tree-3
bindkey '^F' fzf-buffer
bindkey '^V' fzf-vim
bindkey '^R' fzf-cd
bindkey '^X^T' print-current-date
bindkey '^X^D' print-unix-timestamp
bindkey '^G' git-status

bindkey -a "^O" copybuffer
bindkey -a " p" vi-append-clip-selection
