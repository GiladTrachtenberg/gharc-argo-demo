#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Helm charts installation...${NC}"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for kubectl
if ! command_exists kubectl; then
  echo -e "${RED}kubectl is not installed!${NC}"
  echo "Installing kubectl..."
  brew install kubectl
else
  echo -e "${GREEN}kubectl found!${NC}"
fi

# Debug: Show available Kind clusters
echo -e "${BLUE}Available Kind clusters:${NC}"
kind get clusters || echo "No Kind clusters found"

# Check if arc-demo exists
if ! kind get clusters | grep -q "arc-demo"; then
  echo -e "${RED}Kind cluster 'arc-demo' not found!${NC}"
  echo "Please create the 'arc-demo' Kind cluster first or verify it exists"
  echo -e "${BLUE}Current kubectl contexts:${NC}"
  kubectl config get-contexts
  exit 1
else
  echo -e "${GREEN}Found arc-demo!${NC}"
fi

# Check for Helm
if ! command_exists helm; then
  echo -e "${RED}Helm is not installed!${NC}"
  echo "Installing Helm..."
  brew install helm
else
  echo -e "${GREEN}Helm found!${NC}"
  helm version
fi

# Set kubectl context to arc-demo
echo -e "${BLUE}Setting kubectl context to arc-demo...${NC}"
kubectl config use-context kind-arc-demo || {
  echo -e "${RED}Failed to set context to kind-arc-demo!${NC}"
  echo "Available contexts:"
  kubectl config get-contexts
  exit 1
}

# Install Cert-Manager
echo -e "${BLUE}Ensuring Cert-Manager operator is installed...${NC}"
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
if ! helm list -n cert-manager | grep -q "cert-manager"; then
  echo -e "${BLUE}Installing Cert-Manager operator...${NC}"
  helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.17.2 \
    --set crds.enabled=true \
    --wait
else
  echo -e "${GREEN}Cert-Manager operator already installed!${NC}"
fi

# Ensure the GH-Arc operator is installed (dependency for the cluster)
echo -e "${BLUE}Ensuring GH-Arc operator is installed...${NC}"
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update
if ! helm list -n actions-runner-controller | grep -q "actions-runner-controller"; then
  echo -e "${BLUE}Installing GH-Arc operator...${NC}"
  helm upgrade --install --namespace actions-runner-controller --create-namespace \
    --wait actions-runner-controller actions-runner-controller/actions-runner-controller
else
  echo -e "${GREEN}GH-Arc operator already installed!${NC}"
fi
