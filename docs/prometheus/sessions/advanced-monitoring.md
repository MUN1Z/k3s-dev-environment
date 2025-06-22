# Advanced Prometheus Monitoring Session

## Overview
This advanced session covers sophisticated monitoring techniques, custom metrics, recording rules, and advanced PromQL for experienced users.

## Prerequisites
- Completed the [Quick Start session](./quick-start.md)
- Familiarity with PromQL basics
- Understanding of Kubernetes concepts
- Experience with monitoring concepts

## Session Objectives
By the end of this session, you will:
- Create custom metrics and exporters
- Use advanced PromQL functions and operators
- Implement recording rules for performance
- Set up complex alerting scenarios
- Monitor application-specific metrics
- Implement SLI/SLO monitoring

## Advanced PromQL Techniques

### Complex Aggregations
```promql
# CPU usage by namespace
sum(rate(container_cpu_usage_seconds_total{container!="POD"}[5m])) by (namespace)

# Memory usage percentile across pods
quantile(0.95, sum(container_memory_working_set_bytes) by (pod))

# Network traffic correlation
(
  sum(rate(node_network_receive_bytes_total[5m])) by (instance) +
  sum(rate(node_network_transmit_bytes_total[5m])) by (instance)
) / 1024 / 1024
```

### Time-based Analysis
```promql
# Compare current vs previous week
node_cpu_seconds_total offset 1w

# Growth rate over time
increase(prometheus_tsdb_symbol_table_size_bytes[1d])

# Moving average
avg_over_time(node_memory_MemAvailable_bytes[1h])

# Trend analysis
deriv(node_filesystem_size_bytes[1h])
```

### Advanced Functions
```promql
# Predict future values
predict_linear(node_filesystem_avail_bytes[1h], 4*3600)

# Rate calculations with extrapolation
rate(prometheus_http_requests_total[5m])

# Histogram quantiles
histogram_quantile(0.99, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (le))

# Label manipulation
label_replace(up, "short_instance", "$1", "instance", "([^:]+):.*")
```

## Custom Metrics and Exporters

### Creating a Custom Application Exporter

1. **Simple Python Exporter Example**:
```python
#!/usr/bin/env python3
from prometheus_client import start_http_server, Gauge, Counter, Histogram
import time
import random

# Define metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration')
ACTIVE_USERS = Gauge('app_active_users', 'Currently active users')
QUEUE_SIZE = Gauge('app_queue_size', 'Current queue size')

def generate_metrics():
    """Simulate application metrics"""
    while True:
        # Simulate requests
        REQUEST_COUNT.labels(method='GET', endpoint='/api/users').inc(random.randint(1, 10))
        REQUEST_COUNT.labels(method='POST', endpoint='/api/users').inc(random.randint(0, 3))
        
        # Simulate request duration
        REQUEST_DURATION.observe(random.uniform(0.1, 2.0))
        
        # Simulate active users
        ACTIVE_USERS.set(random.randint(50, 200))
        
        # Simulate queue size
        QUEUE_SIZE.set(random.randint(0, 50))
        
        time.sleep(15)

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8000)
    print("Custom exporter running on port 8000")
    generate_metrics()
```

2. **Dockerfile for Custom Exporter**:
```dockerfile
FROM python:3.9-slim
WORKDIR /app
RUN pip install prometheus_client
COPY custom_exporter.py .
EXPOSE 8000
CMD ["python", "custom_exporter.py"]
```

3. **Deploy to Kubernetes**:
```yaml
  custom-exporter:
    build: ./exporters/custom
    container_name: custom-exporter
    ports:
      - "8000:8000"
    networks:
      - k3s-network
    restart: unless-stopped
```

4. **Configure Prometheus to Scrape**:
```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['custom-exporter:8000']
    scrape_interval: 15s
    metrics_path: /metrics
```

## Recording Rules for Performance

### Create Recording Rules File
`config/prometheus/recording-rules.yml`:

```yaml
groups:
  - name: performance_rules
    interval: 30s
    rules:
      # CPU usage recording rules
      - record: instance:node_cpu:rate5m
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
      
      - record: instance:node_memory_usage:ratio
        expr: 1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
      
      # Pod resource usage
      - record: pod:container_cpu_usage:rate5m
        expr: sum(rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m])) by (pod, namespace)
      
      - record: pod:container_memory_usage:bytes
        expr: sum(container_memory_working_set_bytes{container!="POD",container!=""}) by (pod, namespace)
      
      # Application-level metrics
      - record: job:http_requests:rate5m
        expr: sum(rate(prometheus_http_requests_total[5m])) by (job)
      
      - record: job:http_request_duration:p99
        expr: histogram_quantile(0.99, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (job, le))

  - name: sli_rules
    interval: 30s
    rules:
      # Service Level Indicators
      - record: sli:http_availability:rate5m
        expr: sum(rate(prometheus_http_requests_total{code!~"5.."}[5m])) / sum(rate(prometheus_http_requests_total[5m]))
      
      - record: sli:http_latency:p95
        expr: histogram_quantile(0.95, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (le))
      
      - record: sli:error_rate:rate5m
        expr: sum(rate(prometheus_http_requests_total{code=~"5.."}[5m])) / sum(rate(prometheus_http_requests_total[5m]))
```

## Advanced Alerting Patterns

### Multi-condition Alerts
`config/prometheus/advanced-alerts.yml`:

```yaml
groups:
  - name: advanced_alerts
    rules:
      - alert: HighResourceUsage
        expr: |
          (
            instance:node_cpu:rate5m > 80 and
            instance:node_memory_usage:ratio > 0.85
          ) or (
            instance:node_cpu:rate5m > 90
          )
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High resource usage on {{ $labels.instance }}"
          description: "CPU: {{ $value | humanizePercentage }}, Memory: {{ with query \"instance:node_memory_usage:ratio{instance='\" }}{{ $labels.instance }}{{ \"'}\" }}{{ . | first | value | humanizePercentage }}{{ end }}"
      
      - alert: ApplicationSLOBreach
        expr: |
          (
            sli:http_availability:rate5m < 0.99 or
            sli:http_latency:p95 > 0.5 or
            sli:error_rate:rate5m > 0.01
          )
        for: 2m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "SLO breach detected"
          description: |
            Availability: {{ query "sli:http_availability:rate5m" | first | value | humanizePercentage }}
            P95 Latency: {{ query "sli:http_latency:p95" | first | value }}s
            Error Rate: {{ query "sli:error_rate:rate5m" | first | value | humanizePercentage }}
      
      - alert: PredictiveDiskFull
        expr: predict_linear(node_filesystem_avail_bytes{fstype!="tmpfs"}[1h], 4*3600) < 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk will be full in 4 hours"
          description: "{{ $labels.device }} on {{ $labels.instance }} will be full in approximately 4 hours"
```

## SLI/SLO Implementation

### Define Service Level Objectives

1. **Availability SLO**: 99.9% uptime
2. **Latency SLO**: 95% of requests < 200ms
3. **Error Rate SLO**: < 0.1% error rate

### SLO Monitoring Queries
```promql
# Availability over 30 days
avg_over_time(sli:http_availability:rate5m[30d])

# Latency budget burn rate
(
  1 - avg_over_time(sli:http_availability:rate5m[1h])
) / (1 - 0.999) * 24

# Error budget remaining
1 - (
  avg_over_time(sli:error_rate:rate5m[30d]) / 0.001
)
```

## Performance Optimization

### Query Optimization Techniques

1. **Use Recording Rules for Expensive Queries**:
   ```promql
   # Instead of this expensive query
   sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace)
   
   # Use this recording rule
   pod:container_cpu_usage:rate5m
   ```

2. **Limit Time Ranges**:
   ```promql
   # Be specific with time ranges
   node_cpu_seconds_total[5m]  # Good
   node_cpu_seconds_total[1d]  # Use carefully
   ```

3. **Use Appropriate Aggregations**:
   ```promql
   # Aggregate early
   sum(rate(http_requests_total[5m])) by (job)
   
   # Instead of
   sum(http_requests_total) by (job)
   ```

### Prometheus Configuration Tuning

```yaml
# prometheus.yml optimizations
global:
  scrape_interval: 15s       # Balance between data resolution and storage
  evaluation_interval: 15s   # How often to evaluate rules
  external_labels:
    cluster: 'k3s-dev'
    environment: 'development'

# Storage optimization
storage:
  tsdb:
    retention.time: 15d      # Adjust based on storage capacity
    retention.size: 10GB     # Limit disk usage
    wal-compression: true    # Compress WAL files

# Query optimization
query:
  max_concurrency: 20        # Limit concurrent queries
  timeout: 2m               # Query timeout
  max_samples: 50000000     # Limit samples per query
```

## Monitoring Best Practices

### Metric Design Principles

1. **Naming Conventions**:
   ```promql
   # Good metric names
   http_requests_total           # Counter with _total suffix
   http_request_duration_seconds # Histogram with unit
   memory_usage_bytes           # Gauge with unit
   
   # Avoid
   requests                     # No type indicator
   latency                      # No unit
   ```

2. **Label Design**:
   ```promql
   # Good labels
   http_requests_total{method="GET", status="200", endpoint="/api/users"}
   
   # Avoid high cardinality
   http_requests_total{user_id="12345"}  # Too many unique values
   ```

3. **Metric Types**:
   - **Counter**: Monotonically increasing values (requests, errors)
   - **Gauge**: Point-in-time values (memory usage, queue size)
   - **Histogram**: Distributions (request duration, response size)
   - **Summary**: Similar to histogram with quantiles

### Alerting Best Practices

1. **Alert Fatigue Prevention**:
   ```yaml
   # Use appropriate thresholds
   expr: instance:node_cpu:rate5m > 80  # Not 50
   for: 5m                              # Not 1m
   
   # Group related alerts
   group_by: ['alertname', 'cluster', 'service']
   ```

2. **Meaningful Annotations**:
   ```yaml
   annotations:
     summary: "{{ $labels.service }} is down"
     description: |
       Service {{ $labels.service }} in namespace {{ $labels.namespace }} 
       has been down for {{ $value }} minutes.
       Runbook: https://wiki.company.com/runbooks/{{ $labels.service }}
   ```

## Session Exercises

### Exercise 1: Custom Metrics
1. Create a custom exporter for a mock application
2. Add business-specific metrics (user signups, payments, etc.)
3. Create dashboards for these metrics

### Exercise 2: SLO Implementation
1. Define SLOs for your application
2. Create SLI recording rules
3. Set up SLO-based alerting

### Exercise 3: Performance Optimization
1. Identify slow queries in your environment
2. Create recording rules to optimize them
3. Measure the performance improvement

## Troubleshooting Advanced Issues

### High Cardinality Metrics
```bash
# Find high cardinality metrics
curl -s 'http://localhost:9090/api/v1/label/__name__/values' | jq '.data[]' | head -20

# Check series count per metric
curl -s 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes'
```

### Memory Usage Issues
```promql
# Monitor Prometheus memory usage
prometheus_tsdb_head_memory_usage_bytes
process_resident_memory_bytes{job="prometheus"}

# Check series count
prometheus_tsdb_head_series
```

### Query Performance
```promql
# Query execution time
prometheus_engine_query_duration_seconds

# Slow queries
topk(10, prometheus_engine_query_duration_seconds{quantile="0.9"})
```

## Next Steps

1. **Implement Alertmanager**: Set up notification routing and silencing
2. **Federation**: Connect multiple Prometheus instances
3. **Long-term Storage**: Set up Thanos or Cortex
4. **Custom Dashboards**: Build comprehensive Grafana dashboards
5. **Automation**: Implement monitoring as code

## Session Completion

✅ **You have completed the Advanced Prometheus Monitoring session!**

You should now be able to:
- Create sophisticated monitoring solutions
- Optimize Prometheus performance
- Implement SLI/SLO monitoring
- Design custom metrics and exporters
- Troubleshoot complex monitoring issues

Continue exploring with specialized monitoring topics or move to other platform components.
