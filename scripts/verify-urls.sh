#!/bin/bash

# K3s Development Environment - URL Verification
# Tests all documented service URLs to ensure they're accessible

echo "🔍 K3s Development Environment - URL Verification"
echo "================================================="
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test URL
test_url() {
    local url=$1
    local name=$2
    local expected_code=$3
    
    printf "Testing %-25s " "$name:"
    
    # Test with curl
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
    
    if [[ "$response" == "200" ]] || [[ "$response" == "302" ]] || [[ "$response" == "405" ]] || [[ "$response" == "301" ]] || [[ "$response" == "403" ]] || [[ "$response" == "307" ]]; then
        echo -e "${GREEN}✅ OK ($response)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed ($response)${NC}"
        return 1
    fi
}

echo "🌐 Testing Domain Access (requires ./setup-hosts.sh):"
echo "---------------------------------------------------"

# Test domain URLs
test_url "http://traefik.localhost" "Traefik Dashboard"
test_url "http://grafana.localhost" "Grafana"
test_url "http://prometheus.localhost" "Prometheus"
test_url "http://jaeger.localhost" "Jaeger"
test_url "http://minio.localhost" "MinIO Console"
test_url "http://minio-api.localhost" "MinIO API"
test_url "http://rancher.localhost" "Rancher"
test_url "http://argocd.localhost" "ArgoCD"

echo
echo "🔌 Testing Port Forward Access (requires ./setup-port-forwards.sh):"
echo "-------------------------------------------------------------------"

# Test port forward URLs
test_url "http://localhost:8888" "Traefik (8888)"
test_url "http://localhost:3000" "Grafana (3000)"
test_url "http://localhost:9090" "Prometheus (9090)"
test_url "http://localhost:16686" "Jaeger (16686)"
test_url "http://localhost:9001" "MinIO Console (9001)"
test_url "http://localhost:9000" "MinIO API (9000)"
test_url "https://localhost:8443" "Rancher (8443)" 
test_url "http://localhost:8080" "ArgoCD (8080)" 

echo
echo "💡 Notes:"
echo "• Domain access requires: ./setup-hosts.sh"
echo "• Port forward access requires: ./setup-port-forwards.sh"
echo "• 200, 301, 302, 307, 403, 405 response codes are considered successful"
echo "• Database services (PostgreSQL:5432, Redis:6379) require port forwarding"
echo
echo "📖 For complete documentation see:"
echo "• README.md - Complete setup guide"
echo "• ENVIRONMENT_REFERENCE.md - All URLs and credentials"
echo "• SERVICE_ACCESS.md - Access troubleshooting"
