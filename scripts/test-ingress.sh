#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Testing Ingress Configuration${NC}"
echo "=================================="
echo

# Test function
test_service() {
    local service_name="$1"
    local host="$2"
    local expected_code="$3"
    
    echo -n "Testing $service_name ($host)... "
    
    # Test with Host header
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $host" http://localhost --connect-timeout 5)
    
    if [[ "$response" == "$expected_code" ]] || [[ "$response" == "200" ]] || [[ "$response" == "302" ]]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $response)"
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
    fi
}

echo -e "${YELLOW}Testing services with Host headers:${NC}"
echo

# Test each service
test_service "Grafana" "grafana.localhost" "302"
test_service "Prometheus" "prometheus.localhost" "200"
test_service "Jaeger" "jaeger.localhost" "200"
test_service "MinIO Console" "minio.localhost" "200"
test_service "MinIO API" "minio-api.localhost" "403"
test_service "Rancher" "rancher.localhost" "200"
test_service "Traefik Dashboard" "traefik.localhost" "200"

echo
echo -e "${BLUE}Checking ingress routes:${NC}"
kubectl get ingressroutes -A

echo
echo -e "${BLUE}Checking Traefik service:${NC}"
kubectl get svc -n traefik-system traefik

echo
echo -e "${YELLOW}Note: If tests fail, the ingress routes are configured but may need:${NC}"
echo "1. Time for k3d load balancer to initialize"
echo "2. Proper /etc/hosts entries (run ./setup-hosts.sh)"
echo "3. Alternative access via port forwarding (run ./setup-port-forwards.sh)"
