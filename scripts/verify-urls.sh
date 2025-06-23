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
    
    # Test with curl (use -k for HTTPS URLs to ignore self-signed certificates)
    if [[ "$url" == https* ]]; then
        response=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
    fi
    
    if [[ "$response" == "200" ]] || [[ "$response" == "302" ]] || [[ "$response" == "405" ]] || [[ "$response" == "301" ]] || [[ "$response" == "403" ]] || [[ "$response" == "307" ]]; then
        echo -e "${GREEN}✅ OK ($response)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed ($response)${NC}"
        return 1
    fi
}

# Function to test TCP connection
test_tcp() {
    local host=$1
    local port=$2
    local name=$3
    
    printf "Testing %-25s " "$name:"
    
    # Test TCP connectivity
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w5 "$host" "$port" 2>/dev/null; then
            echo -e "${GREEN}✅ OK (TCP)${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed (TCP)${NC}"
            return 1
        fi
    else
        # Fallback to telnet if nc is not available
        if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            echo -e "${GREEN}✅ OK (TCP)${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed (TCP)${NC}"
            return 1
        fi
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
test_url "http://argocd.localhost" "ArgoCD"
test_url "https://rancher.localhost" "Rancher"
test_url "http://postgres.localhost" "pgAdmin4"

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
test_url "http://localhost:8080" "ArgoCD (8080)" 

echo
echo "🗄️  Testing TCP Services (Database Access):"
echo "--------------------------------------------"

# Test TCP services
test_tcp "127.0.0.1" "5432" "PostgreSQL (Direct)"

echo
echo "🐘 Testing pgAdmin4 Functionality:"
echo "----------------------------------"

# Test pgAdmin4 login page
test_url "http://postgres.localhost/login" "pgAdmin4 Login Page"

# Test pgAdmin4 ping endpoint (health check)
test_url "http://postgres.localhost/misc/ping" "pgAdmin4 Health Check"

echo
echo " Notes:"
echo "• Domain access requires: ./setup-hosts.sh"
echo "• Port forward access requires: ./setup-port-forwards.sh"
echo "• PostgreSQL direct access via Traefik TCP Ingress (no port-forward needed)"
echo "• pgAdmin4 available at: http://postgres.localhost (admin@local.com / 1q2w3e4r@123)"
echo "• PostgreSQL direct connection: psql -h 127.0.0.1 -p 5432 -U admin -d devdb"
echo "• 200, 301, 302, 307, 403, 405 response codes are considered successful"
echo "• Database services (Redis:6379) require port forwarding"
echo
echo "📖 For complete documentation see:"
echo "• README.md - Complete setup guide"
echo "• ENVIRONMENT_REFERENCE.md - All URLs and credentials"
echo "• SERVICE_ACCESS.md - Access troubleshooting"
