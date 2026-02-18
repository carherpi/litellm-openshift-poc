#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get Docker Hub username
read -p "Enter your Docker Hub username (default: carlosmw): " DOCKER_USERNAME
DOCKER_USERNAME=${DOCKER_USERNAME:-carlosmw}

# Get version tag
read -p "Enter version tag (default: v4): " VERSION
VERSION=${VERSION:-v4}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Full redeploy: ${DOCKER_USERNAME}/*:${VERSION}${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Step 1: Delete current deployment
echo -e "${GREEN}Step 1/5: Deleting current deployment...${NC}"
oc delete -f k8s/ 2>/dev/null || echo "Nothing to delete"
echo ""

# Step 2: Remove old images
echo -e "${GREEN}Step 2/5: Removing old local images...${NC}"
docker rmi ${DOCKER_USERNAME}/litellm-backend:${VERSION} 2>/dev/null || true
docker rmi ${DOCKER_USERNAME}/litellm-frontend:${VERSION} 2>/dev/null || true
echo ""

# Step 3: Build new images
echo -e "${GREEN}Step 3/5: Building images for linux/amd64...${NC}"
docker buildx build --platform linux/amd64 --tag ${DOCKER_USERNAME}/litellm-backend:${VERSION} --load ./backend
docker buildx build --platform linux/amd64 --tag ${DOCKER_USERNAME}/litellm-frontend:${VERSION} --load ./frontend
echo ""

# Step 4: Push to Docker Hub
echo -e "${GREEN}Step 4/5: Pushing to Docker Hub...${NC}"
docker push ${DOCKER_USERNAME}/litellm-backend:${VERSION}
docker push ${DOCKER_USERNAME}/litellm-frontend:${VERSION}
echo ""

# Step 5: Deploy to OpenShift
echo -e "${GREEN}Step 5/5: Deploying to OpenShift...${NC}"
oc apply -f k8s/
echo ""

# Show status
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Watching pods (Ctrl+C to exit)..."
oc get pods -w
