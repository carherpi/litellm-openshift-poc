#!/bin/bash

# Build Docker images for OpenShift demo application
# Usage: ./build.sh [VERSION]

set -e

VERSION=${1:-latest}
REGISTRY=${REGISTRY:-quay.io}
NAMESPACE=${NAMESPACE:-your-namespace}

echo "Building images with version: $VERSION"

# Build backend image
echo "Building backend image..."
docker build -t ${REGISTRY}/${NAMESPACE}/openshift-demo-backend:${VERSION} \
  -f backend/Dockerfile backend/

# Build frontend image
echo "Building frontend image..."
docker build -t ${REGISTRY}/${NAMESPACE}/openshift-demo-frontend:${VERSION} \
  -f frontend/Dockerfile frontend/

echo "Build complete!"
echo "Backend image: ${REGISTRY}/${NAMESPACE}/openshift-demo-backend:${VERSION}"
echo "Frontend image: ${REGISTRY}/${NAMESPACE}/openshift-demo-frontend:${VERSION}"
