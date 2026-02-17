#!/bin/bash

# Push Docker images to registry
# Usage: ./push.sh [VERSION]

set -e

VERSION=${1:-latest}
REGISTRY=${REGISTRY:-quay.io}
NAMESPACE=${NAMESPACE:-your-namespace}

echo "Pushing images with version: $VERSION"

# Push backend image
echo "Pushing backend image..."
docker push ${REGISTRY}/${NAMESPACE}/openshift-demo-backend:${VERSION}

# Push frontend image
echo "Pushing frontend image..."
docker push ${REGISTRY}/${NAMESPACE}/openshift-demo-frontend:${VERSION}

echo "Push complete!"
echo "Backend image: ${REGISTRY}/${NAMESPACE}/openshift-demo-backend:${VERSION}"
echo "Frontend image: ${REGISTRY}/${NAMESPACE}/openshift-demo-frontend:${VERSION}"
