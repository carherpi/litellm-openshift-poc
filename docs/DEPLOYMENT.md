# Deployment Guide

Complete step-by-step guide for deploying the LiteLLM POC.

## Prerequisites Checklist

- [ ] Docker Desktop installed and running
- [ ] OpenShift CLI (`oc`) installed
- [ ] Docker Hub account created
- [ ] Red Hat Developer Sandbox account created
- [ ] Custom LLM endpoint URL and API key available

## Phase 1: Manual Deployment

### Step 1: Prepare OpenShift Environment

1. **Access Developer Sandbox**
   - Go to https://developers.redhat.com/developer-sandbox
   - Click "Launch your Developer Sandbox for Red Hat OpenShift"
   - Login with Red Hat account

2. **Get Login Command**
   - Click your username (top right)
   - Select "Copy login command"
   - Click "Display Token"
   - Copy the `oc login` command

3. **Login to OpenShift**
   ```bash
   oc login --token=sha256~... --server=https://api...
   ```

4. **Verify Login**
   ```bash
   oc whoami
   oc project
   ```

### Step 2: Build Docker Images

1. **Run build script**
   ```bash
   chmod +x scripts/build.sh
   ./scripts/build.sh
   ```

2. **Enter details when prompted**
   - Docker Hub username: `yourname`
   - Version tag: `v1` (or press Enter for default)

3. **Verify images built**
   ```bash
   docker images | grep litellm
   ```

   Expected output:
   ```
   yourname/litellm-backend   v1   ...   ...   ...
   yourname/litellm-frontend  v1   ...   ...   ...
   ```

### Step 3: Push to Docker Hub

1. **Login to Docker Hub** (if not already)
   ```bash
   docker login
   ```

2. **Run push script**
   ```bash
   ./scripts/push.sh
   ```

3. **Verify on Docker Hub**
   - Go to https://hub.docker.com/
   - Check your repositories
   - Should see `litellm-backend` and `litellm-frontend`

### Step 4: Configure Kubernetes Manifests

1. **Update deployment image references**
   ```bash
   # In k8s/backend-deployment.yaml
   # Change: image: YOUR_DOCKERHUB_USERNAME/litellm-backend:v1
   # To:     image: yourname/litellm-backend:v1

   # In k8s/frontend-deployment.yaml
   # Change: image: YOUR_DOCKERHUB_USERNAME/litellm-frontend:v1
   # To:     image: yourname/litellm-frontend:v1
   ```

2. **Create secret with your credentials**
   ```bash
   cp k8s/secret.yaml.template k8s/secret.yaml
   ```

3. **Edit k8s/secret.yaml**
   ```yaml
   stringData:
     LLM_API_BASE: "https://your-actual-endpoint.com/v1"
     LLM_API_KEY: "your-actual-api-key"
     LLM_MODEL: "gpt-3.5-turbo"
   ```

### Step 5: Deploy to OpenShift

1. **Apply secret first**
   ```bash
   oc apply -f k8s/secret.yaml
   ```

   Expected output:
   ```
   secret/litellm-secrets created
   ```

2. **Deploy all resources**
   ```bash
   oc apply -f k8s/
   ```

   Expected output:
   ```
   deployment.apps/backend created
   service/backend-service created
   deployment.apps/frontend created
   service/frontend-service created
   route.route.openshift.io/frontend-route created
   secret/litellm-secrets unchanged
   ```

3. **Watch pods start**
   ```bash
   oc get pods -w
   ```

   Wait until both pods show `1/1 Running`:
   ```
   NAME                        READY   STATUS    RESTARTS   AGE
   backend-xxx-yyy             1/1     Running   0          30s
   frontend-xxx-zzz            1/1     Running   0          30s
   ```

   Press `Ctrl+C` to exit watch mode.

### Step 6: Access the Application

1. **Get the Route URL**
   ```bash
   oc get route frontend-route -o jsonpath='{.spec.host}'
   echo ""
   ```

2. **Open in browser**
   ```bash
   # Copy the URL and paste into browser
   # Should see "LiteLLM Chat POC" interface
   ```

3. **Test the chat**
   - Type a message in the input box
   - Click "Send"
   - Should see response from your LLM

### Step 7: Verify Everything Works

1. **Check backend logs**
   ```bash
   oc logs -f deployment/backend
   ```

   Should see:
   ```
   INFO:     Started server process
   INFO:     Uvicorn running on http://0.0.0.0:8000
   ```

2. **Check frontend logs**
   ```bash
   oc logs deployment/frontend
   ```

3. **Test health endpoint**
   ```bash
   oc port-forward svc/backend-service 8000:8000
   # In another terminal:
   curl http://localhost:8000/health
   # Expected: {"status":"healthy"}
   ```

## Phase 2: ArgoCD GitOps

See [`argocd/README.md`](../argocd/README.md) for ArgoCD setup.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Updating the Application

### Update Backend Code

1. Make changes to `backend/app.py`
2. Build new image: `docker build -t yourname/litellm-backend:v2 ./backend`
3. Push: `docker push yourname/litellm-backend:v2`
4. Update `k8s/backend-deployment.yaml` image tag to `v2`
5. Apply: `oc apply -f k8s/backend-deployment.yaml`
6. Watch rollout: `oc rollout status deployment/backend`

### Update Frontend Code

Same process as backend, but with frontend files.

### Scaling

```bash
# Scale to 3 replicas
oc scale deployment/backend --replicas=3

# Verify
oc get pods
```

## Cleanup

```bash
# Delete all resources
oc delete -f k8s/

# Verify deletion
oc get pods
```
