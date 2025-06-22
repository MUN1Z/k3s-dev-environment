# Examples

This directory contains practical examples for using the K3s Development Environment.

## 📁 Available Examples

### Basic Usage
- [Getting Started](getting-started.md) - First steps with the platform
- [Service Access](service-access.md) - How to access different services

### Application Deployment
- [Deploy Sample App](deploy-sample-app/) - Deploy a simple application
- [Ingress Configuration](ingress-examples/) - Configure custom ingress rules
- [Persistent Storage](storage-examples/) - Use persistent volumes

### Monitoring & Observability
- [Custom Dashboards](grafana-dashboards/) - Create custom Grafana dashboards
- [Alert Configuration](prometheus-alerts/) - Set up monitoring alerts
- [Log Aggregation](logging-examples/) - Configure application logging

### Advanced Configuration
- [Custom Services](custom-services/) - Add new services to the platform
- [Security Hardening](security-examples/) - Enhance platform security
- [Backup Strategies](backup-examples/) - Implement backup solutions

## 🚀 Quick Examples

### Deploy a Simple Web Application

```bash
# Create a namespace
./scripts/setup-k3s.sh kubectl create namespace demo

# Deploy nginx
./scripts/setup-k3s.sh kubectl create deployment nginx --image=nginx -n demo

# Expose the service
./scripts/setup-k3s.sh kubectl expose deployment nginx --port=80 --type=LoadBalancer -n demo

# Check the service
./scripts/setup-k3s.sh kubectl get services -n demo
```

### Access Kubernetes Dashboard

```bash
# Deploy Kubernetes Dashboard
./scripts/setup-k3s.sh kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
cat <<EOF | ./scripts/setup-k3s.sh kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Get access token
./scripts/setup-k3s.sh kubectl -n kubernetes-dashboard create token admin-user

# Port forward to access
./scripts/setup-k3s.sh kubectl proxy
```

### Create Custom Grafana Dashboard

```bash
# Copy dashboard template
cp examples/grafana-dashboards/custom-dashboard.json volumes/grafana/dashboards/

# Restart Grafana to load new dashboard
./scripts/k3s-helper.sh restart grafana
```

### Monitor Custom Application

```yaml
# prometheus-config.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'my-app'
      static_configs:
      - targets: ['my-app:8080']
      metrics_path: /metrics
```

## 📚 Documentation References

For detailed information, refer to:
- [Architecture Documentation](../docs/architecture/README.md)
- [Service-specific Documentation](../docs/)
- [Troubleshooting Guide](../docs/troubleshooting.md)

## 🤝 Contributing Examples

Have a useful example? Please contribute!

1. Create a new directory under `examples/`
2. Include a clear README.md
3. Add any necessary configuration files
4. Test your example thoroughly
5. Submit a pull request

---

**Need help?** Check our [Getting Started Guide](getting-started.md) or [open an issue](../../issues)!
