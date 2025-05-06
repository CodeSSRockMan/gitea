#!/bin/bash
set -euo pipefail

# ---------- Configuration ----------
DOCKERHUB_USER="hescobarsanchez"          # Your Docker Hub username
IMAGE_NAME="ansible-agent"               # Docker image name
IMAGE_TAG="latest"                         # Image tag/version
DOCKERFILE_DIR="."                         # Path to Dockerfile directory

# Full image reference
IMAGE_REF="${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

# ---------- Build Docker image ----------
echo "[INFO] Building Docker image: ${IMAGE_REF}"
docker build -t "${IMAGE_REF}" "${DOCKERFILE_DIR}"

# ---------- Log in to Docker Hub ----------
echo "[INFO] Logging in to Docker Hub"
docker login

# ---------- Push Docker image ----------
echo "[INFO] Pushing image to Docker Hub: ${IMAGE_REF}"
docker push "${IMAGE_REF}"

echo "[SUCCESS] Docker image successfully pushed: ${IMAGE_REF}"
