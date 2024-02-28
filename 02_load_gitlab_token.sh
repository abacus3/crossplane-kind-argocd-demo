#!/bin/bash


[[ -z ${gitlab_token} ]] && echo "Please provide a gitlab_token environment variable and ensure it has a non empty value." && exit 1

kubectl create secret generic gitlab-credentials -n crossplane-system --from-literal=token=${gitlab_token} || true
