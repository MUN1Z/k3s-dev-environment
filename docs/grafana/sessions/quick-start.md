# Grafana Quick Start Session

## 🎯 Objective
Get up and running with Grafana in the K3s development environment within 10 minutes.

## 📋 Prerequisites
- K3s development environment deployed
- Basic understanding of monitoring concepts
- Web browser available

## 🚀 Session Steps

### Step 1: Environment Verification (2 minutes)

1. **Verify services are running**:
   ```bash
   ./scripts/k3s-helper.sh status
   ```
   
   Expected output should show all services as "healthy" or "running".

2. **Check Grafana container**:
   ```bash
   docker ps | grep grafana
   ```
   
   Should show grafana container running on port 3000.

3. **Verify network connectivity**:
   ```bash
   curl -f http://localhost:3000/api/health
   ```
   
   Should return: `{"database":"ok","version":"..."}` 

### Step 2: Initial Access (2 minutes)

1. **Open Grafana in browser**:
   ```
   http://grafana.dev:3000
   # OR
   http://localhost:3000
   ```

2. **Login with default credentials**:
   - Username: `admin`
   - Password: `SecureGrafanaPass123!`

3. **First login prompts**:
   - Skip data source configuration (already provisioned)
   - Skip dashboard creation (already provisioned)

### Step 3: Verify Data Sources (2 minutes)

1. **Navigate to Configuration → Data Sources**
2. **Verify Prometheus data source**:
   - Click on "Prometheus"
   - Scroll down and click "Test"
   - Should show green "Data source is working"

3. **Verify OpenSearch data source**:
   - Click on "OpenSearch"
   - Click "Test"
   - Should show successful connection

### Step 4: Explore Pre-built Dashboards (3 minutes)

1. **Navigate to Dashboards → Browse**
2. **Open "Kubernetes Cluster Overview"**:
   - Should show cluster metrics
   - Verify data is populated (not "No data")
   - Check time range (default last 1 hour)

3. **Explore key panels**:
   - CPU Usage across nodes
   - Memory utilization
   - Pod count by namespace
   - Network traffic

4. **Try different time ranges**:
   - Click time picker (top right)
   - Try "Last 5 minutes" or "Last 15 minutes"

### Step 5: Basic Query Exercise (1 minute)

1. **Navigate to Explore**
2. **Select Prometheus data source**
3. **Try sample queries**:
   
   ```promql
   # CPU usage across all nodes
   100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
   # Memory usage percentage
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   
   # Number of running pods
   count(kube_pod_info{phase="Running"})
   ```

4. **Run query and verify results**

## ✅ Success Criteria

By the end of this session, you should be able to:
- [ ] Access Grafana web interface
- [ ] Verify all data sources are connected
- [ ] View pre-built dashboards with live data
- [ ] Execute basic Prometheus queries
- [ ] Navigate between different time ranges

## 🔍 Troubleshooting

### Issue: Cannot access Grafana web interface
```bash
# Check if service is running
docker ps | grep grafana

# Check logs for errors
docker logs grafana

# Verify port binding
netstat -tulpn | grep :3000
```

### Issue: No data in dashboards
```bash
# Check Prometheus connectivity
docker exec grafana ping prometheus

# Verify Prometheus is collecting metrics
curl http://localhost:9090/api/v1/targets

# Check if services are discovered
curl http://localhost:9090/api/v1/label/__name__/values
```

### Issue: Login credentials don't work
```bash
# Reset admin password
docker exec grafana grafana-cli admin reset-admin-password admin123

# Or check environment variables
docker exec grafana env | grep GF_SECURITY
```

## 📚 Next Steps

After completing this quick start:
1. Try the **Dashboard Development Session**
2. Set up **Alerting Configuration Session**
3. Explore custom dashboard creation
4. Configure notification channels

## 🕐 Time Estimate
**Total Duration**: 10 minutes
- Environment verification: 2 minutes
- Initial access: 2 minutes
- Data source verification: 2 minutes
- Dashboard exploration: 3 minutes
- Basic queries: 1 minute

## 📝 Notes
- Keep this session under 10 minutes for optimal onboarding
- If issues arise, refer to troubleshooting section first
- Document any custom changes or observations
- All default passwords should be changed in production
