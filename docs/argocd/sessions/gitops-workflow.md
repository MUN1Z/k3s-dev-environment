# GitOps Workflow with ArgoCD

## 🎯 Objective
Learn how to implement a complete GitOps workflow using ArgoCD for continuous deployment and application management.

## 🏗️ GitOps Principles

### Core Concepts
1. **Declarative**: Everything is described declaratively
2. **Versioned**: All changes are versioned in Git
3. **Immutable**: Applications are deployed from Git, not manual changes
4. **Auditable**: All changes have audit trails
5. **Automated**: Deployments happen automatically on Git changes

### GitOps Workflow
```mermaid
graph LR
    A[Developer] -->|Push Code| B[Git Repository]
    B -->|Trigger| C[CI Pipeline]
    C -->|Update Manifests| D[Config Repository]
    D -->|Pull Changes| E[ArgoCD]
    E -->|Deploy| F[Target Environment]
    F -->|Monitor| G[Observability Stack]
    G -->|Feedback| A
```

## 📂 Repository Structure

### Option 1: Mono-repo Approach
```
gitops-repo/
├── applications/
│   ├── development/
│   │   ├── frontend/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── configmap.yaml
│   │   ├── backend/
│   │   └── database/
│   ├── staging/
│   └── production/
├── infrastructure/
│   ├── monitoring/
│   ├── ingress/
│   └── security/
└── argocd/
    ├── applications/
    └── projects/
```

### Option 2: Multi-repo Approach
```
app-source-repo/          # Application source code
├── src/
├── Dockerfile
└── .github/workflows/

app-config-repo/          # Application configurations
├── base/
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── development/
│   ├── staging/
│   └── production/
└── argocd-app.yaml

infrastructure-repo/      # Infrastructure as Code
├── terraform/
├── ansible/
└── kubernetes/
```

## 🔄 Setting Up GitOps Workflow

### Step 1: Prepare Your Repository

1. **Create a new repository** for your application configurations:
   ```bash
   mkdir my-app-gitops
   cd my-app-gitops
   git init
   ```

2. **Create directory structure**:
   ```bash
   mkdir -p {environments/{dev,staging,prod},applications/my-app,argocd/apps}
   ```

3. **Create base application manifests**:
   ```yaml
   # applications/my-app/deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: my-app
     labels:
       app: my-app
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: my-app
     template:
       metadata:
         labels:
           app: my-app
       spec:
         containers:
         - name: my-app
           image: nginx:latest
           ports:
           - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: my-app
   spec:
     selector:
       app: my-app
     ports:
     - port: 80
       targetPort: 80
     type: ClusterIP
   ```

### Step 2: Create Environment-Specific Configurations

1. **Development environment**:
   ```yaml
   # environments/dev/my-app.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   namespace: dev
   
   resources:
   - ../../applications/my-app
   
   patchesStrategicMerge:
   - replica-patch.yaml
   
   images:
   - name: nginx
     newTag: "1.21-alpine"
   ```

   ```yaml
   # environments/dev/replica-patch.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: my-app
   spec:
     replicas: 1
   ```

2. **Production environment**:
   ```yaml
   # environments/prod/my-app.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   namespace: production
   
   resources:
   - ../../applications/my-app
   
   patchesStrategicMerge:
   - replica-patch.yaml
   - resource-limits.yaml
   
   images:
   - name: nginx
     newTag: "1.21"
   ```

### Step 3: Create ArgoCD Applications

1. **Development application**:
   ```yaml
   # argocd/apps/my-app-dev.yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app-dev
     namespace: argocd
     finalizers:
       - resources-finalizer.argocd.argoproj.io
   spec:
     project: default
     source:
       repoURL: https://github.com/your-org/my-app-gitops
       targetRevision: HEAD
       path: environments/dev
     destination:
       server: https://kubernetes.default.svc
       namespace: dev
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
       - CreateNamespace=true
   ```

2. **Production application**:
   ```yaml
   # argocd/apps/my-app-prod.yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app-prod
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/your-org/my-app-gitops
       targetRevision: HEAD
       path: environments/prod
     destination:
       server: https://kubernetes.default.svc
       namespace: production
     syncPolicy:
       syncOptions:
       - CreateNamespace=true
     # Note: No automated sync for production
   ```

### Step 4: Deploy ArgoCD Applications

```bash
# Apply the ArgoCD applications
kubectl apply -f argocd/apps/my-app-dev.yaml
kubectl apply -f argocd/apps/my-app-prod.yaml

# Check application status
argocd app list
argocd app get my-app-dev
```

## 🔧 CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/update-manifests.yml
name: Update Kubernetes Manifests

on:
  push:
    branches: [main]
    paths: ['src/**']

jobs:
  update-manifests:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v3
        with:
          repository: your-org/my-app-source

      - name: Build and push Docker image
        run: |
          docker build -t my-app:${{ github.sha }} .
          docker tag my-app:${{ github.sha }} my-app:latest
          # Push to registry

      - name: Checkout config repository
        uses: actions/checkout@v3
        with:
          repository: your-org/my-app-gitops
          path: config-repo
          token: ${{ secrets.GITOPS_TOKEN }}

      - name: Update image tag
        run: |
          cd config-repo
          # Update image tag in kustomization files
          sed -i "s|newTag: .*|newTag: \"${{ github.sha }}\"|g" environments/dev/kustomization.yaml
          
      - name: Commit and push changes
        run: |
          cd config-repo
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add .
          git commit -m "Update image to ${{ github.sha }}"
          git push
```

### GitLab CI Example

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy-dev
  - deploy-prod

variables:
  IMAGE_TAG: $CI_COMMIT_SHA

build:
  stage: build
  script:
    - docker build -t my-app:$IMAGE_TAG .
    - docker push my-app:$IMAGE_TAG

deploy-dev:
  stage: deploy-dev
  script:
    - git clone https://oauth2:$GITOPS_TOKEN@gitlab.com/your-org/my-app-gitops.git
    - cd my-app-gitops
    - sed -i "s|newTag: .*|newTag: \"$IMAGE_TAG\"|g" environments/dev/kustomization.yaml
    - git add .
    - git commit -m "Update dev image to $IMAGE_TAG"
    - git push origin main
  only:
    - main

deploy-prod:
  stage: deploy-prod
  script:
    - git clone https://oauth2:$GITOPS_TOKEN@gitlab.com/your-org/my-app-gitops.git
    - cd my-app-gitops
    - sed -i "s|newTag: .*|newTag: \"$IMAGE_TAG\"|g" environments/prod/kustomization.yaml
    - git add .
    - git commit -m "Update prod image to $IMAGE_TAG"
    - git push origin main
  when: manual
  only:
    - main
```

## 🔄 Advanced GitOps Patterns

### Progressive Delivery

1. **Canary Deployments**:
   ```yaml
   # environments/prod/rollout.yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Rollout
   metadata:
     name: my-app
   spec:
     replicas: 10
     strategy:
       canary:
         steps:
         - setWeight: 20
         - pause: {duration: 10m}
         - setWeight: 50
         - pause: {duration: 5m}
         - setWeight: 80
         - pause: {duration: 2m}
     selector:
       matchLabels:
         app: my-app
     template:
       metadata:
         labels:
           app: my-app
       spec:
         containers:
         - name: my-app
           image: my-app:latest
   ```

2. **Blue-Green Deployments**:
   ```yaml
   strategy:
     blueGreen:
       activeService: my-app-active
       previewService: my-app-preview
       autoPromotionEnabled: false
       prePromotionAnalysis:
         templates:
         - templateName: success-rate
         args:
         - name: service-name
           value: my-app-preview
   ```

### Multi-Cluster Deployments

```yaml
# argocd/apps/my-app-multicluster.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app-clusters
  namespace: argocd
spec:
  generators:
  - clusters: {}
  template:
    metadata:
      name: '{{name}}-my-app'
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/my-app-gitops
        targetRevision: HEAD
        path: 'environments/{{metadata.labels.environment}}'
      destination:
        server: '{{server}}'
        namespace: my-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## 📊 Monitoring GitOps Pipeline

### Key Metrics to Track

1. **Deployment Frequency**: How often you deploy
2. **Lead Time**: Time from commit to production
3. **Mean Time to Recovery**: Time to recover from failures
4. **Change Failure Rate**: Percentage of deployments causing issues

### Prometheus Metrics

```yaml
# ServiceMonitor for ArgoCD metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
```

### Custom Alerts

```yaml
# Prometheus AlertManager rules
groups:
- name: argocd
  rules:
  - alert: ArgocdAppOutOfSync
    expr: argocd_app_info{sync_status!="Synced"} == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "ArgoCD application {{ $labels.name }} is out of sync"

  - alert: ArgocdAppUnhealthy
    expr: argocd_app_info{health_status!="Healthy"} == 1
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "ArgoCD application {{ $labels.name }} is unhealthy"
```

## 🔐 Security Best Practices

### Repository Access
- Use deploy keys or dedicated service accounts
- Implement branch protection rules
- Require signed commits for production

### RBAC Configuration
```yaml
# ArgoCD RBAC policy
policy.default: role:readonly
policy.csv: |
  p, role:admin, applications, *, */*, allow
  p, role:admin, clusters, *, *, allow
  p, role:developer, applications, get, my-team/*, allow
  p, role:developer, applications, sync, my-team/dev-*, allow
  g, alice@company.com, role:admin
  g, bob@company.com, role:developer
```

### Secret Management
- Use external secret management (AWS Secrets Manager, HashiCorp Vault)
- Never commit secrets to Git
- Implement secret rotation

## 🚨 Troubleshooting Common Issues

### Application Won't Sync
```bash
# Check application status
argocd app get my-app-dev

# Look for resource conflicts
argocd app diff my-app-dev

# Force refresh and sync
argocd app refresh my-app-dev --hard
argocd app sync my-app-dev --force
```

### Git Repository Issues
```bash
# Test repository access
argocd repo get https://github.com/your-org/my-app-gitops

# Update repository credentials
argocd repo add https://github.com/your-org/my-app-gitops \
  --username your-username \
  --password your-token
```

### Resource Conflicts
```bash
# Check for existing resources
kubectl get all -n dev

# Delete conflicting resources
kubectl delete deployment my-app -n dev

# Re-sync application
argocd app sync my-app-dev
```

## 📚 Best Practices Summary

1. **Repository Structure**: Keep configurations separate from source code
2. **Environment Promotion**: Use separate branches or directories for environments
3. **Automated Testing**: Test your manifests before applying
4. **Rollback Strategy**: Always have a rollback plan
5. **Monitoring**: Monitor both applications and the GitOps pipeline
6. **Security**: Implement proper RBAC and secret management
7. **Documentation**: Document your GitOps workflows and procedures

---

**⏱️ Estimated Time**: 45-60 minutes  
**💡 Pro Tip**: Start with a simple application and gradually add complexity as you master the GitOps workflow.
