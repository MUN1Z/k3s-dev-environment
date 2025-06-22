# K3s Development Environment - Complete Reference

This document provides a comprehensive reference for all services, URLs, credentials, and configuration details in the K3s development environment.

## 🚀 Environment Status

**Current Version**: v2.0.0 (Kubernetes-Native)  
**Cluster Type**: k3d-managed K3s cluster  
**Nodes**: 1 server + 2 agents  
**Ingress**: Traefik with LoadBalancer  

## 📊 Service Directory

### 🌐 Web Services (Ingress-Enabled)

| Service | Primary URL | Port Forward | Namespace | Purpose | Credentials |
|---------|-------------|--------------|-----------|---------|-------------|
| **Traefik Dashboard** | http://traefik.localhost | http://localhost:8888 | traefik-system | Ingress controller dashboard | None |
| **Grafana** | http://grafana.localhost | http://localhost:3000 | development | Monitoring dashboards | admin/admin123 |
| **Prometheus** | http://prometheus.localhost | http://localhost:9090 | development | Metrics collection | None |
| **Jaeger** | http://jaeger.localhost | http://localhost:16686 | development | Distributed tracing | None |
| **MinIO Console** | http://minio.localhost | http://localhost:9001 | development | Object storage UI | minioadmin/minioadmin123 |
| **MinIO API** | http://minio-api.localhost | http://localhost:9000 | development | S3-compatible API | - |
| **Rancher** | http://rancher.localhost | https://localhost:8443 | cattle-system | Kubernetes management | admin/admin123 |
| **ArgoCD** | http://argocd.localhost | http://localhost:8080 | argocd | GitOps continuous delivery | admin/admin123 |

### 🔗 Database Services (Internal)

| Service | Connection | Database | Username | Password | Purpose |
|---------|------------|----------|----------|----------|---------|
| **PostgreSQL** | localhost:5432 | devdb | admin | admin123 | Primary database |
| **Redis** | localhost:6379 | - | - | - | Cache & sessions |

*Database services require port forwarding for external access*

## 🌐 Access Configuration

### Method 1: Domain Access (Recommended)

```bash
# Setup hosts file (run once)
./setup-hosts.sh

# Hosts file entries added:
# 127.0.0.1 grafana.localhost
# 127.0.0.1 prometheus.localhost
# 127.0.0.1 traefik.localhost
# 127.0.0.1 jaeger.localhost
# 127.0.0.1 minio.localhost
# 127.0.0.1 minio-api.localhost
# 127.0.0.1 rancher.localhost
# 127.0.0.1 argocd.localhost

# Access services directly via browser
open http://grafana.localhost
```

### Method 2: Port Forwarding (Fallback)

```bash
# Setup port forwards
./setup-port-forwards.sh

# Port mapping:
# 3000  → Grafana
# 9090  → Prometheus
# 8888  → Traefik Dashboard
# 16686 → Jaeger
# 9001  → MinIO Console
# 9000  → MinIO API
# 8443  → Rancher (HTTPS)
# 8080  → ArgoCD
# 5432  → PostgreSQL
# 6379  → Redis
```

## 🏗️ Network Architecture

```
External Request → k3d LoadBalancer:80 → Traefik Ingress Controller
                                        ↓
                              Host-based routing:
                              ├── grafana.localhost → Grafana:3000
                              ├── prometheus.localhost → Prometheus:9090
                              ├── jaeger.localhost → Jaeger:16686
                              ├── minio.localhost → MinIO:9001
                              ├── minio-api.localhost → MinIO:9000
                              ├── rancher.localhost → Rancher:80
                              ├── argocd.localhost → ArgoCD:80
                              └── traefik.localhost → Traefik:8080
```

## 📁 Configuration Files

### Kubernetes Manifests
```
k8s-manifests/
├── traefik.yaml      # Ingress controller, RBAC, ConfigMap
├── ingress.yaml      # IngressRoutes for all services
├── grafana.yaml      # Grafana deployment with persistent storage
├── prometheus.yaml   # Prometheus with configuration
├── jaeger.yaml       # Jaeger tracing platform
├── minio.yaml        # MinIO object storage
├── postgres.yaml     # PostgreSQL database
├── redis.yaml        # Redis cache
├── rancher.yaml      # Rancher management platform
└── argocd.yaml       # ArgoCD GitOps platform
```

### Service Configurations
```
config/
├── prometheus/
│   └── prometheus.yml    # Prometheus targets and rules
└── grafana/
    └── datasources/
        └── prometheus.yml    # Grafana datasource configuration
```

## 🛠️ Management Commands

### Environment Control
```bash
./k3s-dev-env.sh start      # Start complete environment
./k3s-dev-env.sh stop       # Stop and cleanup cluster
./k3s-dev-env.sh restart    # Restart environment
./k3s-dev-env.sh status     # Show cluster and pod status
./k3s-dev-env.sh logs       # View all service logs
```

### Access Setup
```bash
./show-services.sh          # Display status and all URLs
./setup-hosts.sh            # Configure domain access
./setup-port-forwards.sh    # Setup port forwarding
./setup-access.sh           # Access help and alternatives
```

### Troubleshooting
```bash
./test-ingress.sh           # Test ingress connectivity
./health-check.sh           # Environment health check
pkill -f 'kubectl port-forward'  # Stop all port forwards
```

## 💾 Data Persistence

All stateful services use Kubernetes PersistentVolumes:

| Service | Volume Name | Data Location | Retention |
|---------|-------------|---------------|-----------|
| PostgreSQL | postgres-data | Database files | Persistent |
| Redis | redis-data | Snapshots & AOF | Persistent |
| Grafana | grafana-data | Dashboards & configs | Persistent |
| Prometheus | prometheus-data | Metrics & rules | Persistent |
| MinIO | minio-data | Object storage | Persistent |
| Rancher | rancher-data | Cluster configs | Persistent |
| ArgoCD | argocd-data | GitOps configs | Persistent |

## 🔧 Service-Specific Details

### Grafana Configuration
- **Pre-configured datasources**: Prometheus
- **Default dashboards**: Kubernetes cluster monitoring
- **Data source URL**: http://prometheus.development.svc.cluster.local:9090
- **Admin password**: admin123 (change for production)

### Prometheus Configuration
- **Scrape interval**: 15s
- **Targets**: Kubernetes API, nodes, pods, services
- **Storage retention**: 30 days (configurable)
- **Configuration file**: `config/prometheus/prometheus.yml`

### MinIO Configuration
- **Console port**: 9001 (UI)
- **API port**: 9000 (S3 API)
- **Default bucket**: Auto-created
- **Access patterns**: S3-compatible API calls

### PostgreSQL Configuration
- **Port**: 5432
- **Database**: devdb
- **Encoding**: UTF-8
- **Connection limit**: 100 (configurable)

### Traefik Configuration
- **Entry points**: web:80, websecure:443, traefik:8080
- **API dashboard**: Enabled (development mode)
- **Auto-discovery**: Kubernetes IngressRoute CRDs
- **Load balancing**: Round-robin

## 🔒 Security Configuration

### RBAC (Role-Based Access Control)
- Traefik has ClusterRole for ingress management
- Rancher has cluster-admin permissions for management
- Services isolated by namespace permissions

### Network Security
- Database services (PostgreSQL, Redis) not exposed externally
- All external access goes through Traefik ingress
- Service-to-service communication via cluster DNS

### Default Credentials (Development Only)
- **Grafana**: admin/admin123
- **MinIO**: minioadmin/minioadmin123
- **Rancher**: admin/admin123
- **ArgoCD**: admin/admin123
- **PostgreSQL**: admin/admin123

## 🚨 Troubleshooting Reference

### Common Issues & Solutions

#### Services not accessible via domain
```bash
# Check hosts file
cat /etc/hosts | grep localhost

# Re-run hosts setup
./setup-hosts.sh

# Test DNS resolution
nslookup grafana.localhost
```

#### Port forwarding not working
```bash
# Kill existing forwards
pkill -f 'kubectl port-forward'

# Check pods are running
kubectl get pods -A

# Restart port forwards
./setup-port-forwards.sh
```

#### Service startup issues
```bash
# Check pod status
kubectl get pods -n development

# View service logs
kubectl logs -n development deployment/grafana

# Check ingress routes
kubectl get ingressroutes -A
```

#### Ingress routing problems
```bash
# Check Traefik status
kubectl get pods -n traefik-system

# View Traefik logs
kubectl logs -n traefik-system deployment/traefik

# Test with Host header
curl -H "Host: grafana.localhost" http://localhost
```

## 📖 Documentation Index

- **[README.md](README.md)**: Complete setup and architecture guide
- **[QUICK_START.md](QUICK_START.md)**: Fast setup instructions
- **[SERVICE_ACCESS.md](SERVICE_ACCESS.md)**: Service access methods
- **[INGRESS_STATUS.md](INGRESS_STATUS.md)**: Ingress configuration details
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)**: Project overview and features
- **[docs/](docs/)**: Service-specific documentation

## 🎯 Quick Reference Commands

```bash
# Essential commands for daily use
./k3s-dev-env.sh start && ./show-services.sh    # Start and check
./setup-hosts.sh                                # Enable domains
open http://grafana.localhost                   # Quick access
./k3s-dev-env.sh logs | grep ERROR              # Check for errors
./k3s-dev-env.sh stop                          # Clean shutdown
```

---

**This reference contains all the information needed to work with the K3s development environment. For detailed setup instructions, see [README.md](README.md).**
