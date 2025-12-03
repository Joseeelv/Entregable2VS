#!/bin/bash

# Script para construir y publicar imagen Docker multi-arquitectura

set -e

DOCKER_USERNAME="${1:-joseeelv}"
IMAGE_NAME="matomo-custom"
TAG="latest"

echo "🏗️  Construyendo imagen multi-arquitectura para $DOCKER_USERNAME/$IMAGE_NAME:$TAG"

# Crear un nuevo builder si no existe
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

# Construir y publicar para múltiples plataformas
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag $DOCKER_USERNAME/$IMAGE_NAME:$TAG \
  --push \
  .

echo "✅ Imagen publicada exitosamente"
echo "📦 $DOCKER_USERNAME/$IMAGE_NAME:$TAG (amd64, arm64)"

# Inspeccionar la imagen
docker buildx imagetools inspect $DOCKER_USERNAME/$IMAGE_NAME:$TAG
