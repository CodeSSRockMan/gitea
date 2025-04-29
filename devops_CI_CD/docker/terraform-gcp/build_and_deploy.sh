#!/bin/bash

# Set variables for GCP Terraform Agent
IMAGE_NAME="terraform-gcp-agent"
NAMESPACE="jenkins"
POD_NAME="terraform-gcp-agent"
DOCKERFILE_DIR="$(pwd)"

# Step 1: Connect your Docker CLI to Minikube's Docker daemon
echo "[INFO] Connecting to Minikube Docker daemon..."
eval $(minikube docker-env)

# Step 2: Build Docker image
echo "[INFO] Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME:latest "$DOCKERFILE_DIR"

# Step 3: Deploy Pod to Minikube
echo "[INFO] Applying Kubernetes Pod manifest..."
kubectl apply -f $POD_NAME.yaml -n $NAMESPACE

# Step 4: Done
echo "[SUCCESS] Build and deploy of $IMAGE_NAME completed successfully!"
