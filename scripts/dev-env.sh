#!/bin/bash

# Development Environment Manager
# Simplified Docker-based development stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.clean.yml"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "  Development Environment Manager"
    echo "  Simplified Docker-based development stack"
    echo "=================================================================="
    echo -e "${NC}"
}

start_environment() {
    log_info "Starting development environment..."
    
    # Generate required configuration files
    generate_configs
    
    # Start all services
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait a moment for services to be ready
    sleep 5
    
    log_success "Development environment started!"
    display_access_info
}

stop_environment() {
    log_info "Stopping development environment..."
    docker-compose -f "$COMPOSE_FILE" down
    log_success "Development environment stopped!"
}

restart_environment() {
    log_info "Restarting development environment..."
    stop_environment
    sleep 2
    start_environment
}

show_status() {
    log_info "Development environment status:"
    docker-compose -f "$COMPOSE_FILE" ps
}

show_logs() {
    local service="$1"
    if [[ -n "$service" ]]; then
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

cleanup_environment() {
    log_warning "Cleaning up development environment (removing containers and volumes)..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    docker system prune -f
    log_success "Cleanup complete!"
}

generate_configs() {
    log_info "Generating configuration files..."
    
    # Create config directories
    mkdir -p "$SCRIPT_DIR/config/prometheus"
    mkdir -p "$SCRIPT_DIR/config/grafana/datasources"
    
    # Generate Prometheus config
    cat > "$SCRIPT_DIR/config/prometheus/prometheus.yml" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker-containers'
    static_configs:
      - targets: ['traefik:8080', 'grafana:3000', 'postgres:5432', 'redis:6379', 'minio:9000']
    scrape_interval: 30s
EOF

    # Generate Grafana datasource config
    cat > "$SCRIPT_DIR/config/grafana/datasources/prometheus.yml" <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    log_success "Configuration files generated!"
}

setup_hosts() {
    log_info "Setting up /etc/hosts entries..."
    
    # Check if entries already exist
    if grep -q "traefik.localhost" /etc/hosts; then
        log_warning "/etc/hosts entries already exist"
        return
    fi
    
    # Add entries to /etc/hosts
    cat <<EOF | sudo tee -a /etc/hosts
# Development Environment Services
127.0.0.1 traefik.localhost
127.0.0.1 prometheus.localhost  
127.0.0.1 grafana.localhost
127.0.0.1 jaeger.localhost
127.0.0.1 minio.localhost
127.0.0.1 minio-api.localhost
EOF
    
    log_success "/etc/hosts configured"
}

display_access_info() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "  Development Environment - Ready!"
    echo "=================================================================="
    echo -e "${NC}"
    
    echo "Docker Services:"
    echo "================"
    echo "• Traefik Dashboard: http://traefik.localhost or http://localhost:8080"
    echo "• Rancher UI:        http://rancher.localhost or http://localhost:8888"
    echo ""
    
    echo "K3s Services (via Rancher):"
    echo "==========================="
    echo "• Grafana:           http://grafana.localhost (admin/1q2w3e4r@123)"
    echo "• Prometheus:        http://prometheus.localhost"
    echo "• Jaeger Tracing:    http://jaeger.localhost"
    echo "• MinIO Console:     http://minio.localhost (minioadmin/minioadmin123)"
    echo "• MinIO API:         http://minio-api.localhost"
    echo ""
    echo "Database Connections (K3s):"
    echo "==========================="
    echo "• PostgreSQL:        kubectl port-forward svc/postgres 5432:5432 -n development"
    echo "• Redis:             kubectl port-forward svc/redis 6379:6379 -n development"
    echo ""
    echo "Available Commands:"
    echo "=================="
    echo "  ./dev-env.sh start       - Start the environment"
    echo "  ./dev-env.sh stop        - Stop the environment"
    echo "  ./dev-env.sh restart     - Restart the environment"
    echo "  ./dev-env.sh status      - Show status"
    echo "  ./dev-env.sh logs        - Show logs (add service name for specific service)"
    echo "  ./dev-env.sh cleanup     - Remove all containers and volumes"
    echo "  ./dev-env.sh setup-hosts - Configure /etc/hosts"
    echo "  ./dev-env.sh deploy-k8s  - Deploy services to K3s cluster"
    echo "  ./dev-env.sh kubeconfig  - Get kubeconfig for kubectl"
}

deploy_to_k8s() {
    log_info "Deploying services to K3s cluster..."
    
    # Wait for K3s to be ready
    log_info "Waiting for K3s to be ready..."
    sleep 30
    
    # Check if kubeconfig exists
    if [[ ! -f "$SCRIPT_DIR/config/k3s/kubeconfig.yaml" ]]; then
        log_error "Kubeconfig not found. Make sure K3s is running."
        return 1
    fi
    
    export KUBECONFIG="$SCRIPT_DIR/config/k3s/kubeconfig.yaml"
    
    # Deploy all manifests
    log_info "Deploying Kubernetes manifests..."
    kubectl apply -f "$SCRIPT_DIR/k8s-manifests/"
    
    log_info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment --all -n development
    
    log_success "Services deployed to K3s cluster!"
    
    echo ""
    echo "Access your services via:"
    echo "• Grafana: http://grafana.localhost"
    echo "• Prometheus: http://prometheus.localhost"
    echo "• Jaeger: http://jaeger.localhost"
    echo "• MinIO: http://minio.localhost"
}

get_kubeconfig() {
    log_info "Kubeconfig location: $SCRIPT_DIR/config/k3s/kubeconfig.yaml"
    
    if [[ -f "$SCRIPT_DIR/config/k3s/kubeconfig.yaml" ]]; then
        echo ""
        echo "To use kubectl, run:"
        echo "export KUBECONFIG=$SCRIPT_DIR/config/k3s/kubeconfig.yaml"
        echo ""
        echo "Or copy the kubeconfig to your default location:"
        echo "cp $SCRIPT_DIR/config/k3s/kubeconfig.yaml ~/.kube/config"
    else
        log_error "Kubeconfig not found. Make sure K3s is running."
    fi
}

# Main script logic
case "${1:-}" in
    start)
        print_banner
        start_environment
        ;;
    stop)
        print_banner
        stop_environment
        ;;
    restart)
        print_banner
        restart_environment
        ;;
    status)
        print_banner
        show_status
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    cleanup)
        print_banner
        cleanup_environment
        ;;
    setup-hosts)
        print_banner
        setup_hosts
        ;;
    deploy-k8s)
        print_banner
        deploy_to_k8s
        ;;
    kubeconfig)
        print_banner
        get_kubeconfig
        ;;
    *)
        print_banner
        echo "Usage: $0 {start|stop|restart|status|logs [service]|cleanup|setup-hosts|deploy-k8s|kubeconfig}"
        echo ""
        display_access_info
        exit 1
        ;;
esac
