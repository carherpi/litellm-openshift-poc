# ArgoCD Configuration

## Prerequisites

1. ArgoCD installed on your OpenShift cluster
2. Git repository pushed to GitHub
3. Phase 1 (manual deployment) completed and working

## Installation

### 1. Install ArgoCD on OpenShift

```bash
# Create argocd namespace
oc new-project argocd

# Install ArgoCD
oc apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
oc get pods -n argocd -w
```

### 2. Expose ArgoCD UI

```bash
# Create route for ArgoCD server
oc -n argocd expose svc argocd-server

# Get the URL
oc -n argocd get route argocd-server -o jsonpath='{.spec.host}'
```

### 3. Get Admin Password

```bash
# Get initial admin password
oc -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
```

Login to ArgoCD UI:
- Username: `admin`
- Password: (from command above)

### 4. Configure Application

Edit `argocd/application.yaml`:
- Replace `YOUR_GITHUB_USERNAME` with your GitHub username
- Replace `YOUR_OPENSHIFT_NAMESPACE` with your project namespace

```bash
oc apply -f argocd/application.yaml
```

### 5. Verify Sync

```bash
# Check application status
oc get application -n argocd

# View in UI
# Open ArgoCD UI and see your application syncing
```

## GitOps Workflow

1. Make changes to `k8s/*.yaml` files locally
2. Commit changes: `git commit -am "Update deployment"`
3. Push to GitHub: `git push`
4. Wait ~3 minutes for ArgoCD to detect and sync
5. Verify in ArgoCD UI or: `oc get pods`

## Manual Sync

If you don't want to wait for auto-sync:

```bash
# Sync via CLI
argocd app sync litellm-chat

# Or use the "Sync" button in ArgoCD UI
```

## Troubleshooting

```bash
# Check application status
oc describe application litellm-chat -n argocd

# View sync errors in ArgoCD UI
# Or check ArgoCD application controller logs
oc logs -n argocd deployment/argocd-application-controller
```
