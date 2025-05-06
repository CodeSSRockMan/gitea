#!/bin/bash
set -e

# ---------- Configuration ----------
DOCKER_HUB_USER="hescobarsanchez"    # Change this to your Docker Hub username
IMAGE_NAME="jenkins-agent"           # Name of the image
IMAGE_TAG="latest"                   # Image tag/version
DOCKERFILE_PATH="."                  # Path to the Dockerfile (default: current directory)

# ---------- Build Docker image ----------
echo "[INFO] Building Docker image..."
docker build -t "${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}" "${DOCKERFILE_PATH}"

# ---------- Log in to Docker Hub ----------
echo "[INFO] Logging in to Docker Hub..."
docker login

# ---------- Push Docker image ----------
echo "[INFO] Pushing image to Docker Hub..."
docker push "${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "[SUCCESS] Docker image pushed: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
