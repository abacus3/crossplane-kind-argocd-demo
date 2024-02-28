killall kubectl

kubectl port-forward svc/grafana 8080:80 -n default &
kubectl -n argocd port-forward svc/argocd-server 8443:443 &

# Open the endpoint in the default web browser (WSL2 specific)
if [ -n "$WSL_DISTRO_NAME" ]; then
    explorer.exe "https://localhost:8443/"
fi

# Open the endpoint in the default web browser (WSL2 specific)
if [ -n "$WSL_DISTRO_NAME" ]; then
    explorer.exe "http://localhost:8080/"
fi
