# 🚀 Rancher Quick Start Session

## 📋 Prerequisites

- K3s development environment running
- Traefik ingress controller deployed
- Either hosts file configured OR port forwarding setup

## 🎯 Objectives

By the end of this session, you will:
- Access Rancher web interface
- Navigate the Rancher dashboard
- View your K3s cluster status
- Deploy a simple application
- Monitor application resources

## 🏁 Step-by-Step Guide

### Step 1: Access Rancher

**Option A: Domain Access (Recommended)**
```bash
# Setup hosts file (one-time setup)
./scripts/setup-hosts.sh

# Open browser to
https://rancher.localhost
```

**Option B: Port Forwarding**
```bash
# Setup port forwarding
./scripts/setup-port-forwards.sh

# Open browser to
https://localhost:8443
```

### Step 2: Login

1. **Accept Certificate Warning**
   - Click "Advanced" → "Proceed to rancher.localhost (unsafe)"
   - This is expected for development self-signed certificates

2. **Login Credentials**
   - Username: `admin`
   - Password: `admin123`

3. **Dashboard Overview**
   - You should see the local K3s cluster automatically detected
   - Cluster status should show "Active"

### Step 3: Explore the Dashboard

#### Cluster Overview
1. Click on your cluster name (usually "local")
2. Review the cluster dashboard:
   - Node status
   - Resource usage graphs
   - Workload summary
   - Event timeline

#### Navigation Menu
- **Workloads**: Deployments, pods, services
- **Service Discovery**: Services and ingress
- **Storage**: Persistent volumes and claims
- **Monitoring**: Resource metrics and alerts

### Step 4: Deploy Sample Application

#### Create Namespace
1. Navigate to **Cluster** → **Projects/Namespaces**
2. Click **Create Namespace**
3. Name: `demo-app`
4. Click **Create**

#### Deploy Nginx Application
1. Navigate to **Workloads** → **Deployments**
2. Click **Create**
3. Configure deployment:
   - **Name**: `nginx-demo`
   - **Namespace**: `demo-app`
   - **Docker Image**: `nginx:latest`
   - **Port Mapping**: Container Port `80`
4. Click **Launch**

#### Create Service
1. Navigate to **Service Discovery** → **Services**
2. Click **Create**
3. Configure service:
   - **Name**: `nginx-demo-service`
   - **Namespace**: `demo-app`
   - **Target Workload**: `nginx-demo`
   - **Port Mapping**: Port `80` → Target Port `80`
4. Click **Save**

### Step 5: Monitor Application

#### View Workload Status
1. Navigate to **Workloads** → **Pods**
2. Filter by namespace: `demo-app`
3. Observe pod status (should be "Running")
4. Click on pod name to view details:
   - Container logs
   - Resource usage
   - Events

#### Check Resource Usage
1. In the pod details, check the **Metrics** tab
2. View CPU and memory usage graphs
3. Navigate back to cluster dashboard
4. Observe how the new workload affects cluster metrics

### Step 6: Access Application

#### Create Ingress (Optional)
1. Navigate to **Service Discovery** → **Ingresses**
2. Click **Create**
3. Configure ingress:
   - **Name**: `nginx-demo-ingress`
   - **Namespace**: `demo-app`
   - **Rules**: Host `nginx-demo.localhost` → Service `nginx-demo-service:80`
4. Add to hosts file: `127.0.0.1 nginx-demo.localhost`
5. Access: `http://nginx-demo.localhost`

#### Port Forward (Alternative)
```bash
# Port forward to access application
kubectl port-forward -n demo-app service/nginx-demo-service 8080:80

# Access application
curl http://localhost:8080
```

### Step 7: Cleanup

#### Remove Demo Application
1. Navigate to **Workloads** → **Deployments**
2. Select `nginx-demo` deployment
3. Click **Delete**
4. Navigate to **Service Discovery** → **Services**
5. Delete `nginx-demo-service`
6. Navigate to **Cluster** → **Projects/Namespaces**
7. Delete `demo-app` namespace

## 🎉 Success Criteria

You have successfully completed this session if you can:
- ✅ Access Rancher at https://rancher.localhost
- ✅ Login with admin credentials
- ✅ View cluster status and resources
- ✅ Deploy and access a simple application
- ✅ Monitor application metrics
- ✅ Clean up deployed resources

## 🔗 Next Steps

- **Advanced Monitoring**: [Grafana Integration](../../grafana/sessions/quick-start.md)
- **Application Deployment**: [GitOps with ArgoCD](../../argocd/sessions/quick-start.md)
- **Load Balancing**: [Traefik Configuration](../../traefik/sessions/quick-start.md)

## 📚 Additional Resources

- [Rancher Official Documentation](https://rancher.com/docs/)
- [Kubernetes Workloads](https://kubernetes.io/docs/concepts/workloads/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

## 🆘 Troubleshooting

**Cannot access Rancher UI:**
```bash
# Check Rancher pod status
kubectl get pods -n cattle-system -l app=rancher

# Check ingress configuration
kubectl get ingressroute,ingressroutetcp -n cattle-system

# View logs
kubectl logs -n cattle-system deployment/rancher
```

**Certificate warnings:**
- Expected behavior with self-signed certificates
- Safe to proceed in development environment
- Use port forwarding as alternative access method

**Application not accessible:**
```bash
# Check pod status
kubectl get pods -n demo-app

# Check service endpoints
kubectl get endpoints -n demo-app

# Test service connectivity
kubectl port-forward -n demo-app service/nginx-demo-service 8080:80
curl http://localhost:8080
```
