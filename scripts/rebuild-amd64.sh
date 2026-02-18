#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Rebuilding images for AMD64 only...${NC}"

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker Hub username is required${NC}"
    exit 1
fi

# Get version tag (default: v1)
read -p "Enter version tag (default: v1): " VERSION
VERSION=${VERSION:-v1}

# Remove any existing local images
echo -e "${YELLOW}Removing existing local images...${NC}"
docker rmi ${DOCKER_USERNAME}/litellm-backend:${VERSION} 2>/dev/null || true
docker rmi ${DOCKER_USERNAME}/litellm-frontend:${VERSION} 2>/dev/null || true

echo -e "${GREEN}Building backend image for linux/amd64 ONLY...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag ${DOCKER_USERNAME}/litellm-backend:${VERSION} \
  --load \
  ./backend

echo -e "${GREEN}Building frontend image for linux/amd64 ONLY...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --tag ${DOCKER_USERNAME}/litellm-frontend:${VERSION} \
  --load \
  ./frontend

echo -e "${GREEN}✓ Build complete!${NC}"
echo ""
echo "Verifying architectures:"
docker inspect ${DOCKER_USERNAME}/litellm-backend:${VERSION} | grep Architecture
docker inspect ${DOCKER_USERNAME}/litellm-frontend:${VERSION} | grep Architecture
echo ""
echo "Images created:"
echo "  - ${DOCKER_USERNAME}/litellm-backend:${VERSION}"
echo "  - ${DOCKER_USERNAME}/litellm-frontend:${VERSION}"
echo ""
echo "Next: Run ./scripts/push.sh to push to Docker Hub"
