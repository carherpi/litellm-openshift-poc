# LiteLLM OpenShift POC

A learning project to understand OpenShift, Kubernetes, and ArgoCD GitOps workflows.

## Architecture

- **Backend:** FastAPI + LiteLLM (Python)
- **Frontend:** React + Nginx
- **Deployment:** OpenShift with ArgoCD

## Prerequisites

- Docker Desktop
- OpenShift CLI (`oc`)
- Red Hat Developer Sandbox account
- Docker Hub account

## Documentation

See `docs/plans/` for design and implementation details.

## Quick Start

### Phase 1: Manual Deployment
1. Build images: `./scripts/build.sh`
2. Push images: `./scripts/push.sh`
3. Deploy: `oc apply -f k8s/`

### Phase 2: ArgoCD GitOps
1. Install ArgoCD
2. Apply ArgoCD app: `oc apply -f argocd/application.yaml`
3. Push changes to Git and watch auto-deployment
