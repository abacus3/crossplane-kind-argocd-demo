#!/bin/bash

# Prepare ArgoCD endpoint access
# kubectl -n argocd port-forward svc/argocd-server 8443:443 &
# argocd_root_user="admin"
# argocd_root_pw=$(kubectl view-secret argocd-initial-admin-secret -n argocd -q)
# echo "[ArgoCD] Username: $argocd_root_user Password: $argocd_root_pw URL: https://127.0.0.1:8443/"

# Open the endpoint in the default web browser (WSL2 specific)
if [ -n "$WSL_DISTRO_NAME" ]; then
    explorer.exe "https://localhost:8443/"
fi

# Simulate user claiming an platform application workspace 
kubectl apply -f claims/app-workspace.yaml && kubectl wait --for=condition=ready -f claims/app-workspace.yaml --timeout 600s

# Simulate user deploying a Helm Release

repository_url="git@gitlab.com:noli.mo/my-example-app.git"

# Wipe remote repo entirely if it exists already


# Set the target file name and location
target_file="grafana-local.yaml"

# Set the file content with normal good test cases
file_content=$(cat app/example-argo-app.yaml)

# Set the commit message
commit_message="ci(observability)[G-42]: Cluster-Local Grafana Application"

# Change to the cloned repository directory
repository_name=$(basename $repository_url .git)

# WARN: Will wipe dir named as such
rm -rf $repository_name

# Clone the repository
git clone $repository_url
cd $repository_name

# Check if the repository was successfully cloned. If so, reset it to inital empty state
if [ $? -eq 0 ]; then
    # Clone the repository to a temporary directory
    tmp_dir=$(mktemp -d)
    git clone $repository_url $tmp_dir

    # Change to the temporary directory
    cd $tmp_dir

    # Remove all branches except master and main
    git branch | grep -v -e "main" -e "master" | xargs git branch -D

    # Remove all tags
    git tag | xargs git tag -d

    # Clear the Git reflog and garbage collect
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive

    # Push the changes to the remote repository with force
    git push origin --all --force
    git push origin --tags --force
    
    ## Always cd and cleanup
    cd -
    rm -rf $tmp_dir
fi

pwd

# Preparing the user e-mail
git config --local user.email "joe@example.org"

# Preparing the user name
git config --local user.name "Joe Doe"

# Create the target file with the specified content
mkdir -p $(dirname $target_file)
echo "$file_content" > $target_file

# Stage the file
git add $target_file

# Commit the changes with the conventional commit message
git commit -m "$commit_message"

# Push the changes to the remote repository using force with lease
git push --force-with-lease origin main

