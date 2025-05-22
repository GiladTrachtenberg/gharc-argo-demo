#!/bin/bash

set -e

echo "Setting up local demo environment for arc-demo s..."

# Create kind cluster if it doesn't exist
if ! kind get clusters | grep -q "arc-demo"; then
  echo "Creating kind cluster 'arc-demo'..."
  kind create cluster --name arc-demo
else
  echo "Kind cluster 'arc-demo' alrey exists, skipping creation."
fi

# Set kubectl context to kind cluster
kubectl config use-context kind-arc-demo

# Create namespace if it doesn't exist
if ! kubectl get namespace arc-demo &>/dev/null; then
  echo "Creating 'arc-demo' namespace..."
  kubectl create namespace arc-demo
else
  echo "Namespace 'arc-demo' alrey exists, skipping creation."
fi
