#!/bin/bash

# Docker Complete Cleanup Script
# This script removes all Docker containers, volumes, and networks related to the dev environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

confirm_cleanup() {
    echo ""
    log_warning "⚠️  DANGER ZONE ⚠️"
    echo "This script will:"
    echo "  • Stop and remove ALL Docker containers"
    echo "  • Remove ALL Docker volumes (including data)"
    echo "  • Remove ALL Docker networks"
    echo "  • Clean up Docker Compose resources"
    echo ""
    echo "This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

stop_docker_compose() {
    log_info "Stopping Docker Compose services..."
    
    # Try to stop with different compose files
    compose_files=(
        "docker-compose.yml"
        "docker-compose.clean.yml"
        "docker-compose.k3d.yml"
        "docker-compose.simple.yml"
    )
    
    for compose_file in "${compose_files[@]}"; do
        if [ -f "$compose_file" ]; then
            log_info "Stopping services from $compose_file"
            docker-compose -f "$compose_file" down --volumes --remove-orphans 2>/dev/null || true
        fi
    done
    
    log_success "Docker Compose services stopped"
}

remove_containers() {
    log_info "Removing all Docker containers..."
    
    # Stop all running containers
    if [ "$(docker ps -q)" ]; then
        log_info "Stopping running containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
    fi
    
    # Remove all containers
    if [ "$(docker ps -aq)" ]; then
        log_info "Removing all containers..."
        docker rm $(docker ps -aq) 2>/dev/null || true
    fi
    
    log_success "All containers removed"
}

remove_volumes() {
    log_info "Removing Docker volumes..."
    
    # Get all volumes
    volumes=$(docker volume ls -q)
    
    if [ -n "$volumes" ]; then
        log_info "Found $(echo "$volumes" | wc -l) volumes to remove"
        echo "$volumes" | while read -r volume; do
            log_info "Removing volume: $volume"
            docker volume rm "$volume" 2>/dev/null || log_warning "Failed to remove volume: $volume"
        done
    else
        log_info "No volumes found to remove"
    fi
    
    log_success "Volume cleanup completed"
}

remove_networks() {
    log_info "Removing Docker networks..."
    
    # Get all custom networks (excluding default ones)
    networks=$(docker network ls --filter "type=custom" -q)
    
    if [ -n "$networks" ]; then
        log_info "Found $(echo "$networks" | wc -l) custom networks to remove"
        echo "$networks" | while read -r network; do
            network_name=$(docker network inspect "$network" --format '{{.Name}}')
            log_info "Removing network: $network_name"
            docker network rm "$network" 2>/dev/null || log_warning "Failed to remove network: $network_name"
        done
    else
        log_info "No custom networks found to remove"
    fi
    
    log_success "Network cleanup completed"
}

clean_docker_system() {
    log_info "Performing Docker system cleanup..."
    
    # Remove unused data
    docker system prune -af --volumes 2>/dev/null || true
    
    log_success "Docker system cleanup completed"
}

cleanup_project_files() {
    log_info "Cleaning up project-specific files..."
    
    # Remove volume directories if they exist
    volume_dirs=(
        "./volumes"
        "./logs"
        "./config/k3s/kubeconfig.yaml"
    )
    
    for dir in "${volume_dirs[@]}"; do
        if [ -d "$dir" ] || [ -f "$dir" ]; then
            log_info "Removing: $dir"
            rm -rf "$dir" 2>/dev/null || log_warning "Failed to remove: $dir"
        fi
    done
    
    # Recreate necessary directories
    mkdir -p "./config/k3s"
    mkdir -p "./logs"
    
    log_success "Project files cleanup completed"
}

show_docker_status() {
    log_info "Current Docker status:"
    echo ""
    
    echo "🐳 Containers:"
    if [ "$(docker ps -aq)" ]; then
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "  No containers found"
    fi
    
    echo ""
    echo "💾 Volumes:"
    if [ "$(docker volume ls -q)" ]; then
        docker volume ls --format "table {{.Name}}\t{{.Driver}}"
    else
        echo "  No volumes found"
    fi
    
    echo ""
    echo "🌐 Networks:"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    
    echo ""
    echo "📊 System Info:"
    docker system df
}

main() {
    echo "🧹 Docker Complete Cleanup Script"
    echo "=================================="
    
    # Show current status
    show_docker_status
    
    # Confirm cleanup
    confirm_cleanup
    
    # Perform cleanup
    log_info "Starting cleanup process..."
    
    stop_docker_compose
    remove_containers
    remove_volumes
    remove_networks
    clean_docker_system
    cleanup_project_files
    
    echo ""
    log_success "🎉 Complete cleanup finished!"
    echo ""
    log_info "Your system is now clean and ready for the new Kubernetes-only setup."
    echo "You can now run: ./k3s-dev-env.sh start"
    echo ""
}

# Run main function
main "$@"
