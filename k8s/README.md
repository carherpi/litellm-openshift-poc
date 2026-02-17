# Kubernetes Manifests

## Setup Instructions

### 1. Create Secret

Copy the template and fill in your values:

```bash
cp secret.yaml.template secret.yaml
# Edit secret.yaml with your actual credentials
```

**IMPORTANT:** `secret.yaml` is gitignored. Never commit actual secrets!

### 2. Deploy to OpenShift

```bash
# Login to OpenShift
oc login --token=YOUR_TOKEN --server=YOUR_SERVER

# Create secret
oc apply -f secret.yaml

# Deploy all resources
oc apply -f .

# Check status
oc get pods
oc get routes
```

### 3. Access Application

```bash
oc get route frontend-route -o jsonpath='{.spec.host}'
```

Open the returned URL in your browser.

## Resources

- `secret.yaml` - API credentials (gitignored)
- `backend-deployment.yaml` - Backend pod configuration
- `backend-service.yaml` - Backend internal service
- `frontend-deployment.yaml` - Frontend pod configuration
- `frontend-service.yaml` - Frontend internal service
- `frontend-route.yaml` - Frontend public HTTPS route
