# https://carapace-sh.github.io/carapace-bin/setup.html#nushell
$env.CARAPACE_BRIDGES = 'bash'

let out = ($nu.user-autoload-dirs | first | path join "11-carapace.nu")
let bin = (which carapace | get 0?.path)

if $bin != null {
    let bin_time = (ls ($bin | path expand) | get 0.modified)
    if not ($out | path exists) or $bin_time > (ls $out | get 0.modified) {
        carapace _carapace nushell | save --force $out
    }
}
