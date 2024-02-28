#!/bin/bash

# The Argo CD application name and namespace from the example-argp-app
application_name="grafana"
namespace="argocd"

# Set the Kubernetes service name and namespace
service_name="grafana"
service_namespace="default"

# App local port
local_port=8080

# Wait for the Argo CD application to reach a desired target status
until kubectl get app $application_name -n $namespace -o jsonpath='{.status.health.status}' | grep -q "Healthy"; do
    echo "Waiting for the Argo CD application to reach a desired target status..."
    sleep 5
done

# Wait for the service to have at least one endpoint
until [ "$(kubectl get endpoints -n $service_namespace $service_name -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)" -gt 0 ]; do
    echo "Waiting for the service to have at least one endpoint..."
    sleep 5
done

# Start port forwarding
# kubectl port-forward svc/$service_name $local_port:80 -n $service_namespace &

# Wait for the port forwarding to be established
until ! [[ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$local_port/)" =~ ^[2-3][0-9][0-9]$ ]]; do
    echo "Waiting for the port forwarding to be established..."
    sleep 5
done

grafana_usr="admin"
grafana_pw=$(kubectl view-secret $service_name admin-password -n $service_namespace -q)
echo "[Grafana] Username: $grafana_usr Password: $grafana_pw URL: https://127.0.0.1:$local_port/"

# Prepare ArgoCD endpoint access
# kubectl -n argocd port-forward svc/argocd-server 8443:443 &
argocd_root_user="admin"
argocd_root_pw=$(kubectl view-secret argocd-initial-admin-secret -n argocd -q)
echo "[ArgoCD] Username: $argocd_root_user Password: $argocd_root_pw URL: https://127.0.0.1:8443/"
