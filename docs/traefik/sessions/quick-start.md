# Traefik Quick Start Session

## Overview
This session will help you get started with Traefik as your ingress controller and reverse proxy. You'll learn to access the Traefik dashboard, configure routing, and manage SSL certificates.

## Prerequisites
- K3s environment is running (`./k3s-dev-env.sh start`)
- Basic understanding of HTTP/HTTPS and reverse proxies
- Familiarity with DNS concepts

## Session Objectives
By the end of this session, you will:
- Access and navigate the Traefik dashboard
- Understand Traefik's routing concepts
- Configure basic ingress routes
- Set up SSL/TLS termination
- Monitor traffic and services
- Troubleshoot routing issues

## Step 1: Access Traefik Dashboard

1. **Open Traefik Dashboard**:
   ```bash
   # Traefik dashboard is available at:
   open http://traefik.k3s.local:8080
   # or directly via port:
   open http://localhost:8080
   ```

2. **Dashboard Overview**:
   - **HTTP Services**: Backend services and their health
   - **HTTP Routers**: Route definitions and rules
   - **HTTP Middlewares**: Applied transformations
   - **Entrypoints**: Listening ports and protocols

3. **Navigation Areas**:
   - **Overview**: Quick system status
   - **HTTP**: HTTP-specific routing
   - **TCP**: TCP routing (for non-HTTP services)
   - **UDP**: UDP routing

## Step 2: Understand Traefik Concepts

### Core Components

1. **Entrypoints**: Where Traefik listens
   ```yaml
   # Example entrypoints
   web:      # Port 80 (HTTP)
   websecure: # Port 443 (HTTPS)
   api:      # Port 8080 (Dashboard)
   ```

2. **Routers**: Define routing rules
   ```yaml
   # Router example
   rule: "Host(`app.k3s.local`)"
   service: "my-app-service"
   middlewares: ["auth", "compression"]
   ```

3. **Services**: Backend targets
   ```yaml
   # Service example
   loadBalancer:
     servers:
       - url: "http://app-pod:8080"
   ```

4. **Middlewares**: Request/response transformations
   ```yaml
   # Middleware examples
   - Authentication
   - Rate limiting
   - Compression
   - Headers modification
   ```

### Traefik Configuration Discovery

Traefik automatically discovers services from:
- **Kubernetes**: Ingress resources and CRDs
- **Docker**: Container labels
- **File**: Static configuration files
- **Consul/Etcd**: Service discovery backends

## Step 3: Configure Your First Route

### Using Kubernetes Ingress

1. **Create a Sample Application**:
   ```yaml
   # sample-app.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-demo
     namespace: default
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: nginx-demo
     template:
       metadata:
         labels:
           app: nginx-demo
       spec:
         containers:
         - name: nginx
           image: nginx:latest
           ports:
           - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: nginx-demo-service
     namespace: default
   spec:
     selector:
       app: nginx-demo
     ports:
     - port: 80
       targetPort: 80
   ```

2. **Create an Ingress Resource**:
   ```yaml
   # ingress.yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: nginx-demo-ingress
     namespace: default
     annotations:
       traefik.ingress.kubernetes.io/router.entrypoints: web
   spec:
     rules:
     - host: nginx-demo.k3s.local
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: nginx-demo-service
               port:
                 number: 80
   ```

3. **Apply the Configuration**:
   ```bash
   kubectl apply -f sample-app.yaml
   kubectl apply -f ingress.yaml
   ```

4. **Test the Route**:
   ```bash
   # Add to /etc/hosts
   echo "127.0.0.1 nginx-demo.k3s.local" | sudo tee -a /etc/hosts
   
   # Test the route
   curl http://nginx-demo.k3s.local
   open http://nginx-demo.k3s.local
   ```

5. **Verify in Dashboard**:
   - Check Traefik dashboard for new router
   - Verify service is healthy and responding

### Using Traefik IngressRoute (CRD)

1. **Create an IngressRoute**:
   ```yaml
   # ingressroute.yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRoute
   metadata:
     name: nginx-demo-route
     namespace: default
   spec:
     entryPoints:
       - web
     routes:
       - match: Host(`nginx-demo-v2.k3s.local`)
         kind: Rule
         services:
           - name: nginx-demo-service
             port: 80
   ```

2. **Apply and Test**:
   ```bash
   kubectl apply -f ingressroute.yaml
   
   # Add to /etc/hosts
   echo "127.0.0.1 nginx-demo-v2.k3s.local" | sudo tee -a /etc/hosts
   
   # Test
   curl http://nginx-demo-v2.k3s.local
   ```

## Step 4: SSL/TLS Configuration

### Enable HTTPS with Let's Encrypt

1. **Configure Let's Encrypt Certificate Resolver**:
   ```yaml
   # Already configured in our setup
   certificatesResolvers:
     letsencrypt:
       acme:
         email: admin@k3s.local
         storage: /data/acme.json
         httpChallenge:
           entryPoint: web
   ```

2. **Create HTTPS IngressRoute**:
   ```yaml
   # https-ingressroute.yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRoute
   metadata:
     name: nginx-demo-https
     namespace: default
   spec:
     entryPoints:
       - websecure
     routes:
       - match: Host(`nginx-demo-ssl.k3s.local`)
         kind: Rule
         services:
           - name: nginx-demo-service
             port: 80
     tls:
       certResolver: letsencrypt
   ```

3. **HTTP to HTTPS Redirect**:
   ```yaml
   # redirect-middleware.yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: redirect-to-https
     namespace: default
   spec:
     redirectScheme:
       scheme: https
       permanent: true
   ---
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRoute
   metadata:
     name: nginx-demo-redirect
     namespace: default
   spec:
     entryPoints:
       - web
     routes:
       - match: Host(`nginx-demo-ssl.k3s.local`)
         kind: Rule
         services:
           - name: nginx-demo-service
             port: 80
         middlewares:
           - name: redirect-to-https
   ```

### Self-Signed Certificates for Development

1. **Create a TLS Secret**:
   ```bash
   # Generate self-signed certificate
   openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=*.k3s.local"
   
   # Create Kubernetes secret
   kubectl create secret tls dev-tls-secret --cert=tls.crt --key=tls.key
   ```

2. **Use the Secret in IngressRoute**:
   ```yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRoute
   metadata:
     name: nginx-demo-dev-tls
     namespace: default
   spec:
     entryPoints:
       - websecure
     routes:
       - match: Host(`nginx-demo-dev.k3s.local`)
         kind: Rule
         services:
           - name: nginx-demo-service
             port: 80
     tls:
       secretName: dev-tls-secret
   ```

## Step 5: Middlewares and Advanced Routing

### Authentication Middleware

1. **Basic Authentication**:
   ```bash
   # Generate password hash
   htpasswd -nb admin secretpassword
   # Output: admin:$2y$10$...
   
   # Create secret
   kubectl create secret generic auth-secret --from-literal=users='admin:$2y$10$...'
   ```

2. **Auth Middleware**:
   ```yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: basic-auth
     namespace: default
   spec:
     basicAuth:
       secret: auth-secret
   ```

### Rate Limiting

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: default
spec:
  rateLimit:
    burst: 100
    average: 50
```

### Headers Modification

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: security-headers
  namespace: default
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-Proto: "https"
    customResponseHeaders:
      X-Frame-Options: "DENY"
      X-Content-Type-Options: "nosniff"
    sslRedirect: true
```

### Compression

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: compression
  namespace: default
spec:
  compress: {}
```

## Step 6: Load Balancing Strategies

### Weighted Round Robin

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: weighted-routing
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`app.k3s.local`)
      kind: Rule
      services:
        - name: app-v1-service
          port: 80
          weight: 80
        - name: app-v2-service
          port: 80
          weight: 20
```

### Health Checks

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: health-check-routing
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`app.k3s.local`)
      kind: Rule
      services:
        - name: app-service
          port: 80
          healthCheck:
            path: /health
            interval: 30s
            timeout: 5s
```

## Step 7: Monitoring and Observability

### Access Logs

1. **Enable Access Logs** (configured in our setup):
   ```yaml
   accessLog:
     format: json
     filePath: "/data/access.log"
   ```

2. **View Logs**:
   ```bash
   # View Traefik logs
   kubectl logs deployment/traefik -n kube-system
   
   # View access logs
   kubectl exec deployment/traefik -n kube-system -- tail -f /data/access.log
   ```

### Metrics

1. **Prometheus Metrics** (already enabled):
   ```yaml
   metrics:
     prometheus:
       addEntryPointsLabels: true
       addServicesLabels: true
   ```

2. **Query Metrics**:
   ```promql
   # Request rate
   rate(traefik_http_requests_total[5m])
   
   # Request duration
   histogram_quantile(0.95, sum(rate(traefik_http_request_duration_seconds_bucket[5m])) by (le))
   
   # Error rate
   rate(traefik_http_requests_total{code!~"2.."}[5m])
   ```

### Tracing (Optional)

```yaml
# In traefik.yml
tracing:
  jaeger:
    samplingServerURL: http://jaeger:14268/api/sampling
    localAgentHostPort: jaeger:6831
```

## Step 8: Troubleshooting Common Issues

### Route Not Working

1. **Check Router Status**:
   - Verify router appears in dashboard
   - Check if service is healthy
   - Verify entrypoint configuration

2. **Debug Commands**:
   ```bash
   # Check ingress resources
   kubectl get ingress -A
   
   # Check IngressRoute resources
   kubectl get ingressroute -A
   
   # Check services
   kubectl get svc -A
   
   # Check endpoints
   kubectl get endpoints
   ```

3. **Common Issues**:
   - DNS not resolving to Traefik
   - Service selector not matching pods
   - Wrong port configuration
   - Namespace mismatches

### SSL Certificate Issues

1. **Check Certificate Status**:
   ```bash
   # View certificates
   kubectl get certificates -A
   
   # Check certificate details
   kubectl describe certificate <cert-name>
   
   # Check ACME challenge
   kubectl get challenges -A
   ```

2. **Debug ACME**:
   ```bash
   # View Let's Encrypt logs
   kubectl logs deployment/traefik -n kube-system | grep acme
   
   # Check ACME storage
   kubectl exec deployment/traefik -n kube-system -- ls -la /data/
   ```

### Performance Issues

1. **Monitor Metrics**:
   ```promql
   # Response time
   traefik_http_request_duration_seconds
   
   # Request rate
   traefik_http_requests_total
   
   # Connection metrics
   traefik_http_requests_total - traefik_http_requests_total offset 1m
   ```

2. **Optimize Configuration**:
   - Increase worker processes
   - Tune timeout values
   - Enable compression
   - Use connection pooling

## Practice Exercises

### Exercise 1: Multi-Service Application
1. Deploy a multi-tier application (frontend, API, database)
2. Configure routing for each tier
3. Set up path-based routing (/api, /admin, /)
4. Add authentication to admin routes

### Exercise 2: Blue-Green Deployment
1. Deploy two versions of an application
2. Configure weighted routing (90% old, 10% new)
3. Gradually shift traffic to the new version
4. Monitor metrics during the transition

### Exercise 3: SSL/TLS Setup
1. Configure HTTPS for your applications
2. Set up HTTP to HTTPS redirect
3. Test certificate renewal process
4. Implement security headers

## Best Practices

### Security
- Always use HTTPS in production
- Implement proper authentication
- Use security headers middleware
- Regularly update certificates

### Performance
- Enable compression for text content
- Use appropriate timeout values
- Implement health checks
- Monitor response times

### Organization
- Use consistent naming conventions
- Organize routes by namespace/project
- Document route configurations
- Implement proper labeling

## Next Steps

1. **Advanced Routing**: Explore TCP/UDP routing
2. **Service Mesh Integration**: Connect with Istio or Linkerd
3. **API Gateway**: Use Traefik as an API gateway
4. **Multi-Cluster**: Configure cross-cluster routing
5. **Custom Plugins**: Develop custom middleware

## Additional Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Kubernetes Integration](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Let's Encrypt with Traefik](https://doc.traefik.io/traefik/https/acme/)
- [Middlewares Reference](https://doc.traefik.io/traefik/middlewares/overview/)

## Session Completion

✅ **You have completed the Traefik Quick Start session!**

You should now be able to:
- Navigate the Traefik dashboard
- Configure HTTP and HTTPS routing
- Use middlewares for authentication and optimization
- Set up SSL/TLS certificates
- Monitor traffic and troubleshoot issues
- Implement load balancing strategies

Continue with the [Advanced Routing session](./advanced-routing.md) to learn more sophisticated traffic management techniques.
