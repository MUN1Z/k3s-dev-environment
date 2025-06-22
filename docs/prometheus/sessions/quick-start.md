# Prometheus Quick Start Session

## Overview
This session will help you get started with Prometheus monitoring in your K3s environment. You'll learn to access Prometheus, understand the web interface, and create basic queries.

## Prerequisites
- K3s environment is running (`./k3s-dev-env.sh start`)
- All services are healthy
- Basic understanding of metrics and monitoring concepts

## Session Objectives
By the end of this session, you will:
- Access the Prometheus web interface
- Understand the Prometheus data model
- Write basic PromQL queries
- Explore available metrics
- Set up basic alerting rules

## Step 1: Access Prometheus

1. **Open Prometheus Web UI**:
   ```bash
   # Prometheus is available at:
   open http://prometheus.k3s.local:9090
   # or directly via port:
   open http://localhost:9090
   ```

2. **Verify Prometheus is collecting metrics**:
   - Navigate to Status > Targets
   - Confirm all targets are "UP"
   - Check for any error messages

## Step 2: Explore the Interface

### Navigation Overview
- **Graph**: Query and visualize metrics
- **Alerts**: View active alerts and rules
- **Status**: 
  - Targets: Monitored endpoints
  - Service Discovery: Auto-discovered services
  - Configuration: Current Prometheus config
  - Runtime Information: System details

### Key Concepts
- **Metrics**: Time-series data points
- **Labels**: Key-value pairs that identify metrics
- **Targets**: Endpoints that Prometheus scrapes
- **Jobs**: Groups of targets with the same purpose

## Step 3: Basic PromQL Queries

### Fundamental Query Types

1. **Instant Vector Queries** (single value at a time):
   ```promql
   # CPU usage across all nodes
   node_cpu_seconds_total
   
   # Memory usage
   node_memory_MemAvailable_bytes
   
   # Container CPU usage
   container_cpu_usage_seconds_total
   ```

2. **Range Vector Queries** (values over time):
   ```promql
   # CPU usage over last 5 minutes
   node_cpu_seconds_total[5m]
   
   # HTTP request rate over last hour
   prometheus_http_requests_total[1h]
   ```

3. **Filtering with Labels**:
   ```promql
   # CPU usage for specific mode
   node_cpu_seconds_total{mode="idle"}
   
   # Container metrics for specific pod
   container_cpu_usage_seconds_total{pod="grafana"}
   
   # Multiple label filters
   node_cpu_seconds_total{mode="idle",instance="k3s-server:9100"}
   ```

## Step 4: Useful Monitoring Queries

### System Metrics
```promql
# CPU usage percentage (non-idle)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# Disk usage percentage
100 * (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}))

# Network I/O
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Kubernetes Metrics
```promql
# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m])) by (pod)

# Pod memory usage
sum(container_memory_working_set_bytes{container!="POD",container!=""}) by (pod)

# Pod restart count
sum(increase(kube_pod_container_status_restarts_total[1h])) by (pod)

# Node resource usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (instance)
```

### Application Metrics
```promql
# HTTP request rate
sum(rate(prometheus_http_requests_total[5m])) by (handler)

# HTTP request duration
histogram_quantile(0.95, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (le))

# Error rate
sum(rate(prometheus_http_requests_total{code!~"2.."}[5m])) / sum(rate(prometheus_http_requests_total[5m]))
```

## Step 5: Creating Alerts

### Basic Alert Rules
Create a file `config/prometheus/alert-rules.yml`:

```yaml
groups:
  - name: basic-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"
      
      - alert: HighMemoryUsage
        expr: 100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% for more than 5 minutes"
      
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ $labels.pod }} is restarting frequently"
```

### Update Prometheus Configuration
Add to `config/prometheus/prometheus.yml`:

```yaml
rule_files:
  - "alert-rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

## Step 6: Practice Exercises

### Exercise 1: Resource Monitoring
1. Find the top 5 pods by CPU usage
2. Identify which node has the highest memory usage
3. Check disk space usage across all nodes

### Exercise 2: Application Monitoring
1. Monitor HTTP request rates for Grafana
2. Check response times for Prometheus itself
3. Find any error rates in the system

### Exercise 3: Alerting
1. Create an alert for low disk space (< 10%)
2. Set up an alert for pod down time
3. Configure an alert for high network traffic

## Troubleshooting

### Common Issues

1. **No data showing**:
   - Check if targets are UP in Status > Targets
   - Verify network connectivity
   - Check Prometheus logs: `kubectl logs deployment/prometheus`

2. **Query returns no results**:
   - Verify metric names with auto-completion
   - Check label filters
   - Ensure time range includes data

3. **Performance issues**:
   - Reduce query range for complex queries
   - Use recording rules for frequently used queries
   - Check resource usage of Prometheus

### Useful Commands
```bash
# Check Prometheus status
curl http://localhost:9090/-/healthy

# Reload configuration
curl -X POST http://localhost:9090/-/reload

# Check targets
curl http://localhost:9090/api/v1/targets

# Query API directly
curl 'http://localhost:9090/api/v1/query?query=up'
```

## Next Steps

1. **Learn advanced PromQL**: Functions, operators, and aggregations
2. **Set up Alertmanager**: Configure notification channels
3. **Create recording rules**: Pre-compute expensive queries
4. **Integrate with Grafana**: Build comprehensive dashboards
5. **Explore service discovery**: Auto-discover new services

## Additional Resources

- [Prometheus Query Language (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Best Practices for Monitoring](https://prometheus.io/docs/practices/naming/)
- [PromQL Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

## Session Completion

✅ **You have completed the Prometheus Quick Start session!**

You should now be able to:
- Navigate the Prometheus web interface
- Write basic PromQL queries
- Monitor system and application metrics
- Create simple alerting rules
- Troubleshoot common issues

Continue with the [Advanced Monitoring session](./advanced-monitoring.md) to learn more sophisticated monitoring techniques.
