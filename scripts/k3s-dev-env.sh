#!/bin/bash

# K3s Dev Environment - Kubernetes-only Setup
# This script sets up a complete development environment using only Kubernetes (K3s)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
K3S_VERSION="latest"
KUBECONFIG_PATH="./config/k3s/kubeconfig.yaml"
CLUSTER_NAME="k3s-dev"

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

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if k3d is installed
    if ! command -v k3d &> /dev/null; then
        log_error "k3d is not installed. Please install it first:"
        echo "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it first"
        exit 1
    fi
    
    # Check if docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first"
        exit 1
    fi
    
    log_success "All dependencies are available"
}

cleanup_docker_compose() {
    log_info "Cleaning up existing Docker Compose containers and volumes..."
    
    # Stop and remove any existing containers
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.clean.yml" ]; then
        docker-compose -f docker-compose.clean.yml down --volumes --remove-orphans 2>/dev/null || true
        docker-compose down --volumes --remove-orphans 2>/dev/null || true
    fi
    
    # Remove specific volumes if they exist
    volumes=(
        "k3s-dev-environment_postgres_data"
        "k3s-dev-environment_redis_data"
        "k3s-dev-environment_prometheus_data"
        "k3s-dev-environment_grafana_data"
        "k3s-dev-environment_minio_data"
        "k3s-dev-environment_jaeger_data"
        "k3s-dev-environment_rancher_data"
        "k3s-dev-environment_traefik_data"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume ls -q | grep -q "$volume"; then
            log_info "Removing Docker volume: $volume"
            docker volume rm "$volume" 2>/dev/null || true
        fi
    done
    
    log_success "Docker cleanup completed"
}

create_k3s_cluster() {
    log_info "Creating K3s cluster..."
    
    # Create config directory
    mkdir -p "$(dirname "$KUBECONFIG_PATH")"
    
    # Remove existing cluster if it exists
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warning "Existing cluster found. Removing..."
        k3d cluster delete "$CLUSTER_NAME"
    fi
    
    # Create new cluster with specific configuration
    k3d cluster create "$CLUSTER_NAME" \
        --image "rancher/k3s:$K3S_VERSION" \
        --port "80:80@loadbalancer" \
        --port "443:443@loadbalancer" \
        --port "8080:8080@loadbalancer" \
        --port "9090:9090@loadbalancer" \
        --port "3000:3000@loadbalancer" \
        --port "16686:16686@loadbalancer" \
        --port "9001:9001@loadbalancer" \
        --port "9000:9000@loadbalancer" \
        --k3s-arg "--disable=traefik@server:0" \
        --k3s-arg "--disable=servicelb@server:0" \
        --registry-create "$CLUSTER_NAME-registry:0.0.0.0:5555" \
        --agents 2
    
    # Export kubeconfig
    k3d kubeconfig get "$CLUSTER_NAME" > "$KUBECONFIG_PATH"
    export KUBECONFIG="$KUBECONFIG_PATH"
    
    log_success "K3s cluster created successfully"
}

wait_for_cluster() {
    log_info "Waiting for cluster to be ready..."
    
    # Wait for nodes to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log_success "Cluster is ready"
}

deploy_traefik() {
    log_info "Installing Traefik CRDs..."
    kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
    
    log_info "Waiting for CRDs to be ready..."
    sleep 5
    
    log_info "Deploying Traefik ingress controller..."
    kubectl apply -f k8s-manifests/traefik.yaml
    
    # Wait for Traefik to be ready
    kubectl wait --for=condition=available deployment/traefik -n traefik-system --timeout=300s
    
    log_success "Traefik deployed successfully"
}

deploy_applications() {
    log_info "Deploying applications..."
    
    # Create development namespace
    kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy all services
    services=(
        "postgres.yaml"
        "redis.yaml"
        "prometheus.yaml"
        "grafana.yaml"
        "jaeger.yaml"
        "minio.yaml"
    )
    
    for service in "${services[@]}"; do
        log_info "Deploying $service..."
        kubectl apply -f "k8s-manifests/$service"
    done
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=available deployment --all -n development --timeout=600s
    
    log_success "Applications deployed successfully"
}

deploy_rancher() {
    log_info "Deploying Rancher..."
    
    kubectl apply -f k8s-manifests/rancher.yaml
    
    # Wait for Rancher to be ready
    kubectl wait --for=condition=available deployment/rancher -n cattle-system --timeout=600s
    
    log_success "Rancher deployed successfully"
}

deploy_argocd() {
    log_info "Deploying ArgoCD..."
    
    kubectl apply -f k8s-manifests/argocd.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available deployment --all -n argocd --timeout=600s
    
    log_success "ArgoCD deployed successfully"
}

deploy_ingress() {
    log_info "Deploying ingress routes..."
    
    kubectl apply -f k8s-manifests/ingress.yaml
    
    log_success "Ingress routes deployed successfully"
}

display_access_info() {
    log_success "🚀 K3s Development Environment is ready!"
    echo ""
    echo "📋 Service Access URLs:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Rancher:           http://rancher.localhost         (User: admin, Password: admin123)"
    echo "📊 Grafana:           http://grafana.localhost         (User: admin, Password: admin)"
    echo "📈 Prometheus:        http://prometheus.localhost      (Metrics & monitoring)"
    echo "🔍 Jaeger:            http://jaeger.localhost          (Distributed tracing)"
    echo "💾 MinIO Console:     http://minio.localhost           (User: minioadmin, Password: minioadmin)"
    echo "💾 MinIO API:         http://minio-api.localhost       (S3-compatible storage API)"
    echo "🔀 Traefik:           http://traefik.localhost         (Load balancer dashboard)"
    echo ""
    echo "🐧 Kubernetes Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📂 Kubeconfig:        $KUBECONFIG_PATH"
    echo "🎯 Cluster:           $CLUSTER_NAME"
    echo "📦 Namespaces:        development, cattle-system, traefik-system"
    echo ""
    echo "⚙️ Useful Commands:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Export kubeconfig:    export KUBECONFIG=$KUBECONFIG_PATH"
    echo "View pods:            kubectl get pods --all-namespaces"
    echo "View services:        kubectl get services --all-namespaces"
    echo "View ingress:         kubectl get ingressroutes --all-namespaces"
    echo "Delete cluster:       k3d cluster delete $CLUSTER_NAME"
    echo ""
}

show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the K3s development environment"
    echo "  stop        Stop and remove the K3s cluster"
    echo "  restart     Stop and start the environment"
    echo "  status      Show cluster and services status"
    echo "  cleanup     Remove Docker containers and volumes"
    echo "  logs        Show logs for all services"
    echo "  help        Show this help message"
    echo ""
}

start_environment() {
    log_info "Starting K3s Development Environment..."
    
    check_dependencies
    cleanup_docker_compose
    create_k3s_cluster
    wait_for_cluster
    deploy_traefik
    deploy_applications
    deploy_rancher
    deploy_argocd
    deploy_ingress
    
    display_access_info
}

stop_environment() {
    log_info "Stopping K3s Development Environment..."
    
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        k3d cluster delete "$CLUSTER_NAME"
        log_success "K3s cluster stopped and removed"
    else
        log_warning "No cluster found to stop"
    fi
}

show_status() {
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warning "Cluster is not running"
        return 1
    fi
    
    log_info "Cluster Status:"
    kubectl get nodes -o wide
    
    echo ""
    log_info "Services Status:"
    kubectl get pods --all-namespaces -o wide
    
    echo ""
    log_info "Ingress Routes:"
    kubectl get ingressroutes --all-namespaces
}

show_logs() {
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_error "Cluster is not running"
        return 1
    fi
    
    namespaces=("development" "cattle-system" "traefik-system")
    
    for namespace in "${namespaces[@]}"; do
        echo ""
        log_info "Logs for namespace: $namespace"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        pods=$(kubectl get pods -n "$namespace" -o name 2>/dev/null || true)
        if [ -n "$pods" ]; then
            echo "$pods" | while read -r pod; do
                echo ""
                echo "📋 Logs for $pod:"
                kubectl logs "$pod" -n "$namespace" --tail=10 2>/dev/null || echo "No logs available"
            done
        else
            echo "No pods found in namespace $namespace"
        fi
    done
}

# Main script logic
case "${1:-start}" in
    start)
        start_environment
        ;;
    stop)
        stop_environment
        ;;
    restart)
        stop_environment
        sleep 5
        start_environment
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup_docker_compose
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
