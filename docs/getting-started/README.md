# Getting Started with K3s Development Environment

This guide will help you set up and run the Kubernetes-based development environment from scratch.

## 📋 Prerequisites

Before starting, ensure you have the following installed:

### Required Software

- **Docker Desktop** (macOS) or **Docker Engine** (Linux) version 20.10 or higher
- **kubectl** (Kubernetes CLI)
- **k3d** for K3s cluster management
- **Git** for cloning the repository
- **8GB+ RAM** available for the cluster
- **10GB+ free disk space** for volumes and images

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 8GB | 16GB+ |
| CPU | 4 cores | 8 cores+ |
| Disk | 10GB free | 50GB+ free |
| OS | macOS 10.15+ / Linux | macOS 12+ / Ubuntu 20.04+ |

### Network Requirements

- Ports 80, 443, 6443, 8080, 8443, 3000, 9090, 5432, 6379 available
- Internet connection for downloading images
- No conflicting services on these ports

## 🚀 Quick Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd k3s-development-environment
```

### 2. Install Dependencies

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/$(uname -m | sed 's/x86_64/amd64/')/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### 3. Start the Environment

```bash
# Make scripts executable
chmod +x *.sh

# Start everything
./k3s-dev-env.sh start
```

### 4. Verify Installation

```bash
# Check cluster status
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Run health check
./k3s-dev-env.sh status
```

## 🔧 Detailed Setup Process

### Step 1: K3s Cluster Creation

The setup script creates a K3s cluster with:

- Single server node
- Traefik ingress controller
- MetalLB load balancer
- Persistent volume support

```bash
# Manual cluster creation (if needed)
k3d cluster create dev-cluster \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "8080:8080@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0"
```

### Step 2: Service Deployment

The script deploys all services to Kubernetes:

1. **Infrastructure**: Traefik, MetalLB
2. **Data Services**: PostgreSQL, Redis, MinIO
3. **Monitoring**: Prometheus, Grafana, Jaeger
4. **Management**: Rancher

### Step 3: Ingress Configuration

All services are exposed via Traefik IngressRoutes:

```yaml
# Example ingress configuration
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: grafana
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`localhost`) && PathPrefix(`/grafana`)
      kind: Rule
      services:
        - name: grafana
          port: 3000
```

### Step 4: Access Services

Once started, access the services at:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Rancher** | http://localhost:8888 | admin / admin123 |
| **Traefik** | http://localhost:8080 | No authentication |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | No authentication |
| **Jaeger** | http://localhost:16686 | No authentication |
| **MinIO Console** | http://localhost:9001 | minioadmin / minioadmin |

## 📊 Initial Configuration

### Rancher Setup

1. Navigate to http://localhost:8888
2. Complete the initial setup wizard
3. Create initial admin password
4. The local K3s cluster should be automatically detected

### Grafana Setup

1. Navigate to http://localhost:3000
2. Login with `admin` / `admin`
3. Change the default password when prompted
4. Prometheus datasource is pre-configured
5. Import dashboards for Kubernetes monitoring

### Kubernetes Access

```bash
# Using kubectl directly
kubectl get nodes

# View cluster info
kubectl cluster-info

# Access K3s cluster config
k3d kubeconfig get dev-cluster
```

## 🛠️ Management Commands

### Basic Operations

```bash
# Check overall status
./k3s-dev-env.sh status

# View service logs
./k3s-dev-env.sh logs grafana
./k3s-dev-env.sh logs prometheus

# Restart cluster
./k3s-dev-env.sh stop
./k3s-dev-env.sh start
```

### Kubernetes Operations

```bash
# View cluster info
kubectl cluster-info

# Get all resources
kubectl get all --all-namespaces

# View nodes
kubectl get nodes -o wide

# Check pod status
kubectl get pods --all-namespaces -o wide
```

### Monitoring

```bash
# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Service status
kubectl get services --all-namespaces

# Ingress status
kubectl get ingress --all-namespaces
```

## 🔍 Verification Checklist

After setup, verify these items:

- [ ] K3s cluster is healthy: `kubectl get nodes`
- [ ] All pods are running: `kubectl get pods --all-namespaces`
- [ ] Ingress is configured: `kubectl get ingress --all-namespaces`
- [ ] Traefik is responding: `curl -I http://localhost:8080`
- [ ] Rancher is accessible: Visit http://localhost:8888
- [ ] Grafana shows data: Visit http://localhost:3000
- [ ] Prometheus has targets: Visit http://localhost:9090/targets

## 🐛 Common Issues

### Docker Issues

**Issue**: Docker not running
```bash
# Check Docker status
docker info

# Start Docker Desktop (macOS)
open -a Docker

# Start Docker service (Linux)
sudo systemctl start docker
```

**Issue**: Permission denied
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

### Network Issues

**Issue**: Port conflicts
```bash
# Check what's using ports
lsof -i :80
lsof -i :443
lsof -i :6443

# Stop conflicting services
sudo killall -9 nginx  # Example
```

### K3s Issues

**Issue**: Cluster won't start
```bash
# Check cluster status
k3d cluster list

# Restart cluster
./k3s-dev-env.sh stop
./k3s-dev-env.sh start

# Delete and recreate cluster
k3d cluster delete dev-cluster
./k3s-dev-env.sh start
```

### Service Issues

**Issue**: Service unreachable
```bash
# Check pod status
kubectl get pods --all-namespaces

# Check service logs
kubectl logs -n default deployment/grafana

# Describe service for debugging
kubectl describe service grafana
```

**Issue**: Ingress not working
```bash
# Check ingress status
kubectl get ingress --all-namespaces

# Check Traefik configuration
kubectl logs -n kube-system deployment/traefik
```

## 🎯 Next Steps

After successful setup:

1. **Explore Rancher**: Learn cluster management features
2. **Configure Monitoring**: Set up custom Grafana dashboards
3. **Deploy Applications**: Use kubectl or Rancher to deploy apps
4. **Set Up GitOps**: Configure ArgoCD for automated deployments
5. **Backup Strategy**: Configure regular backups of persistent data

## 📚 Additional Resources

### External Documentation
- [K3s Documentation](https://docs.k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [Rancher Documentation](https://rancher.com/docs/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Environment-Specific Documentation
For detailed configuration and usage guides specific to this environment, check the `docs/` directory:

- **Architecture**: `docs/architecture/README.md` - System architecture and design
- **ArgoCD**: `docs/argocd/README.md` - GitOps and deployment automation
- **Grafana**: `docs/grafana/README.md` - Monitoring dashboards and visualization
- **OpenSearch**: `docs/opensearch/README.md` - Log management and search
- **PostgreSQL**: `docs/postgresql/README.md` - Database management and integration
- **Prometheus**: `docs/prometheus/README.md` - Metrics collection and monitoring
- **Rancher**: `docs/rancher/README.md` - Kubernetes cluster management
- **Traefik**: `docs/traefik/README.md` - Ingress controller and load balancing
