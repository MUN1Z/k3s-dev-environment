# ArgoCD Quick Start Guide

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes that is included in this K3s development environment.

## Access Methods

### Method 1: Domain Access (Recommended)
After setting up hosts file with `./setup-hosts.sh`:
- **URL**: http://argocd.localhost
- **Username**: admin
- **Password**: Run `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d` to get the password

### Method 2: Port Forwarding
After running `./setup-port-forwards.sh`:
- **URL**: http://localhost:8080
- **Username**: admin
- **Password**: Same as above

## Initial Setup

1. **First Login**: Use the credentials shown above to log in
2. **Change Password**: It's recommended to change the default password after first login
3. **Set Up Repositories**: Connect your Git repositories containing Kubernetes manifests

## Common Tasks

### Adding a Git Repository
1. Go to Settings → Repositories
2. Click "Connect Repo using HTTPS" or "Connect Repo using SSH"
3. Enter your repository URL and credentials

### Creating an Application
1. Click "New App"
2. Fill in:
   - **Application Name**: Your app name
   - **Project**: default (or create a new project)
   - **Source Repository**: Select your connected repo
   - **Path**: Path to your Kubernetes manifests
   - **Destination Cluster**: https://kubernetes.default.svc
   - **Namespace**: Target namespace for deployment

### Syncing Applications
- **Auto-Sync**: Enable for automatic deployment when Git changes
- **Manual Sync**: Click "Sync" button to deploy manually

## Integration with K3s Environment

ArgoCD is fully integrated with the development environment:
- **Namespace**: `argocd`
- **Ingress**: Configured with Traefik
- **Monitoring**: Metrics available for Prometheus
- **Storage**: Uses local K3s storage

## Troubleshooting

### Can't Access ArgoCD
1. Check if pods are running: `kubectl get pods -n argocd`
2. Verify ingress route: `kubectl get ingressroute -n argocd`
3. Check port forwards: `ps aux | grep "kubectl port-forward"`

### Forgot Admin Password
```bash
# Get the current password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Or reset password using ArgoCD CLI
argocd account update-password --account admin --new-password admin123
```

### Application Sync Issues
1. Check repository connectivity in Settings → Repositories
2. Verify path and branch configuration in Application settings
3. Check ArgoCD server logs: `kubectl logs -n argocd deployment/argocd-server`

## Best Practices

1. **Use Git Branches**: Create feature branches for testing changes
2. **Organize Manifests**: Structure your repository with clear folder hierarchy
3. **Use Projects**: Group related applications in ArgoCD projects
4. **Monitor Health**: Regularly check application health status
5. **Backup Configuration**: Export ArgoCD configuration regularly

## Integration Examples

See the `examples/gitops/` directory for sample applications and GitOps workflows that can be deployed using ArgoCD.

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [K3s Integration Guide](../k3s/README.md)
