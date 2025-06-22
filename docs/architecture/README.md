# System Architecture

This document describes the architecture and design principles of the K3s Development Environment.

## 🏗️ Overview

The K3s Development Environment is designed as a multi-layered, containerized infrastructure that provides a complete Kubernetes development experience with integrated management, monitoring, and networking capabilities.

## 🔧 Architecture Principles

### Design Goals

1. **Simplicity**: One-command deployment and management
2. **Reliability**: Stable networking with fixed IPs
3. **Observability**: Comprehensive monitoring and logging
4. **Scalability**: Easy to extend with additional services
5. **Security**: Isolated networks and secure defaults

### Core Principles

- **Infrastructure as Code**: Everything defined in version control
- **Immutable Infrastructure**: Containers can be replaced without data loss
- **Service Mesh Ready**: Designed for easy service mesh integration
- **Cloud Native**: Follows CNCF best practices

## 🏢 System Architecture

```mermaid
graph TB
    subgraph "Host System"
        subgraph "Docker Engine"
            subgraph "K3s Development Environment Network - 172.30.0.0/16"
                subgraph "Control Plane - 172.30.10.0/24"
                    K3S_SERVER[K3s Server<br/>172.30.10.10<br/>Kubernetes API<br/>etcd<br/>Controller Manager<br/>Scheduler]
                end
                
                subgraph "Worker Nodes - 172.30.10.0/24"
                    K3S_AGENT1[K3s Agent 1<br/>172.30.10.11<br/>Zone: zone-a<br/>kubelet<br/>kube-proxy]
                    K3S_AGENT2[K3s Agent 2<br/>172.30.10.12<br/>Zone: zone-b<br/>kubelet<br/>kube-proxy]
                end
                
                subgraph "Infrastructure Services - 172.30.20.0/24"
                    TRAEFIK[Traefik v3.2.1<br/>172.30.20.10<br/>Ingress Controller<br/>Load Balancer<br/>SSL Termination]
                    RANCHER[Rancher v2.9.3<br/>172.30.20.20<br/>Cluster Management<br/>Web UI<br/>RBAC]
                end
                
                subgraph "Monitoring Stack - 172.30.30.0/24"
                    PROMETHEUS[Prometheus v2.56.1<br/>172.30.30.10<br/>Metrics Collection<br/>Alerting Rules<br/>Service Discovery]
                    GRAFANA[Grafana v11.4.0<br/>172.30.30.20<br/>Dashboards<br/>Visualization<br/>Analytics]
                end
                
                subgraph "Logging Stack - 172.30.40.0/24"
                    OPENSEARCH[OpenSearch v2.18.0<br/>172.30.40.10<br/>Search Engine<br/>Log Storage<br/>Index Management]
                    OPENSEARCH_DASH[OpenSearch Dashboard<br/>172.30.40.20<br/>Log Visualization<br/>Queries<br/>Analytics]
                end
                
                subgraph "Load Balancer Pool - 172.30.255.0/24"
                    METALLB_POOL[MetalLB IP Pool<br/>172.30.255.10-100<br/>Layer 2 Advertisement<br/>Service Load Balancing]
                end
            end
        end
        
        subgraph "Host Network Interface"
            HOST_PORTS[Host Ports<br/>80, 443, 6443<br/>8080, 8443<br/>3000, 9090<br/>9200, 5601]
        end
    end
    
    subgraph "External Access"
        BROWSER[Web Browser]
        KUBECTL[kubectl CLI]
        API_CLIENTS[API Clients]
    end
    
    %% Connections
    BROWSER --> HOST_PORTS
    KUBECTL --> HOST_PORTS
    API_CLIENTS --> HOST_PORTS
    
    HOST_PORTS --> TRAEFIK
    HOST_PORTS --> RANCHER
    HOST_PORTS --> GRAFANA
    HOST_PORTS --> PROMETHEUS
    HOST_PORTS --> OPENSEARCH
    HOST_PORTS --> OPENSEARCH_DASH
    
    TRAEFIK --> K3S_SERVER
    TRAEFIK --> K3S_AGENT1
    TRAEFIK --> K3S_AGENT2
    
    RANCHER --> K3S_SERVER
    
    PROMETHEUS --> K3S_SERVER
    PROMETHEUS --> K3S_AGENT1
    PROMETHEUS --> K3S_AGENT2
    PROMETHEUS --> TRAEFIK
    PROMETHEUS --> RANCHER
    
    GRAFANA --> PROMETHEUS
    OPENSEARCH_DASH --> OPENSEARCH
    
    K3S_SERVER --> K3S_AGENT1
    K3S_SERVER --> K3S_AGENT2
    
    METALLB_POOL --> K3S_SERVER
    METALLB_POOL --> K3S_AGENT1
    METALLB_POOL --> K3S_AGENT2
```

## 🌐 Network Architecture

### Network Segmentation

The environment uses a single Docker bridge network (`172.30.0.0/16`) with logical subnets:

| Subnet | Purpose | Components |
|--------|---------|------------|
| `172.30.10.0/24` | Kubernetes Cluster | K3s server and agents |
| `172.30.20.0/24` | Infrastructure Services | Traefik, Rancher |
| `172.30.30.0/24` | Monitoring | Prometheus, Grafana |
| `172.30.40.0/24` | Logging | OpenSearch, Dashboard |
| `172.30.255.0/24` | Load Balancer Pool | MetalLB IP allocation |

### Network Flow

```mermaid
sequenceDiagram
    participant Client
    participant Traefik
    participant MetalLB
    participant K3s
    participant Service
    
    Client->>Traefik: HTTP/HTTPS Request
    Traefik->>MetalLB: Route to LoadBalancer
    MetalLB->>K3s: Forward to Service
    K3s->>Service: Deliver to Pod
    Service->>K3s: Response
    K3s->>MetalLB: Response
    MetalLB->>Traefik: Response
    Traefik->>Client: HTTP/HTTPS Response
```

### DNS Resolution

Local DNS resolution is handled through `/etc/hosts` entries:

```
127.0.0.1 rancher.dev
127.0.0.1 traefik.dev
127.0.0.1 grafana.dev
127.0.0.1 prometheus.dev
127.0.0.1 opensearch.dev
127.0.0.1 opensearch-dashboard.dev
```

## 🔧 Component Architecture

### K3s Cluster

```mermaid
graph LR
    subgraph "K3s Server - 172.30.10.10"
        API[Kubernetes API]
        ETCD[etcd]
        SCHED[Scheduler]
        CTRL[Controller Manager]
        KUBELET1[kubelet]
        PROXY1[kube-proxy]
    end
    
    subgraph "K3s Agent 1 - 172.30.10.11"
        KUBELET2[kubelet]
        PROXY2[kube-proxy]
        CONTAINERD2[containerd]
    end
    
    subgraph "K3s Agent 2 - 172.30.10.12"
        KUBELET3[kubelet]
        PROXY3[kube-proxy]
        CONTAINERD3[containerd]
    end
    
    API --> KUBELET2
    API --> KUBELET3
    ETCD --> API
    SCHED --> API
    CTRL --> API
```

### Traefik Ingress

```mermaid
graph TB
    subgraph "Traefik - 172.30.20.10"
        ENTRYPOINT[Entry Points<br/>:80, :443, :8080]
        ROUTER[Routers<br/>Path/Host based routing]
        MIDDLEWARE[Middleware<br/>Auth, CORS, Rate Limiting]
        SERVICE[Services<br/>Load Balancing]
        PROVIDER[Providers<br/>Docker, Kubernetes]
    end
    
    ENTRYPOINT --> ROUTER
    ROUTER --> MIDDLEWARE
    MIDDLEWARE --> SERVICE
    PROVIDER --> ROUTER
    SERVICE --> K3S_CLUSTER[K3s Cluster Services]
```

### Monitoring Stack

```mermaid
graph TB
    subgraph "Monitoring Architecture"
        subgraph "Data Collection"
            PROM_SERVER[Prometheus Server<br/>172.30.30.10]
            EXPORTERS[Node Exporters<br/>cAdvisor<br/>Custom Metrics]
        end
        
        subgraph "Visualization"
            GRAFANA_SERVER[Grafana Server<br/>172.30.30.20]
            DASHBOARDS[Dashboards<br/>Kubernetes<br/>Infrastructure<br/>Applications]
        end
        
        subgraph "Alerting"
            ALERT_MANAGER[Alert Manager<br/>Future Enhancement]
            NOTIFICATIONS[Notifications<br/>Email, Slack, etc.]
        end
    end
    
    EXPORTERS --> PROM_SERVER
    PROM_SERVER --> GRAFANA_SERVER
    GRAFANA_SERVER --> DASHBOARDS
    PROM_SERVER --> ALERT_MANAGER
    ALERT_MANAGER --> NOTIFICATIONS
```

## 💾 Data Architecture

### Persistent Storage

```mermaid
graph TB
    subgraph "Host File System"
        subgraph "volumes/"
            K3S_DATA[k3s-server/<br/>k3s-agent-1/<br/>k3s-agent-2/]
            KUBECONFIG[kubeconfig/]
            MONITORING_DATA[prometheus/<br/>grafana/]
            LOGGING_DATA[opensearch/]
            INFRA_DATA[rancher/<br/>traefik/]
        end
        
        subgraph "config/"
            CONFIGS[Service Configurations<br/>Static Files<br/>Templates]
        end
        
        subgraph "logs/"
            LOG_FILES[Service Logs<br/>Audit Logs<br/>Debug Output]
        end
    end
    
    subgraph "Container Volumes"
        BIND_MOUNTS[Bind Mounts<br/>Persistent Data]
        TMPFS[tmpfs<br/>Temporary Data]
    end
    
    K3S_DATA --> BIND_MOUNTS
    MONITORING_DATA --> BIND_MOUNTS
    LOGGING_DATA --> BIND_MOUNTS
    INFRA_DATA --> BIND_MOUNTS
    CONFIGS --> BIND_MOUNTS
```

### Data Flow

```mermaid
graph LR
    subgraph "Data Sources"
        APPS[Applications]
        K8S[Kubernetes]
        INFRA[Infrastructure]
    end
    
    subgraph "Collection"
        PROM[Prometheus<br/>Metrics]
        LOGS[Container Logs<br/>Application Logs]
    end
    
    subgraph "Storage"
        PROM_STORAGE[Prometheus TSDB]
        OPENSEARCH_STORAGE[OpenSearch Indices]
    end
    
    subgraph "Visualization"
        GRAFANA_DASH[Grafana Dashboards]
        OPENSEARCH_DASH[OpenSearch Dashboards]
    end
    
    APPS --> PROM
    K8S --> PROM
    INFRA --> PROM
    
    APPS --> LOGS
    K8S --> LOGS
    INFRA --> LOGS
    
    PROM --> PROM_STORAGE
    LOGS --> OPENSEARCH_STORAGE
    
    PROM_STORAGE --> GRAFANA_DASH
    OPENSEARCH_STORAGE --> OPENSEARCH_DASH
```

## 🔒 Security Architecture

### Network Security

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Network Isolation"
            DOCKER_NET[Docker Bridge Network<br/>172.30.0.0/16]
            SUBNETS[Logical Subnets<br/>Service Segregation]
        end
        
        subgraph "Access Control"
            RBAC[Kubernetes RBAC<br/>Role-based Access]
            AUTH[Service Authentication<br/>Basic Auth, TLS]
        end
        
        subgraph "Data Protection"
            TLS[TLS Termination<br/>at Traefik]
            SECRETS[Kubernetes Secrets<br/>Environment Variables]
        end
        
        subgraph "Monitoring"
            AUDIT[Audit Logging<br/>Access Monitoring]
            ALERTS[Security Alerts<br/>Anomaly Detection]
        end
    end
    
    DOCKER_NET --> SUBNETS
    SUBNETS --> RBAC
    RBAC --> AUTH
    AUTH --> TLS
    TLS --> SECRETS
    SECRETS --> AUDIT
    AUDIT --> ALERTS
```

### Security Boundaries

1. **Host Isolation**: Containers isolated from host system
2. **Network Isolation**: Dedicated Docker network
3. **Service Isolation**: Fixed IP addressing and port allocation
4. **Data Isolation**: Separate volumes for each service
5. **Access Control**: Authentication required for management interfaces

## 🔄 Deployment Architecture

### Deployment Process

```mermaid
graph TB
    subgraph "Deployment Flow"
        START[Start Command] --> DEPS[Check Dependencies]
        DEPS --> ENV[Setup Environment]
        ENV --> DIRS[Create Directories]
        DIRS --> HOSTS[Configure Hosts]
        HOSTS --> CLUSTER[Start K3s Cluster]
        CLUSTER --> WAIT[Wait for Ready]
        WAIT --> METALLB[Install MetalLB]
        METALLB --> TRAEFIK[Install Traefik]
        TRAEFIK --> VERIFY[Verify Services]
        VERIFY --> COMPLETE[Deployment Complete]
    end
    
    subgraph "Health Checks"
        HEALTH[Health Monitoring]
        STATUS[Status Checks]
        LOGS[Log Monitoring]
    end
    
    COMPLETE --> HEALTH
    HEALTH --> STATUS
    STATUS --> LOGS
```

### Service Dependencies

```mermaid
graph TB
    subgraph "Dependency Graph"
        DOCKER[Docker Engine] --> K3S_SERVER[K3s Server]
        K3S_SERVER --> K3S_AGENTS[K3s Agents]
        K3S_SERVER --> METALLB[MetalLB]
        METALLB --> TRAEFIK[Traefik]
        K3S_SERVER --> RANCHER[Rancher]
        K3S_AGENTS --> PROMETHEUS[Prometheus]
        PROMETHEUS --> GRAFANA[Grafana]
        K3S_AGENTS --> OPENSEARCH[OpenSearch]
        OPENSEARCH --> OPENSEARCH_DASH[OpenSearch Dashboard]
    end
```

## 📊 Performance Characteristics

### Resource Requirements

| Component | CPU | Memory | Storage | Network |
|-----------|-----|--------|---------|---------|
| K3s Server | 1-2 cores | 2-4 GB | 10 GB | 1 Gbps |
| K3s Agent | 0.5-1 core | 1-2 GB | 5 GB | 1 Gbps |
| Rancher | 0.5-1 core | 1-2 GB | 2 GB | 100 Mbps |
| Traefik | 0.25-0.5 core | 256-512 MB | 1 GB | 1 Gbps |
| Prometheus | 0.5-1 core | 1-2 GB | 10 GB | 100 Mbps |
| Grafana | 0.25-0.5 core | 256-512 MB | 2 GB | 100 Mbps |
| OpenSearch | 1-2 cores | 2-4 GB | 20 GB | 100 Mbps |

### Scaling Characteristics

- **Horizontal Scaling**: Add more K3s agent nodes
- **Vertical Scaling**: Increase container resource limits
- **Storage Scaling**: Expand persistent volumes
- **Network Scaling**: Multiple load balancer IPs

## 🔧 Configuration Management

### Configuration Sources

```mermaid
graph TB
    subgraph "Configuration Management"
        ENV_FILE[.env File<br/>Environment Variables]
        K8S_MANIFESTS[k8s-manifests/<br/>Kubernetes Definitions]
        K8S_MANIFESTS[k8s-manifests/<br/>Kubernetes Resources]
        CONFIGS[config/<br/>Service Configurations]
        MONITORING[monitoring/<br/>Monitoring Configs]
    end
    
    subgraph "Runtime Configuration"
        CONTAINERS[Container Environment]
        VOLUMES[Mounted Volumes]
        NETWORKS[Network Settings]
        SECRETS[Runtime Secrets]
    end
    
    ENV_FILE --> CONTAINERS
    COMPOSE --> CONTAINERS
    K8S_MANIFESTS --> VOLUMES
    CONFIGS --> VOLUMES
    MONITORING --> VOLUMES
    
    CONTAINERS --> NETWORKS
    VOLUMES --> SECRETS
```

This architecture provides a solid foundation for Kubernetes development with enterprise-grade monitoring, management, and networking capabilities.
