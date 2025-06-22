# Quick Start Guide

Get your K3s development environment up and running in minutes.

## ⚡ TL;DR - 3 Commands

```bash
./k3s-dev-env.sh start    # Start the environment
./show-services.sh        # See status and URLs  
./setup-hosts.sh          # Enable domain access (optional)
```

## 🚀 Step-by-Step Setup

### 1. Prerequisites Check
```bash
# Verify you have the required tools
docker --version     # Docker for k3d
k3d version          # K3s cluster manager
kubectl version      # Kubernetes CLI
```

### 2. Clone and Start
```bash
# Clone the repository
git clone <repo-url>
cd k3s-dev-environment

# Make scripts executable
chmod +x *.sh

# Start the complete environment
./k3s-dev-env.sh start
```

### 3. Verify Services
```bash
# Check everything is running
./show-services.sh

# Expected output: All services should show "Running" status
```

### 4. Access Services

**Option A: Domain Access (Recommended)**
```bash
# Setup domain resolution
./setup-hosts.sh

# Access services via browsers
open http://grafana.localhost      # Grafana dashboards
open http://prometheus.localhost   # Metrics
open http://traefik.localhost      # Ingress dashboard
open http://jaeger.localhost       # Distributed tracing
open http://minio.localhost        # Object storage
open http://rancher.localhost      # Cluster management
```

**Option B: Port Forwarding (Fallback)**
```bash
# Setup port forwards
./setup-port-forwards.sh

# Access via localhost ports
open http://localhost:3000    # Grafana
open http://localhost:9090    # Prometheus
open http://localhost:8888    # Traefik
open http://localhost:16686   # Jaeger
open http://localhost:9001    # MinIO
open https://localhost:8443   # Rancher
```

## 🔑 Default Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Grafana | grafana.localhost:80 | admin | admin123 |
| MinIO | minio.localhost:80 | minioadmin | minioadmin123 |
| Rancher | rancher.localhost:80 | admin | admin123 |

## 🔧 Management Commands

```bash
# Environment control
./k3s-dev-env.sh start      # Start all services
./k3s-dev-env.sh stop       # Stop and cleanup
./k3s-dev-env.sh restart    # Restart environment
./k3s-dev-env.sh status     # Show cluster status
./k3s-dev-env.sh logs       # View all logs

# Access helpers
./show-services.sh          # Service status and URLs
./setup-hosts.sh            # Setup domain access
./setup-port-forwards.sh    # Setup port forwarding
./test-ingress.sh           # Test connectivity
./health-check.sh           # Environment health check
```

## 📊 What's Running

After startup, you'll have:

- **🚦 Traefik**: Ingress controller and load balancer
- **📊 Grafana**: Monitoring dashboards with Kubernetes metrics
- **📈 Prometheus**: Metrics collection and storage
- **🔍 Jaeger**: Distributed tracing platform
- **💾 MinIO**: S3-compatible object storage
- **🐄 Rancher**: Kubernetes cluster management UI
- **🐘 PostgreSQL**: Database server (internal)
- **🔴 Redis**: Cache server (internal)

## 🚨 Troubleshooting

### Environment Won't Start
```bash
# Check Docker is running
docker ps

# Clean up and retry
./k3s-dev-env.sh stop
./k3s-dev-env.sh start
```

### Services Not Accessible
```bash
# Check service status
./show-services.sh

# Test connectivity
./test-ingress.sh

# Try port forwarding
./setup-port-forwards.sh
```

### Complete Reset
```bash
# Nuclear option - clean everything
./k3s-dev-env.sh stop
docker system prune -f
./k3s-dev-env.sh start
```

## 🎯 Next Steps

1. **Explore Grafana**: Pre-configured with Kubernetes monitoring dashboards
2. **Check Prometheus**: View cluster metrics and configure alerts
3. **Use MinIO**: S3-compatible storage for your applications
4. **Monitor with Jaeger**: Add tracing to your microservices
5. **Manage with Rancher**: Visual Kubernetes cluster management

## 📖 Additional Resources

- **Full Documentation**: [README.md](README.md)
- **Service Access Guide**: [SERVICE_ACCESS.md](SERVICE_ACCESS.md)
- **Ingress Details**: [INGRESS_STATUS.md](INGRESS_STATUS.md)
- **Architecture Overview**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- **Service Docs**: `docs/[service-name]/README.md`

---

� **You're ready to go!** The environment is running and all services are accessible.
- **K3s**: Lightweight Kubernetes distribution
- **Traefik**: Modern reverse proxy and load balancer
- **MetalLB**: Bare metal load balancer
- **Rancher**: Kubernetes management platform
- **ArgoCD**: GitOps continuous delivery platform

### 📊 Monitoring & Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **OpenSearch**: Log aggregation and search

### 🛠️ Development Tools
- **Kubernetes**: Container orchestration with K3s
- **kubectl**: Kubernetes CLI
- **Helm**: Package manager for Kubernetes

## Learning Paths

### For Beginners
1. Start with [Getting Started Guide](./docs/getting-started/README.md)
2. Follow [K3s Quick Start](./docs/k3s/sessions/quick-start.md)
3. Try [Traefik Basics](./docs/traefik/sessions/quick-start.md)
4. Learn [ArgoCD GitOps](./docs/argocd/sessions/quick-start.md)
5. Explore [Grafana Monitoring](./docs/grafana/sessions/quick-start.md)

### For Intermediate Users
1. Review [Architecture Overview](./docs/architecture/README.md)
2. Practice with [Application Examples](./examples/applications/)
3. Set up [GitOps Workflows](./docs/argocd/sessions/gitops-workflow.md)
4. Set up [Custom Monitoring](./examples/monitoring/)
5. Configure [Advanced Routing](./docs/traefik/sessions/advanced-routing.md)

### For Advanced Users
1. Implement [CI/CD Pipelines](./examples/advanced/cicd-pipeline.md)
2. Set up [Advanced Monitoring](./docs/prometheus/sessions/advanced-monitoring.md)
3. Configure [Multi-cluster Management](./docs/rancher/sessions/advanced-cluster-management.md)
4. Explore custom extensions and integrations

## Directory Structure

```
k3s-dev-environment/
├── 📋 README.md                    # This file
├── 🐳 k8s-manifests/                  # Kubernetes manifests
├── ⚙️ .env.example                 # Environment configuration template
├── 🛠️ scripts/                     # Setup and utility scripts
├── 📝 config/                      # Service configurations
├── 🚀 manifests/                   # Kubernetes manifests
├── 📚 docs/                        # Comprehensive documentation
│   ├── 🏗️ architecture/            # System architecture
│   ├── 🎓 getting-started/         # Beginner guides
│   ├── � argocd/                  # ArgoCD GitOps documentation
│   ├── �📊 grafana/                 # Grafana documentation
│   ├── 🔄 traefik/                 # Traefik documentation
│   ├── 🎮 rancher/                 # Rancher documentation
│   ├── 📈 prometheus/              # Prometheus documentation
│   ├── 🔍 opensearch/              # OpenSearch documentation
│   ├── ⚖️ metallb/                 # MetalLB documentation
│   └── ☸️ k3s/                     # K3s documentation
├── 💡 examples/                    # Practical examples
│   ├── 🌐 applications/            # Sample applications
│   ├── 📊 monitoring/              # Monitoring setups
│   └── 🚀 advanced/                # Advanced configurations
└── 🔧 .github/                     # GitHub workflows and templates
```

## Common Tasks

### Deploy a Sample Application

```bash
# Quick web application deployment
kubectl apply -f examples/applications/web-app-with-db.md

# Check deployment status
kubectl get pods,svc,ingress

# Access your application
open http://my-web-app.k3s.local
```

### Monitor System Health

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# View metrics in Grafana
open http://grafana.k3s.local:3000

# Query metrics directly
curl http://prometheus.k3s.local:9090/api/v1/query?query=up
```

### Manage with Rancher

```bash
# Access Rancher UI
open https://rancher.k3s.local:8443

# Import your cluster (if needed)
# Follow the Rancher Quick Start guide
```

## Troubleshooting

### Services Not Starting
```bash
# Check service logs
kubectl logs deployment/<service-name>

# Restart specific service
kubectl rollout restart deployment/<service-name>

# Rebuild and restart
kubectl delete deployment <service-name> && kubectl apply -f k8s-manifests/<service-name>.yaml
```

### Network Issues
```bash
# Check network connectivity
docker network ls
docker network inspect k3s-dev-environment_k3s-network

# Test internal DNS
docker exec k3s-server ping traefik
```

### Resource Issues
```bash
# Check resource usage
docker stats

# Check disk space
df -h

# Clean up unused resources
docker system prune
```

## Next Steps

### Extend Your Environment
1. **Add Custom Applications**: Use the examples as templates
2. **Configure CI/CD**: Set up automated deployments
3. **Implement Security**: Add authentication and authorization
4. **Scale Components**: Adjust replicas and resources

### Learn Advanced Topics
1. **Service Mesh**: Integrate Istio or Linkerd
2. **GitOps**: Implement ArgoCD or Flux
3. **Backup & Recovery**: Set up automated backups
4. **Multi-Environment**: Create staging/production variants

### Contribute Back
1. **Share Examples**: Add your configurations to `/examples`
2. **Improve Documentation**: Enhance guides and tutorials
3. **Report Issues**: Help improve the environment
4. **Add Features**: Contribute new capabilities

## Support & Resources

### Documentation
- 📚 [Complete Documentation](./docs/)
- 🎓 [Getting Started](./docs/getting-started/)
- 💡 [Examples](./examples/)

### Community
- 🐛 [Report Issues](https://github.com/yourorg/k3s-dev-environment/issues)
- 💬 [Discussions](https://github.com/yourorg/k3s-dev-environment/discussions)
- 🤝 [Contributing](./CONTRIBUTING.md)

### External Resources
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Traefik Documentation](https://doc.traefik.io/)
- [Rancher Documentation](https://rancher.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

## 🎉 Congratulations!

You now have a professional, production-like K3s development environment ready for:

✅ **Application Development**: Deploy and test applications  
✅ **Learning Kubernetes**: Hands-on experience with real tools  
✅ **Monitoring & Observability**: Full monitoring stack  
✅ **Infrastructure as Code**: Reproducible environments  
✅ **Team Collaboration**: Multi-user support with RBAC  
✅ **CI/CD Integration**: Automated deployment pipelines  

**Happy coding and learning!** 🚀

---

*Need help? Check the [troubleshooting guides](./docs/) or open an issue for support.*
