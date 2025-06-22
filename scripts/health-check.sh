#!/bin/bash

# Health Check Script for Development Environment

echo "🔍 Development Environment Health Check"
echo "================================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="$3"
    
    echo -n "Testing $service_name... "
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

echo ""
echo "🌐 Web Services:"
check_service "Traefik Dashboard" "http://localhost:8080" "200"
check_service "Prometheus" "http://localhost:9090" "200"
check_service "Grafana" "http://localhost:3000" "200"
check_service "Jaeger" "http://localhost:16686" "200"
check_service "MinIO Console" "http://localhost:9001" "200"
check_service "Rancher (HTTP→HTTPS)" "http://localhost:8888" "302"

echo ""
echo "💾 Database Services:"
if nc -z localhost 5432 2>/dev/null; then
    echo -e "PostgreSQL... ${GREEN}✓ OK${NC}"
else
    echo -e "PostgreSQL... ${RED}✗ FAILED${NC}"
fi

if nc -z localhost 6379 2>/dev/null; then
    echo -e "Redis... ${GREEN}✓ OK${NC}"
else
    echo -e "Redis... ${RED}✗ FAILED${NC}"
fi

echo ""
echo "🐳 Container Status:"
kubectl get pods --all-namespaces -o wide

echo ""
echo "📊 System Resources:"
echo "Memory Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null

echo ""
echo -e "${GREEN}✅ Health check complete!${NC}"
echo ""
echo "🔗 Quick Access Links:"
echo "• Traefik: http://localhost:8080"
echo "• Rancher: http://localhost:8888 (redirects to HTTPS)"
echo "• Grafana: http://localhost:3000 (admin/admin123)"
echo "• Prometheus: http://localhost:9090"
echo "• Jaeger: http://localhost:16686"
echo "• MinIO: http://localhost:9001 (minioadmin/minioadmin123)"
