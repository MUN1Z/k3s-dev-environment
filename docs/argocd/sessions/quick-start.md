# ArgoCD Quick Start Guide

## 🎯 Objective
Get ArgoCD up and running in 10 minutes and deploy your first application using GitOps principles.

## 📋 Prerequisites
- K3s development environment running (`./k3s-dev-env.sh start`)
- Git repository with application manifests
- Basic understanding of containerized applications

## 🚀 Step-by-Step Guide

### Step 1: Start ArgoCD
```bash
# Ensure the development environment is running
./dev-env.sh start

# Verify ArgoCD is accessible
curl -I http://argocd.local
# Expected: HTTP/1.1 200 OK
```

### Step 2: Get Initial Admin Password
```bash
# Get the initial admin password
./dev-env.sh logs argocd | grep "admin password"

# Alternative: Check container logs directly
docker logs k3s-dev-environment-argocd-1 2>&1 | grep "admin password" | tail -1
```

### Step 3: Access ArgoCD UI
1. Open browser: http://argocd.local
2. Login with:
   - Username: `admin`
   - Password: (from Step 2)

### Step 4: Install ArgoCD CLI (Optional)
```bash
# Install via Homebrew (macOS)
brew install argocd

# Login via CLI
argocd login argocd.local
# Username: admin
# Password: (from Step 2)
```

### Step 5: Create Your First Application

#### Option A: Via Web UI
1. Click **"+ NEW APP"** in ArgoCD UI
2. Fill in application details:
   ```
   Application Name: demo-app
   Project: default
   
   Repository URL: https://github.com/argoproj/argocd-example-apps
   Path: guestbook
   Revision: HEAD
   
   Destination:
   - Cluster URL: https://kubernetes.default.svc
   - Namespace: default
   ```
3. Click **"CREATE"**

#### Option B: Via CLI
```bash
# Create application via CLI
argocd app create demo-app \
  --repo https://github.com/argoproj/argocd-example-apps \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync the application
argocd app sync demo-app
```

### Step 6: Monitor Deployment
```bash
# Check application status
argocd app get demo-app

# Watch sync progress
argocd app wait demo-app --health
```

### Step 7: Verify Application
```bash
# Check if application pods are running
kubectl get pods -n default | grep guestbook

# Port forward to access the application
kubectl port-forward svc/guestbook-ui 8081:80

# Open browser: http://localhost:8081
```

## 🔄 GitOps Workflow Test

### Test Automatic Sync
1. **Fork the example repository**:
   ```bash
   # Fork: https://github.com/argoproj/argocd-example-apps
   ```

2. **Update your application to use your fork**:
   ```bash
   argocd app set demo-app --repo https://github.com/YOUR_USERNAME/argocd-example-apps
   ```

3. **Make a change to the repository**:
   ```bash
   # Clone your fork
   git clone https://github.com/YOUR_USERNAME/argocd-example-apps
   cd argocd-example-apps

   # Edit guestbook deployment
   vim guestbook/guestbook-ui-deployment.yaml
   # Change replicas from 1 to 2

   # Commit and push
   git add .
   git commit -m "Scale guestbook to 2 replicas"
   git push origin HEAD
   ```

4. **Watch ArgoCD automatically sync**:
   ```bash
   # Enable auto-sync
   argocd app set demo-app --sync-policy automated

   # Watch the sync happen
   argocd app wait demo-app --sync
   ```

## 🎛️ Application Management

### Useful Commands
```bash
# List all applications
argocd app list

# Get detailed application info
argocd app get demo-app

# Manual sync
argocd app sync demo-app

# Refresh application (fetch latest from Git)
argocd app refresh demo-app

# Rollback to previous version
argocd app rollback demo-app

# Delete application
argocd app delete demo-app
```

### Sync Policies
```bash
# Enable automatic sync
argocd app set demo-app --sync-policy automated

# Enable automatic pruning (remove deleted resources)
argocd app set demo-app --auto-prune

# Enable self-healing (revert manual changes)
argocd app set demo-app --self-heal
```

## 🚨 Troubleshooting

### Application Stuck in "OutOfSync"
```bash
# Force refresh from Git
argocd app refresh demo-app --hard

# Manual sync with force
argocd app sync demo-app --force

# Check for resource conflicts
argocd app diff demo-app
```

### Repository Access Issues
```bash
# Test repository connection
argocd repo list

# Add repository manually
argocd repo add https://github.com/YOUR_USERNAME/your-repo
```

### Health Check Failures
```bash
# Check application events
argocd app get demo-app | grep -A 10 "Health Status"

# Check Kubernetes events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🎯 Next Steps

1. **Set up your own application repository**
2. **Configure automatic sync policies**
3. **Implement multi-environment deployments**
4. **Set up notifications for deployment status**
5. **Integrate with CI/CD pipelines**

## 📚 Resources

- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **Example Applications**: https://github.com/argoproj/argocd-example-apps
- **GitOps Best Practices**: https://www.gitops.tech/

---

**⏱️ Estimated Time**: 10-15 minutes  
**💡 Pro Tip**: Start with the example applications to understand the workflow before deploying your own applications.
