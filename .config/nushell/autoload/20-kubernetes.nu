def kubectlgetns []: nothing -> list<string> {
    kubectl get ns -o jsonpath='{.items[*].metadata.name}' | split row ' '
}
def "kubectl setns" [namespace: string@kubectlgetns]: nothing -> nothing {
    kubectl config set-context --current $"--namespace=($namespace)"
}

def "docker clean" []: nothing -> table {
    let whitelist = try {
        open $"($nu.default-config-dir)/docker-whitelist" | lines --skip-empty
    } catch {
        []
    }

    (
        docker images --all --format json
            | lines
            | each { from json }
            | where Containers == "0"
            | insert full_tag {|image| $"($image.Repository):($image.Tag)" }
            | where {|image|
                not ($whitelist | any { $image.full_tag =~ $in })
            }
            | each {|image|
                print $"(ansi yellow)Cleaning ($image.full_tag)@sha256:($image.ID)...(ansi reset)"
                docker rmi (if $image.Tag != "<none>" { $image.full_tag } else { $image.ID })
                $image
            }
    )
}
