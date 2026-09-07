export EDITOR=vim
alias code='code-insiders'
alias gs='git status'
alias ga='git add'
alias gd='git diff'
alias gdc='gd --cached'
alias gc='git commit'
alias gcm='gc --amend'
alias gps='git push'
alias gl='git log --oneline'
alias gap='git add -p'
alias gco='git checkout'
alias g=git
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dc='docker compose'

dbash() {
  docker compose exec $@ bash
}
