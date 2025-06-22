#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 K3s Development Environment Access Setup${NC}"
echo "=================================================="
echo

echo -e "${BLUE}📋 Setting up local access to services...${NC}"
echo

# Check if we can access services
echo -e "${YELLOW}Testing service accessibility...${NC}"

# Test basic connectivity
if curl -s --connect-timeout 3 http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Port 8080 is accessible"
else
    echo "❌ Port 8080 is not accessible"
fi

if curl -s --connect-timeout 3 http://localhost > /dev/null 2>&1; then
    echo "✅ Port 80 is accessible"
else
    echo "❌ Port 80 is not accessible"
fi

echo
echo -e "${YELLOW}Creating hosts file entries...${NC}"

# Create hosts entries
HOSTS_ENTRIES="
# K3s Development Environment
127.0.0.1 traefik.localhost
127.0.0.1 grafana.localhost
127.0.0.1 prometheus.localhost
127.0.0.1 jaeger.localhost
127.0.0.1 minio.localhost
127.0.0.1 minio-api.localhost
127.0.0.1 rancher.localhost"

echo "Please add the following entries to your /etc/hosts file:"
echo
echo "$HOSTS_ENTRIES"
echo

echo -e "${BLUE}To add these automatically, run:${NC}"
echo "sudo bash -c 'echo \"$HOSTS_ENTRIES\" >> /etc/hosts'"
echo

echo -e "${YELLOW}Alternative access methods:${NC}"
echo "If the .localhost domains don't work, you can use port forwarding:"
echo

echo "kubectl port-forward -n traefik-system svc/traefik 8080:8080 &"
echo "kubectl port-forward -n development svc/grafana 3000:3000 &"
echo "kubectl port-forward -n development svc/prometheus 9090:9090 &"
echo "kubectl port-forward -n development svc/jaeger 16686:16686 &"
echo "kubectl port-forward -n development svc/minio 9001:9001 &"
echo "kubectl port-forward -n cattle-system svc/rancher 8443:443 &"
echo

echo -e "${GREEN}Then access services at:${NC}"
echo "• Traefik Dashboard: http://localhost:8080"
echo "• Grafana: http://localhost:3000"
echo "• Prometheus: http://localhost:9090"
echo "• Jaeger: http://localhost:16686"
echo "• MinIO: http://localhost:9001"
echo "• Rancher: https://localhost:8443"
echo

echo -e "${BLUE}💡 Run './setup-port-forwards.sh' to start all port forwards automatically${NC}"
