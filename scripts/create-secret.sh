#!/bin/bash

# Create Kubernetes secret from .env file
# Usage: ./scripts/create-secret.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ENV_FILE=".env"
SECRET_FILE="k8s/secret.yaml"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo ""
    echo "Please create a .env file first:"
    echo "  cp .env.template .env"
    echo "  # Edit .env with your actual credentials"
    exit 1
fi

echo -e "${YELLOW}Creating Kubernetes secret from .env file...${NC}"

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Validate required variables
if [ -z "$LLM_API_BASE" ] || [ -z "$LLM_API_KEY" ] || [ -z "$LLM_MODEL" ]; then
    echo -e "${RED}Error: Missing required environment variables in .env${NC}"
    echo ""
    echo "Required variables:"
    echo "  - LLM_API_BASE"
    echo "  - LLM_API_KEY"
    echo "  - LLM_MODEL"
    exit 1
fi

# Create secret.yaml
cat > "$SECRET_FILE" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: litellm-secrets
type: Opaque
stringData:
  LLM_API_BASE: "$LLM_API_BASE"
  LLM_API_KEY: "$LLM_API_KEY"
  LLM_MODEL: "$LLM_MODEL"
EOF

echo -e "${GREEN}✓ Secret created at: $SECRET_FILE${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - This file contains sensitive credentials"
echo "  - It is gitignored and should NOT be committed"
echo "  - You can now deploy with: oc apply -f k8s/"
