#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pushing Docker images to Docker Hub...${NC}"

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker Hub username is required${NC}"
    exit 1
fi

# Get version tag (default: v1)
read -p "Enter version tag (default: v1): " VERSION
VERSION=${VERSION:-v1}

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username: ${DOCKER_USERNAME}"; then
    echo -e "${YELLOW}Not logged in to Docker Hub. Logging in...${NC}"
    docker login
fi

echo -e "${GREEN}Pushing backend image...${NC}"
docker push ${DOCKER_USERNAME}/litellm-backend:${VERSION}

echo -e "${GREEN}Pushing frontend image...${NC}"
docker push ${DOCKER_USERNAME}/litellm-frontend:${VERSION}

echo -e "${GREEN}✓ Push complete!${NC}"
echo ""
echo "Images pushed:"
echo "  - ${DOCKER_USERNAME}/litellm-backend:${VERSION}"
echo "  - ${DOCKER_USERNAME}/litellm-frontend:${VERSION}"
echo ""
echo "Next step: Update k8s/*.yaml files with your Docker Hub username"
echo "Then: oc apply -f k8s/"
