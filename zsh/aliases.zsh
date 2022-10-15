# GLOBAL ALIASES

alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"

# ALIASES

alias dot="cd $DOTFILES"

alias c="coding $HOME/Code"
alias s="coding $HOME/Snippets"

alias r="ranger"
alias ka="killall"
alias :q="exit"

alias o=open

alias bsc=backup
alias pls=please

alias g-='cd $(git rev-parse --show-toplevel || echo ".")'
alias grw=git-review
alias ght=git-history
alias gfz=git-fuzzy

alias v="nvim -p"
alias vim="nvim"

alias py="ipython -i"
alias pm="python -m"

alias t=tmux
alias tc=tmux-connect
alias mux=tmuxinator

alias bs="bin/server"
alias bb="bin/build"
alias br="bin/run"
alias bt="bin/test"
alias bf="bin/format"
alias bl="bin/lint"
alias bcs="bin/console"
alias bcl="bin/clean"
alias bst="bin/setup"
alias bsr="bin/start"
alias bsp="bin/stop"

alias mk=make
alias mkh="make help"
alias mkc="make clean"
alias mkr="make run"
alias mkt="make test"

alias a="ansible"
alias ac="ansible-console"
alias ap="ansible-playbook"
