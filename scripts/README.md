# Build and Push Scripts

This directory contains scripts for building and pushing Docker images.

## Prerequisites

- Docker installed and running
- Access to container registry (e.g., Quay.io, Docker Hub)
- Docker login completed: `docker login quay.io`

## Environment Variables

Set these environment variables to customize the build/push process:

```bash
export REGISTRY=quay.io              # Container registry (default: quay.io)
export NAMESPACE=your-namespace       # Your registry namespace/username
```

## Usage

### Build Images

Build both frontend and backend images:

```bash
./scripts/build.sh [VERSION]
```

Example:
```bash
# Build with 'latest' tag
./scripts/build.sh

# Build with specific version
./scripts/build.sh v1.0.0

# Build with custom registry and namespace
REGISTRY=docker.io NAMESPACE=myuser ./scripts/build.sh v1.0.0
```

### Push Images

Push both frontend and backend images to the registry:

```bash
./scripts/push.sh [VERSION]
```

Example:
```bash
# Push 'latest' tag
./scripts/push.sh

# Push specific version
./scripts/push.sh v1.0.0

# Push with custom registry and namespace
REGISTRY=docker.io NAMESPACE=myuser ./scripts/push.sh v1.0.0
```

### Build and Push Together

```bash
./scripts/build.sh v1.0.0 && ./scripts/push.sh v1.0.0
```

## Images Built

- `${REGISTRY}/${NAMESPACE}/openshift-demo-backend:${VERSION}`
- `${REGISTRY}/${NAMESPACE}/openshift-demo-frontend:${VERSION}`

## Notes

- Scripts must be run from the project root directory
- Ensure you're logged into your container registry before pushing
- Version defaults to 'latest' if not specified
- Set REGISTRY and NAMESPACE environment variables or edit the scripts directly
