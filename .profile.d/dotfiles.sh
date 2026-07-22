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

ccrop() {
    convert "$1" -crop '2560x1440+1080+0' "$1"
}

d() {
    if [ "$1" = "c" ]; then
        sudo shutdown -c
    else
        sudo shutdown -h +$1 minutes
    fi
}

setaudio() {
    name="$1"
    nodes=$(pw-cli list-objects Node | grep -P -o '(?<=id )\d+(?=,)')
    for node_id in $nodes; do
        node_info=$(pw-cli info "$node_id")
        if ! echo "$node_info" | grep -q -i 'media.class = "Audio/Sink"'; then
            continue
        fi
        if echo "$node_info" | grep -q -i "node.description = .*${name}.*"; then
            echo "$node_info" | grep "node.description"
            wpctl set-default "$node_id"
        fi
    done
}
