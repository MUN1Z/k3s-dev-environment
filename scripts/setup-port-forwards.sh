#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Port Forwards for K3s Services${NC}"
echo "============================================="
echo

# Kill existing port forwards
echo -e "${YELLOW}Stopping existing port forwards...${NC}"
pkill -f "kubectl port-forward" || true
sleep 2

echo -e "${BLUE}Starting port forwards...${NC}"

# Start port forwards in background
kubectl port-forward -n traefik-system svc/traefik 8888:8080 > /dev/null 2>&1 &
echo "✅ Traefik Dashboard: http://localhost:8888"

kubectl port-forward -n development svc/grafana 3000:3000 > /dev/null 2>&1 &
echo "✅ Grafana: http://localhost:3000"

kubectl port-forward -n development svc/prometheus 9090:9090 > /dev/null 2>&1 &
echo "✅ Prometheus: http://localhost:9090"

kubectl port-forward -n development svc/jaeger 16686:16686 > /dev/null 2>&1 &
echo "✅ Jaeger: http://localhost:16686"

kubectl port-forward -n development svc/minio 9001:9001 > /dev/null 2>&1 &
echo "✅ MinIO Console: http://localhost:9001"

kubectl port-forward -n development svc/minio 9000:9000 > /dev/null 2>&1 &
echo "✅ MinIO API: http://localhost:9000"

kubectl port-forward -n cattle-system svc/rancher 8443:443 > /dev/null 2>&1 &
echo "✅ Rancher: https://localhost:8443"

kubectl port-forward -n argocd svc/argocd-server 8080:80 > /dev/null 2>&1 &
echo "✅ ArgoCD: http://localhost:8080"

kubectl port-forward -n development svc/postgres 5432:5432 > /dev/null 2>&1 &
echo "✅ PostgreSQL: localhost:5432"

kubectl port-forward -n development svc/redis 6379:6379 > /dev/null 2>&1 &
echo "✅ Redis: localhost:6379"

echo
echo -e "${GREEN}🎉 All services are now accessible!${NC}"
echo
echo -e "${YELLOW}Credentials:${NC}"
echo "• Grafana: admin / admin123"
echo "• MinIO: minioadmin / minioadmin123"  
echo "• Rancher: admin / admin123"
echo "• ArgoCD: admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "admin123")"
echo "• PostgreSQL: admin / admin123"
echo
echo -e "${BLUE}💡 To stop all port forwards: pkill -f 'kubectl port-forward'${NC}"
echo -e "${BLUE}💡 Port forwards will stop when you close this terminal${NC}"
