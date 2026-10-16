use std/util "path add"

#
# NuShell config
#
let gui = ($env.WAYLAND_DISPLAY? != null or $env.DISPLAY? != null)

$env.config.buffer_editor = if $gui { ["subl", "--wait"] } else { "vim" }
$env.config.show_banner = false

#
# Environment variables
#
path add ($nu.home-dir | path join ".local/bin")

$env.GEM_HOME = ($nu.home-dir | path join ".gems")
path add ($env.GEM_HOME | path join "bin")

path add "/opt/go/current/bin"
$env.GOPATH = ($nu.home-dir | path join ".go")
$env.GOBIN = ($env.GOPATH | path join "bin")
path add $env.GOBIN

$env.KUBECONFIG = ($nu.home-dir | path join ".kube/currentconfig")

$env.VAGRANT_NO_PARALLEL = true

#
# Aliases
#
alias tt = cd (mktemp -d)

#
# Custom commands
#
def "d c" []: nothing -> nothing {
    shutdown -c
}

def d [minutes: int]: nothing -> nothing {
    shutdown -h $"+($minutes)" minutes
}

def addcert [host: string, port: int = 443]: nothing -> nothing {
  sudo true
  null | openssl s_client -connect $"($host):($port)" -servername $host | openssl x509 | sudo tee $"/usr/local/share/ca-certificates/00custom-($host)-($port).crt" | ignore
  sudo update-ca-certificates
}
