#!/bin/bash

killall kubectl

kind create cluster
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade --install crossplane \
--wait --wait-for-jobs --timeout 300s \
--namespace crossplane-system \
--create-namespace crossplane-stable/crossplane

kubectl apply -f providers/ && kubectl wait --for=condition=healthy Providers --all --timeout 300s

sleep 2

kubectl apply -f provider-configs/

sleep 5

kubectl apply -f compositions/ && kubectl wait --for=condition=offered xrds --all --timeout 300s && kubectl wait --for=condition=established xrds --all --timeout 300s


kubectl apply -f claims/infra-bundle.yaml && kubectl wait --for=condition=ready -f claims/infra-bundle.yaml --timeout 600s

sleep 10

kubectl wait --for=condition=available deployment argocd-server --timeout 300s -n argocd

# Add ArgoCD User for provider-argocd default ProviderConfig
kubectl patch configmap/argocd-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"accounts.provider-argocd":"apiKey"}}'

kubectl patch configmap/argocd-rbac-cm \
  -n argocd \
  --type merge \
  -p '{"data":{"policy.csv":"g, provider-argocd, role:admin"}}'

kubectl -n argocd port-forward svc/argocd-server 8443:443 & true

ARGOCD_ADMIN_SECRET=$(kubectl view-secret argocd-initial-admin-secret -n argocd -q)
ARGOCD_ADMIN_TOKEN=$(curl -k -s -X POST -k -H "Content-Type: application/json" --data '{"username":"admin","password":"'$ARGOCD_ADMIN_SECRET'"}' https://localhost:8443/api/v1/session | jq -r .token)
ARGOCD_PROVIDER_USER="provider-argocd"

ARGOCD_TOKEN=$(curl -k -s -X POST -k -H "Authorization: Bearer $ARGOCD_ADMIN_TOKEN" -H "Content-Type: application/json" https://localhost:8443/api/v1/account/$ARGOCD_PROVIDER_USER/token | jq -r .token)
kubectl create secret generic argocd-credentials -n crossplane-system --from-literal=authToken="$ARGOCD_TOKEN" || true

killall kubectl

ARGOCD_ROOT_USR="admin"
ARGOCD_ROOT_PW=$(kubectl view-secret argocd-initial-admin-secret -n argocd -q)
echo "[ArgoCD] Username: $ARGOCD_ROOT_USR Password: $ARGOCD_ROOT_PW"

