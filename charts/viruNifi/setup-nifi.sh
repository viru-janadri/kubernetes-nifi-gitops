#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting setup for NiFi on macOS/Linux..."

# Ensure kubectl, argocd, and helm are installed
for cmd in kubectl argocd helm; do
    if ! command_exists $cmd; then
        echo "$cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# Delete existing NiFi application and resources
echo "Deleting existing NiFi resources..."
argocd app delete nifi --cascade=false || true
kubectl delete sts nifi -n nifi --ignore-not-found
kubectl delete sts nifi-zookeeper -n nifi --ignore-not-found

# Create necessary namespaces
echo "Creating required namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nifi --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install cert-manager
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Add ArgoCD repository
echo "Adding ArgoCD repository..."
argocd repo add https://github.com/viru-janadri/kubernetes-nifi-gitops.git || true

# Apply NiFi application manifest
echo "Deploying NiFi..."
kubectl apply -f apps/nifi/nifi-app.yaml

echo "Setup completed successfully!"
