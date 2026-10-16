#
# Environment variables
#
export EDITOR='subl --wait'

export PATH="$HOME/.local/bin:$PATH"

export GEM_HOME="$HOME/.gems"
export PATH="$HOME/.gems/bin:$PATH"

export KUBECONFIG="$HOME/.kube/currentconfig"

export VAGRANT_NO_PARALLEL=true

export PATH="/opt/go/current/bin:$PATH"
export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

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

d() {
    if [ "$1" = "c" ]; then
        sudo shutdown -c
    else
        sudo shutdown -h +$1 minutes
    fi
}
