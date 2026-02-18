# Troubleshooting Guide

Common issues and solutions for the LiteLLM OpenShift POC.

## Pod Issues

### Pods Not Starting (ImagePullBackOff)

**Symptom:**
```bash
oc get pods
NAME                        READY   STATUS             RESTARTS   AGE
backend-xxx-yyy             0/1     ImagePullBackOff   0          2m
```

**Cause:** OpenShift can't pull your Docker image

**Solutions:**

1. **Check image name is correct**
   ```bash
   oc describe pod backend-xxx-yyy | grep Image
   ```
   Verify the image name matches your Docker Hub username.

2. **Verify image exists on Docker Hub**
   - Go to https://hub.docker.com/
   - Check your repositories
   - Verify the tag exists (v1, v2, etc.)

3. **Make repository public** (if private)
   - Go to Docker Hub
   - Repository Settings → Make Public

4. **Check for typos**
   ```bash
   # In k8s/backend-deployment.yaml
   # Should be: yourname/litellm-backend:v1
   # Not: yourname/litellm-backend:latest (if you tagged as v1)
   ```

### Pods Crashing (CrashLoopBackOff)

**Symptom:**
```bash
oc get pods
NAME                        READY   STATUS             RESTARTS   AGE
backend-xxx-yyy             0/1     CrashLoopBackOff   5          5m
```

**Cause:** Application is starting but crashing immediately

**Solutions:**

1. **Check logs**
   ```bash
   oc logs pod/backend-xxx-yyy
   ```

2. **Common backend issues:**

   **Missing environment variables:**
   ```bash
   # Check if secret exists
   oc get secret litellm-secrets

   # View secret data (base64 encoded)
   oc get secret litellm-secrets -o yaml
   ```

   **Invalid API credentials:**
   - Verify `LLM_API_BASE` is correct URL
   - Verify `LLM_API_KEY` is valid
   - Test endpoint manually:
     ```bash
     curl -H "Authorization: Bearer YOUR_KEY" https://your-endpoint/v1/models
     ```

   **Module import errors:**
   - Check `backend/requirements.txt` has all dependencies
   - Rebuild image: `docker build -t yourname/litellm-backend:v2 ./backend`

3. **Common frontend issues:**

   **Nginx configuration errors:**
   ```bash
   oc logs pod/frontend-xxx-zzz
   # Look for nginx errors
   ```

### Pods Pending

**Symptom:**
```bash
oc get pods
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx-yyy             0/1     Pending   0          5m
```

**Cause:** Cluster doesn't have resources to schedule pod

**Solutions:**

1. **Check resource quotas**
   ```bash
   oc describe pod backend-xxx-yyy | grep -A 5 Events
   ```

2. **Reduce resource requests** (if in free tier)
   ```yaml
   # In k8s/backend-deployment.yaml
   resources:
     requests:
       memory: "64Mi"    # Reduced from 128Mi
       cpu: "100m"       # Reduced from 250m
   ```

## Networking Issues

### Frontend Can't Reach Backend

**Symptom:** Frontend loads but chat returns errors like "Failed to get response"

**Solutions:**

1. **Check backend is running**
   ```bash
   oc get pods
   # Both pods should be Running
   ```

2. **Check backend service**
   ```bash
   oc get svc backend-service
   # Should show ClusterIP and port 8000
   ```

3. **Test backend directly**
   ```bash
   oc port-forward svc/backend-service 8000:8000
   # In another terminal:
   curl -X POST http://localhost:8000/chat \
     -H "Content-Type: application/json" \
     -d '{"message":"hello"}'
   ```

4. **Check frontend environment**
   ```bash
   # Frontend should call: http://backend-service:8000
   # Check nginx.conf is correctly proxying
   oc exec deployment/frontend -- cat /etc/nginx/conf.d/default.conf
   ```

5. **Check CORS**
   ```bash
   # Backend logs should show incoming requests
   oc logs -f deployment/backend
   ```

### Can't Access Frontend Route

**Symptom:** Route URL doesn't load in browser

**Solutions:**

1. **Check route exists**
   ```bash
   oc get route frontend-route
   ```

2. **Verify route is pointing to correct service**
   ```bash
   oc describe route frontend-route
   # Should show: Service: frontend-service
   ```

3. **Check frontend pod is running**
   ```bash
   oc get pods | grep frontend
   # Should be 1/1 Running
   ```

4. **Test service directly**
   ```bash
   oc port-forward svc/frontend-service 8080:80
   # Open http://localhost:8080 in browser
   ```

## Secret Issues

### Environment Variables Not Available

**Symptom:** Backend logs show "Missing environment variable" or similar

**Solutions:**

1. **Check secret exists**
   ```bash
   oc get secret litellm-secrets
   ```

2. **Verify secret has correct keys**
   ```bash
   oc get secret litellm-secrets -o jsonpath='{.data}' | jq
   # Should show: LLM_API_BASE, LLM_API_KEY, LLM_MODEL (base64 encoded)
   ```

3. **Check deployment references secret**
   ```bash
   oc get deployment backend -o yaml | grep -A 10 envFrom
   # Should see secretRef to litellm-secrets
   ```

4. **Recreate secret**
   ```bash
   oc delete secret litellm-secrets
   oc apply -f k8s/secret.yaml
   oc rollout restart deployment/backend
   ```

## Build Issues

### Docker Build Fails

**Symptom:** `docker build` command fails

**Solutions:**

1. **Backend build issues:**

   **Pip install fails:**
   ```bash
   # Check requirements.txt syntax
   # Ensure no extra spaces or characters
   ```

   **Python version mismatch:**
   ```dockerfile
   # In backend/Dockerfile
   # Use specific version: FROM python:3.11-alpine
   ```

2. **Frontend build issues:**

   **NPM install fails:**
   ```bash
   # Clear npm cache
   npm cache clean --force

   # Delete node_modules and retry
   rm -rf frontend/node_modules
   docker build -t yourname/litellm-frontend:v1 ./frontend
   ```

   **Build runs out of memory:**
   ```bash
   # Increase Docker Desktop memory allocation
   # Docker Desktop → Settings → Resources → Memory → 4GB+
   ```

## ArgoCD Issues

### Application Not Syncing

**Symptom:** Changes to Git aren't deploying

**Solutions:**

1. **Check application status**
   ```bash
   oc get application -n argocd litellm-chat
   ```

2. **Check ArgoCD can access Git repo**
   - Ensure repository is public, OR
   - Configure SSH/HTTPS credentials in ArgoCD

3. **Manual sync**
   ```bash
   # Install ArgoCD CLI
   argocd app sync litellm-chat
   ```

4. **Check ArgoCD logs**
   ```bash
   oc logs -n argocd deployment/argocd-application-controller
   ```

### Sync Failing

**Symptom:** ArgoCD shows "OutOfSync" or "Failed"

**Solutions:**

1. **Check application details in UI**
   - Login to ArgoCD UI
   - Click on `litellm-chat` application
   - Check error messages

2. **Verify manifests are valid**
   ```bash
   oc apply --dry-run=client -f k8s/
   ```

3. **Check namespace exists**
   ```bash
   # In argocd/application.yaml
   # Ensure namespace matches your OpenShift project
   oc project
   ```

## General Debugging Commands

```bash
# View all resources
oc get all

# Describe pod (shows events)
oc describe pod <pod-name>

# View logs
oc logs -f deployment/backend
oc logs -f deployment/frontend

# View previous logs (if pod crashed)
oc logs deployment/backend --previous

# Execute command in pod
oc exec -it deployment/backend -- /bin/sh

# View events
oc get events --sort-by='.lastTimestamp'

# Check resource usage
oc adm top pods

# Port forward for testing
oc port-forward svc/backend-service 8000:8000
```

## Getting Help

If you're still stuck:

1. Check the full pod description:
   ```bash
   oc describe pod <pod-name>
   ```

2. Export logs:
   ```bash
   oc logs deployment/backend > backend-logs.txt
   oc logs deployment/frontend > frontend-logs.txt
   ```

3. Check OpenShift web console:
   - Go to https://console.redhat.com/openshift
   - Navigate to your Developer Sandbox
   - Check Topology view for visual status

4. Review documentation:
   - [OpenShift Documentation](https://docs.openshift.com/)
   - [LiteLLM Documentation](https://docs.litellm.ai/)
   - [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
