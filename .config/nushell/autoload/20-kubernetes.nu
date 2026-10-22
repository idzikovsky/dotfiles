def kubectlgetns []: nothing -> list<string> {
    kubectl get ns -o jsonpath='{.items[*].metadata.name}' | split row ' '
}
def "kubectl setns" [namespace: string@kubectlgetns]: nothing -> nothing {
    kubectl config set-context --current $"--namespace=($namespace)"
}
