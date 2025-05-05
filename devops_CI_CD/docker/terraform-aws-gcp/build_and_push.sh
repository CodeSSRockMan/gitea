#!/bin/bash
set -e

# ---------- Configuración ----------
DOCKER_HUB_USER="hescobarsanchez"              # Cambia esto por tu usuario real de Docker Hub
IMAGE_NAME="jenkins-agent"                 # Nombre de la imagen
IMAGE_TAG="latest"                         # Etiqueta de versión
DOCKERFILE_PATH="."                        # Ruta al Dockerfile (por defecto, el directorio actual)

# ---------- Construcción de imagen ----------
echo "[INFO] Building Docker image..."
docker build -t $DOCKER_HUB_USER/$IMAGE_NAME:$IMAGE_TAG $DOCKERFILE_PATH

# ---------- Login en Docker Hub ----------
echo "[INFO] Logging into Docker Hub..."
docker login

# ---------- Push ----------
echo "[INFO] Pushing image to Docker Hub..."
docker push $DOCKER_HUB_USER/$IMAGE_NAME:$IMAGE_TAG

echo "[SUCCESS] Docker image pushed: $DOCKER_HUB_USER/$IMAGE_NAME:$IMAGE_TAG"
