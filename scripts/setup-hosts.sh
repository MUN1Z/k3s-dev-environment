#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Configuring Hosts for K3s Services${NC}"
echo "========================================"
echo

HOSTS_ENTRIES="
# K3s Development Environment
127.0.0.1 traefik.localhost
127.0.0.1 grafana.localhost
127.0.0.1 prometheus.localhost
127.0.0.1 jaeger.localhost
127.0.0.1 minio.localhost
127.0.0.1 minio-api.localhost
127.0.0.1 rancher.localhost
127.0.0.1 argocd.localhost"

echo -e "${YELLOW}Adding entries to /etc/hosts...${NC}"
echo "This requires administrator privileges."
echo

# Try to add the entries
if sudo bash -c "echo '$HOSTS_ENTRIES' >> /etc/hosts"; then
    echo -e "${GREEN}✅ Hosts entries added successfully!${NC}"
    echo
    echo -e "${BLUE}Services are now accessible at:${NC}"
    echo "• Traefik Dashboard:  http://traefik.localhost"
    echo "• Grafana:           http://grafana.localhost"
    echo "• Prometheus:        http://prometheus.localhost"
    echo "• Jaeger:            http://jaeger.localhost"
    echo "• MinIO Console:     http://minio.localhost"
    echo "• MinIO API:         http://minio-api.localhost"
    echo "• Rancher:           http://rancher.localhost"
    echo "• ArgoCD:            http://argocd.localhost"
    echo
    echo -e "${YELLOW}Note: Some services may take a moment to become available.${NC}"
else
    echo -e "${RED}❌ Failed to add hosts entries.${NC}"
    echo -e "${YELLOW}You can manually add these entries to /etc/hosts:${NC}"
    echo "$HOSTS_ENTRIES"
fi
