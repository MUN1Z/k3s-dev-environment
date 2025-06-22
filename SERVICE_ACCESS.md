# Service Access Guide

Quick reference for accessing services in the K3s development environment.

## 🚀 Quick Access

### Check Current Status
```bash
./show-services.sh    # Shows all service URLs and status
```

## 🌐 Access Methods

### Method 1: Domain Access (Recommended)
```bash
# Setup hosts file (one-time)
./setup-hosts.sh

# Access services directly
open http://grafana.localhost
open http://prometheus.localhost
open http://traefik.localhost
open http://jaeger.localhost
open http://minio.localhost
open http://rancher.localhost
```

### Method 2: Port Forwarding (Fallback)
```bash
# Setup port forwards
./setup-port-forwards.sh

# Access via localhost ports
open http://localhost:3000    # Grafana
open http://localhost:9090    # Prometheus
open http://localhost:8888    # Traefik
open http://localhost:16686   # Jaeger
open http://localhost:9001    # MinIO Console
open https://localhost:8443   # Rancher
```

### Stop Port Forwards
```bash
pkill -f 'kubectl port-forward'
```

## 🔑 Service Credentials

| Service | Username | Password |
|---------|----------|----------|
| Grafana | admin | admin123 |
| MinIO | minioadmin | minioadmin123 |
| Rancher | admin | admin123 |
| PostgreSQL | admin | admin123 |

## 🔧 Database Connections

### PostgreSQL
```bash
# Via kubectl port forward
kubectl port-forward -n development svc/postgres 5432:5432

# Connection string
postgresql://admin:admin123@localhost:5432/devdb
```

### Redis
```bash
# Via kubectl port forward
kubectl port-forward -n development svc/redis 6379:6379

# Connect with redis-cli
redis-cli -h localhost -p 6379
```

## ⚡ Quick Commands

```bash
# Environment management
./k3s-dev-env.sh start      # Start environment
./k3s-dev-env.sh stop       # Stop environment
./k3s-dev-env.sh restart    # Restart environment

# Access setup
./setup-hosts.sh            # Setup domain access
./setup-port-forwards.sh    # Setup port forwarding
./test-ingress.sh           # Test connectivity

# Troubleshooting
./health-check.sh           # Check environment health
./k3s-dev-env.sh logs       # View all logs
```

## 🚨 Troubleshooting Access Issues

### Domain Access Not Working
```bash
# Check hosts file
cat /etc/hosts | grep localhost

# Test DNS resolution
nslookup grafana.localhost

# Manual hosts setup
echo "127.0.0.1 grafana.localhost prometheus.localhost traefik.localhost jaeger.localhost minio.localhost minio-api.localhost rancher.localhost" | sudo tee -a /etc/hosts
```

### Port Forward Issues
```bash
# Kill existing forwards
pkill -f 'kubectl port-forward'

# Check if pods are running
kubectl get pods -n development
kubectl get pods -n cattle-system

# Restart port forwards
./setup-port-forwards.sh
```

### Service Not Responding
```bash
# Check service status
kubectl get svc -A

# Check pod logs
kubectl logs -n development deployment/grafana

# Restart specific service
kubectl rollout restart deployment/grafana -n development
```

See the main [README.md](README.md) for complete documentation and architecture details.
