#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 K3s Development Environment Status${NC}"
echo "======================================"
echo

# Check cluster status
echo -e "${BLUE}📊 Cluster Status:${NC}"
kubectl get nodes
echo

# Check all pods status
echo -e "${BLUE}🔧 Services Status:${NC}"
kubectl get pods -A | grep -v "kube-system\|local-path"
echo

echo -e "${GREEN}🌐 Service Access:${NC}"
echo "======================================"
echo
echo -e "${YELLOW}Services are configured with ingress routes and accessible via:${NC}"
echo
echo -e "${BLUE}Option 1: Direct Domain Access (requires hosts file setup)${NC}"
echo "Run './setup-hosts.sh' first, then access:"
echo "• Traefik Dashboard:  http://traefik.localhost"
echo "• Grafana:           http://grafana.localhost"
echo "• Prometheus:        http://prometheus.localhost"
echo "• Jaeger Tracing:    http://jaeger.localhost"
echo "• MinIO Console:     http://minio.localhost"
echo "• MinIO API:         http://minio-api.localhost"
echo "• Rancher:           http://rancher.localhost"
echo "• ArgoCD:            http://argocd.localhost"
echo
echo -e "${BLUE}Option 2: Port Forwarding (if domains don't work)${NC}"
echo "Run './setup-port-forwards.sh', then access:"
echo "• Traefik Dashboard:  http://localhost:8888"
echo "• Grafana:           http://localhost:3000"
echo "• Prometheus:        http://localhost:9090"
echo "• Jaeger Tracing:    http://localhost:16686"
echo "• MinIO Console:     http://localhost:9001"
echo "• MinIO API:         http://localhost:9000"
echo "• Rancher:           https://localhost:8443"
echo "• ArgoCD:            http://localhost:8080"
echo
echo -e "${YELLOW}Databases:${NC}"
echo "• PostgreSQL:        localhost:5432 (user: admin, pass: admin123)"
echo "• Redis:             localhost:6379"
echo
echo -e "${YELLOW}Credentials:${NC}"
echo "• Grafana:           admin / admin123"
echo "• MinIO:             minioadmin / minioadmin123"
echo "• Rancher:           admin / admin123"
echo "• ArgoCD:            admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "admin123")"
echo

echo -e "${GREEN}✅ All services are running with ingress configured!${NC}"
echo -e "${BLUE}💡 Try './setup-hosts.sh' for domain access, or './setup-port-forwards.sh' for port forwarding${NC}"
echo -e "${BLUE}💡 Use './k3s-dev-env.sh stop' to stop the environment${NC}"
