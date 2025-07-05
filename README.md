# K3s Development Environment

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![K3s](https://img.shields.io/badge/K3s-FFC61E?style=for-the-badge&logo=k3s&logoColor=black)](https://k3s.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefik&logoColor=white)](https://traefik.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code Quality](https://img.shields.io/badge/Code%20Quality-A+-brightgreen.svg)](https://github.com/BrewertonSantos/k3s-dev-environment)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![GitFlow](https://img.shields.io/badge/GitFlow-Enabled-blue.svg)](https://nvie.com/posts/a-successful-git-branching-model/)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

A complete development environment using **Kubernetes (K3s)** with all services running as native Kubernetes deployments. This environment provides monitoring, storage, databases, and management tools for modern application development.

## 🚀 Quick Start

```bash
# Start the complete K3s environment
./scripts/k3s-dev-env.sh start

# View service status and access URLs
./scripts/show-services.sh

# Stop the environment
./scripts/k3s-dev-env.sh stop
```

## 📋 Included Services

| Service | Namespace | Primary URL | Alt Access | Credentials |
|---------|-----------|-------------|------------|-------------|
| **Traefik** (Ingress Controller) | traefik-system | http://traefik.localhost | http://localhost:8888 | - |
| **Grafana** (Dashboards) | development | http://grafana.localhost | http://localhost:3000 | admin/admin123 |
| **Prometheus** (Monitoring) | development | http://prometheus.localhost | http://localhost:9090 | - |
| **Jaeger** (Tracing) | development | http://jaeger.localhost | http://localhost:16686 | - |
| **MinIO Console** (Storage UI) | development | http://minio.localhost | http://localhost:9001 | minioadmin/minioadmin123 |
| **MinIO API** (S3 API) | development | http://minio-api.localhost | http://localhost:9000 | - |
| **Rancher** (K8s Management) | cattle-system | http://rancher.localhost | https://localhost:8443 | admin/admin123 |
| **ArgoCD** (GitOps) | argocd | http://argocd.localhost | http://localhost:8080 | admin/admin123 |
| **PostgreSQL** (Database) | development | localhost:5432 | - | admin/admin123 |
| **Redis** (Cache) | development | localhost:6379 | - | - |

## 🌐 Service Access Methods

### Method 1: Domain Access (Recommended)
```bash
# Setup domain resolution
./scripts/setup-hosts.sh

# Access services via .localhost domains
# All URLs are listed in the table above
```

### Method 2: Port Forwarding (Fallback)
```bash
# Setup port forwarding
./scripts/setup-port-forwards.sh

# Access services via localhost ports
# Alternative URLs are listed in the table above
```

## 🛠️ Available Commands

### Environment Management
```bash
./k3s-dev-env.sh start      # Start complete environment
./k3s-dev-env.sh stop       # Stop and remove cluster
./k3s-dev-env.sh restart    # Restart environment
./k3s-dev-env.sh status     # Show cluster status
./k3s-dev-env.sh logs       # Show service logs
```

### Service Access Setup
```bash
./scripts/show-services.sh          # Display current status and URLs
./scripts/setup-hosts.sh            # Configure /etc/hosts for domain access
./scripts/setup-port-forwards.sh    # Setup port forwarding access
./scripts/setup-access.sh           # Get help with access configuration
./scripts/test-ingress.sh           # Test ingress connectivity
./scripts/verify-urls.sh            # Verify all documented URLs are accessible
```

### Cleanup and Migration
```bash
./scripts/docker-cleanup.sh         # Remove Docker containers (one-time migration)
./scripts/health-check.sh           # Check environment health
```

## 📁 Project Structure

```
k3s-dev-environment/
├── k3s-dev-env.sh               # Main environment management script
├── show-services.sh             # Service status and URLs
├── setup-hosts.sh               # Domain access configuration
├── setup-port-forwards.sh       # Port forwarding setup
├── setup-access.sh              # Access help and troubleshooting
├── test-ingress.sh              # Ingress connectivity testing
├── health-check.sh              # Environment health check
├── docker-cleanup.sh            # Migration cleanup script
├── k8s-manifests/               # Kubernetes manifests
│   ├── postgres.yaml            # PostgreSQL deployment
│   ├── redis.yaml               # Redis deployment
│   ├── prometheus.yaml          # Prometheus deployment
│   ├── grafana.yaml             # Grafana deployment
│   ├── jaeger.yaml              # Jaeger deployment
│   ├── minio.yaml               # MinIO deployment
│   ├── rancher.yaml             # Rancher deployment
│   ├── argocd.yaml              # ArgoCD deployment
│   ├── traefik.yaml             # Traefik ingress controller
│   └── ingress.yaml             # Service ingress routes
├── config/                      # Service configurations
│   ├── prometheus/
│   └── grafana/
└── docs/                        # Service-specific documentation
    ├── architecture/
    ├── grafana/
    ├── prometheus/
    ├── traefik/
    └── rancher/
```

## � Initial Setup

### Prerequisites
- **Docker**: For K3s cluster (k3d)
- **k3d**: v5.4.0 or higher
- **kubectl**: Kubernetes CLI
- **Operating System**: macOS, Linux, or Windows with WSL2
- **RAM**: Minimum 4GB, recommended 8GB+
- **Disk Space**: ~3GB for K3s images and data

### Installation Steps

1. **Install dependencies**:
   ```bash
   # Install docker (if not already installed)
   # macOS: See https://docs.docker.com/desktop/setup/install/mac-install/
   # Linux: See https://docs.docker.com/engine/install/ubuntu/

   # Install k3d
   curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
   
   # Install kubectl (if not already installed)
   # macOS: brew install kubectl
   # Linux: See https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
   ```

2. **Clone and setup**:
   ```bash
   git clone <repo-url>
   cd k3s-dev-environment
   chmod +x scripts/*.sh
   ```

3. **Start the environment**:
   ```bash
   ./scripts/k3s-dev-env.sh start
   ```

4. **Verify and access services**:
   ```bash
   # Check status
   ./scripts/show-services.sh
   
   # Setup access (choose one method)
   ./scripts/setup-hosts.sh              # For domain access
   ./scripts/setup-port-forwards.sh      # For port forwarding
   ```

## 🏗️ Architecture

The environment uses a multi-namespace Kubernetes architecture:

```mermaid
graph TB
    User[👤 User] --> LB[� k3d LoadBalancer :80]
    
    LB --> Traefik[🚦 Traefik Ingress Controller]
    
    Traefik --> Grafana[📊 Grafana<br/>development ns]
    Traefik --> Prometheus[📈 Prometheus<br/>development ns]
    Traefik --> Jaeger[🔍 Jaeger<br/>development ns]
    Traefik --> MinIO[💾 MinIO<br/>development ns]
    Traefik --> Rancher[🐄 Rancher<br/>cattle-system ns]
    
    Grafana --> PromSvc[Prometheus Service]
    
    App[🚀 Your Application] --> PostgreSQL[🐘 PostgreSQL<br/>development ns]
    App --> Redis[🔴 Redis<br/>development ns]
    App --> MinIO
    
    PostgreSQL --> PgPV[📁 postgres-data PV]
    MinIO --> MinioPV[📁 minio-data PV]
    Grafana --> GrafanaPV[📁 grafana-data PV]
    Prometheus --> PromPV[📁 prometheus-data PV]
    Redis --> RedisPV[📁 redis-data PV]
```

### Namespace Organization
- **traefik-system**: Traefik ingress controller and dashboard
- **development**: Core application services (databases, monitoring, storage)
- **cattle-system**: Rancher management interface
- **argocd**: GitOps continuous delivery platform
- **kube-system**: Kubernetes system components

### Network Architecture
- **External Access**: k3d LoadBalancer → Traefik → Services
- **Internal Communication**: Service-to-service via cluster DNS
- **Data Access**: Applications connect to databases via service names
- **Storage**: Persistent volumes for stateful services

## 📖 Additional Documentation

- **🔧 Complete Reference**: [ENVIRONMENT_REFERENCE.md](ENVIRONMENT_REFERENCE.md) - All URLs, credentials, and configurations
- **⚡ Quick Start**: [QUICK_START.md](QUICK_START.md) - Get running in 3 commands
- **🌐 Service Access**: [SERVICE_ACCESS.md](SERVICE_ACCESS.md) - Access methods and troubleshooting
- **🔗 Ingress Details**: [INGRESS_STATUS.md](INGRESS_STATUS.md) - Ingress configuration and routing
- **📋 Project Overview**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Architecture and features
- **🏗️ Architecture**: `docs/architecture/README.md` - System design and diagrams
- **📊 Service Guides**: `docs/[service-name]/README.md` - Individual service documentation

## 🔍 Service Details

### Monitoring and Observability

#### Prometheus
- **URL**: http://prometheus.localhost (or localhost:9090)
- **Function**: Metrics collection and storage
- **Targets**: Kubernetes services and pods
- **Storage**: Persistent volume for data retention

#### Grafana
- **URL**: http://grafana.localhost (or localhost:3000)
- **Login**: admin/admin123
- **Datasource**: Pre-configured Prometheus connection
- **Dashboards**: Kubernetes cluster monitoring included

#### Jaeger
- **URL**: http://jaeger.localhost (or localhost:16686)
- **Function**: Distributed tracing for microservices
- **Storage**: In-memory (development mode)

### Storage and Data

#### MinIO
- **Console**: http://minio.localhost (or localhost:9001)
- **API**: http://minio-api.localhost (or localhost:9000)
- **Login**: minioadmin/minioadmin123
- **Function**: S3-compatible object storage
- **Storage**: Persistent volume for data retention

#### PostgreSQL
- **Host**: localhost:5432
- **Database**: devdb
- **User**: admin
- **Password**: admin123
- **Function**: Primary application database

#### Redis
- **Host**: localhost:6379
- **Function**: Caching and session storage
- **Storage**: Persistent volume for snapshots

### Management and Networking

#### Traefik
- **Dashboard**: http://traefik.localhost (or localhost:8888)
- **Function**: Ingress controller and load balancer
- **Features**: Automatic service discovery, SSL termination ready

#### Rancher
- **URL**: http://rancher.localhost (or https://localhost:8443)
- **Login**: admin/admin123
- **Function**: Kubernetes cluster management and monitoring
- **Features**: Workload management, resource monitoring

#### ArgoCD
- **URL**: http://argocd.localhost (or localhost:8080)
- **Login**: admin/admin123
- **Function**: GitOps continuous delivery platform
- **Features**: Application deployment, Git-based workflows, multi-environment management

## � Data Persistence

All data is persisted using Kubernetes PersistentVolumes:
- **postgres-data**: PostgreSQL database files
- **redis-data**: Redis snapshots and AOF files
- **prometheus-data**: Historical metrics and configurations
- **grafana-data**: Dashboards, datasources, and user configurations
- **minio-data**: Object storage files and metadata
- **rancher-data**: Rancher configurations and cluster data

## �🔒 Security Notes

⚠️ **Development Environment Only**: This environment uses simplified security for local development.

### Default Credentials
- **Grafana**: admin/admin123
- **MinIO**: minioadmin/minioadmin123
- **PostgreSQL**: admin/admin123
- **Rancher**: admin/admin123
- **ArgoCD**: admin/admin123

### Security Features
- Database services (PostgreSQL, Redis) are not exposed externally
- Ingress controller handles all external traffic
- Services communicate within the cluster network
- Persistent data is isolated in named volumes

## 🚨 Troubleshooting

### Quick Diagnostics
```bash
# Check overall environment status
./scripts/show-services.sh

# Test connectivity
./scripts/test-ingress.sh

# Check environment health
./scripts/health-check.sh
```

### Common Issues

#### Services not accessible via domain
```bash
# Check hosts file configuration
./scripts/setup-hosts.sh

# Verify DNS resolution
nslookup grafana.localhost

# Test with curl
curl -H "Host: grafana.localhost" http://localhost
```

#### Port forwarding issues
```bash
# Stop existing port forwards
pkill -f 'kubectl port-forward'

# Restart port forwarding
./scripts/setup-port-forwards.sh
```

#### Service startup problems
```bash
# Check pod status
kubectl get pods --all-namespaces

# View service logs
./k3s-dev-env.sh logs

# Restart environment
./k3s-dev-env.sh restart
```

#### Complete cleanup
```bash
# Remove everything and start fresh
./k3s-dev-env.sh stop
./k3s-dev-env.sh start
```

### Debug Commands
```bash
# View specific service logs
kubectl logs -n development deployment/grafana

# Access a pod shell
kubectl exec -it deployment/grafana -n development -- /bin/sh

# Check ingress routes
kubectl get ingressroutes -A

# Verify Traefik configuration
kubectl get svc -n traefik-system traefik
```

## 🤝 Contributing

1. Fork the project
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Test your changes: `./scripts/health-check.sh`
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
