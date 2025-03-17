# Function to check if a command exists
function Command-Exists {
    param ([string]$cmd)
    $exists = $false
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $exists = $true
    }
    return $exists
}

Write-Host "Starting setup for NiFi on Windows..."

# Ensure required tools are installed
$commands = @("kubectl", "argocd", "helm")

foreach ($cmd in $commands) {
    if (-not (Command-Exists $cmd)) {
        Write-Host "$cmd is not installed. Please install it and try again."
        exit 1
    }
}

# Delete existing NiFi application and resources
Write-Host "Deleting existing NiFi resources..."
argocd app delete nifi --cascade=false
kubectl delete sts nifi -n nifi --ignore-not-found
kubectl delete sts nifi-zookeeper -n nifi --ignore-not-found

# Create necessary namespaces
Write-Host "Creating required namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nifi --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
Write-Host "Installing ArgoCD..."
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

# Install cert-manager
Write-Host "Installing cert-manager..."
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml"

# Add ArgoCD repository
Write-Host "Adding ArgoCD repository..."
argocd repo add "https://github.com/viru-janadri/kubernetes-nifi-gitops.git"

# Apply NiFi application manifest
Write-Host "Deploying NiFi..."
kubectl apply -f "apps/nifi/nifi-app.yaml"

Write-Host "Setup completed successfully!"
