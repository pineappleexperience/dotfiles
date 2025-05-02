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
bindkey '^X^T' print-current-date
bindkey '^X^D' print-unix-timestamp
bindkey '^G' git-status

bindkey -a "^O" copybuffer
bindkey -a " p" vi-append-clip-selection
