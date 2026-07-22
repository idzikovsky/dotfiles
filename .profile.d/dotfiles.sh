alias dotfiles="git --git-dir=$HOME/git/dotfiles.git/ --work-tree=$HOME"

#
# Environment variables
#
export EDITOR='subl --wait'

export GEM_HOME="$HOME/.gems"
export PATH="$HOME/.gems/bin:$PATH"

export KUBECONFIG="$HOME/.kube/currentconfig"

export VAGRANT_NO_PARALLEL=true

#
# Aliases
#
alias ccat='pygmentize -g -P style=solarized-light'
alias ls='ls --color=auto -w1'
alias tt='cd $(mktemp -d)'

#
# Functions
#
addcert() {
  sudo true
  openssl s_client -connect "${1}:${2}" -servername "$1" </dev/null | openssl x509 | sudo tee "/usr/local/share/ca-certificates/00custom-${1}-${2}.crt" >/dev/null
  sudo update-ca-certificates
}
