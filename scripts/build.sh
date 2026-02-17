#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building Docker images...${NC}"

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker Hub username is required${NC}"
    exit 1
fi

# Get version tag (default: v1)
read -p "Enter version tag (default: v1): " VERSION
VERSION=${VERSION:-v1}

echo -e "${GREEN}Building backend image for linux/amd64...${NC}"
docker build --platform linux/amd64 -t ${DOCKER_USERNAME}/litellm-backend:${VERSION} ./backend

echo -e "${GREEN}Building frontend image for linux/amd64...${NC}"
docker build --platform linux/amd64 -t ${DOCKER_USERNAME}/litellm-frontend:${VERSION} ./frontend

echo -e "${GREEN}✓ Build complete!${NC}"
echo ""
echo "Images created:"
echo "  - ${DOCKER_USERNAME}/litellm-backend:${VERSION}"
echo "  - ${DOCKER_USERNAME}/litellm-frontend:${VERSION}"
echo ""
echo "Next step: Run ./scripts/push.sh to push images to Docker Hub"
