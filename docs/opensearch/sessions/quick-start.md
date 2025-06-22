# OpenSearch Quick Start Session

## 🎯 Objective
Get familiar with OpenSearch and OpenSearch Dashboards for log analysis and search in the K3s development environment within 15 minutes.

## 📋 Prerequisites
- K3s development environment deployed
- Basic understanding of search concepts
- Web browser available

## 🚀 Session Steps

### Step 1: Environment Verification (3 minutes)

1. **Verify OpenSearch services are running**:
   ```bash
   ./scripts/k3s-helper.sh status | grep -E "(opensearch|dashboards)"
   ```

2. **Check OpenSearch cluster health**:
   ```bash
   curl -u admin:SecureOpenSearchPass123! http://localhost:9200/_cluster/health?pretty
   ```
   
   Expected output should show status: "green" or "yellow".

3. **Test OpenSearch API**:
   ```bash
   curl -u admin:SecureOpenSearchPass123! http://localhost:9200/
   ```
   
   Should return cluster information with version details.

### Step 2: Access OpenSearch Dashboards (2 minutes)

1. **Open OpenSearch Dashboards in browser**:
   ```
   http://opensearch.dev:5601
   # OR
   http://localhost:5601
   ```

2. **Login with credentials**:
   - Username: `admin`
   - Password: `SecureOpenSearchPass123!`

3. **Explore the home page**:
   - Click "Explore on my own" to skip tutorial
   - Note the main navigation menu

### Step 3: Create Sample Data (3 minutes)

1. **Index sample log data**:
   ```bash
   # Create sample log entries
   curl -X POST "localhost:9200/logs-sample/_doc/1" \
     -H 'Content-Type: application/json' \
     -u admin:SecureOpenSearchPass123! \
     -d '{
       "@timestamp": "2024-01-15T10:00:00Z",
       "level": "INFO",
       "message": "Application started successfully",
       "service": "web-app",
       "kubernetes": {
         "namespace": "default",
         "pod": "web-app-12345",
         "container": "app"
       }
     }'

   curl -X POST "localhost:9200/logs-sample/_doc/2" \
     -H 'Content-Type: application/json' \
     -u admin:SecureOpenSearchPass123! \
     -d '{
       "@timestamp": "2024-01-15T10:01:00Z",
       "level": "ERROR",
       "message": "Database connection failed",
       "service": "web-app",
       "kubernetes": {
         "namespace": "default",
         "pod": "web-app-12345",
         "container": "app"
       }
     }'

   curl -X POST "localhost:9200/logs-sample/_doc/3" \
     -H 'Content-Type: application/json' \
     -u admin:SecureOpenSearchPass123! \
     -d '{
       "@timestamp": "2024-01-15T10:02:00Z",
       "level": "WARN",
       "message": "High memory usage detected",
       "service": "monitoring",
       "kubernetes": {
         "namespace": "monitoring",
         "pod": "monitoring-67890",
         "container": "monitor"
       }
     }'
   ```

2. **Verify data was indexed**:
   ```bash
   curl -u admin:SecureOpenSearchPass123! \
     "localhost:9200/logs-sample/_search?pretty"
   ```

### Step 4: Basic Search Operations (4 minutes)

1. **Navigate to Discover in OpenSearch Dashboards**:
   - Click on "Discover" in the left menu
   - Create index pattern: `logs-sample`
   - Set time field: `@timestamp`

2. **Basic text search**:
   - In the search bar, try: `message:error`
   - Try: `level:ERROR`
   - Try: `service:web-app AND level:INFO`

3. **Time range filtering**:
   - Click the time picker (top right)
   - Try "Last 15 minutes"
   - Try "Today"

4. **Field filtering**:
   - In the left sidebar, click on field names
   - Try filtering by `level`
   - Try filtering by `service`

### Step 5: Basic Visualizations (3 minutes)

1. **Create a simple visualization**:
   - Navigate to "Visualize" → "Create visualization"
   - Choose "Vertical bar chart"
   - Select `logs-sample` index pattern

2. **Configure the chart**:
   - Y-axis: Count
   - X-axis: Terms aggregation on `level.keyword`
   - Click "Apply changes"

3. **Save the visualization**:
   - Click "Save"
   - Name: "Log Levels Distribution"

## ✅ Success Criteria

By the end of this session, you should be able to:
- [ ] Access OpenSearch API and verify cluster health
- [ ] Login to OpenSearch Dashboards
- [ ] Index sample data via REST API
- [ ] Create index patterns in Dashboards
- [ ] Perform basic text searches and filtering
- [ ] Create simple visualizations
- [ ] Navigate the Dashboards interface

## 🔍 Quick Reference Commands

### API Commands
```bash
# Check cluster health
curl -u admin:SecureOpenSearchPass123! http://localhost:9200/_cluster/health

# List all indices
curl -u admin:SecureOpenSearchPass123! http://localhost:9200/_cat/indices?v

# Search all documents
curl -u admin:SecureOpenSearchPass123! http://localhost:9200/logs-sample/_search?pretty

# Count documents
curl -u admin:SecureOpenSearchPass123! http://localhost:9200/logs-sample/_count

# Delete index (cleanup)
curl -X DELETE -u admin:SecureOpenSearchPass123! http://localhost:9200/logs-sample
```

### Query Examples
```json
// Search for errors
GET /logs-sample/_search
{
  "query": {
    "match": {
      "level": "ERROR"
    }
  }
}

// Time range query
GET /logs-sample/_search
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1h"
      }
    }
  }
}

// Boolean query
GET /logs-sample/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "service": "web-app" } },
        { "match": { "level": "ERROR" } }
      ]
    }
  }
}
```

## 🔍 Troubleshooting

### Issue: Cannot access OpenSearch API
```bash
# Check if service is running
docker ps | grep opensearch

# Check service logs
docker logs opensearch

# Verify port binding
netstat -tulpn | grep :9200
```

### Issue: Authentication fails
```bash
# Check environment variables
docker exec opensearch env | grep OPENSEARCH

# Reset admin password
docker exec opensearch /usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/opensearch/plugins/opensearch-security/securityconfig/ \
  -icl -nhnv
```

### Issue: No data appears in Dashboards
```bash
# Verify index exists
curl -u admin:SecureOpenSearchPass123! http://localhost:9200/_cat/indices

# Check index pattern in Dashboards
# Go to Stack Management → Index Patterns

# Refresh field list
# In index pattern, click "Refresh field list"
```

### Issue: Dashboards won't load
```bash
# Check Dashboards logs
docker logs opensearch-dashboards

# Verify connectivity to OpenSearch
docker exec opensearch-dashboards curl http://172.30.40.10:9200

# Check .opensearch_dashboards index
curl -u admin:SecureOpenSearchPass123! \
  http://localhost:9200/.opensearch_dashboards/_search?pretty
```

## 📚 Next Steps

After completing this quick start:
1. Try the **Log Analysis Session** for advanced search techniques
2. Explore **Index Management Session** for data lifecycle management
3. Learn about alerting and monitoring
4. Practice with real application logs

## 🕐 Time Estimate
**Total Duration**: 15 minutes
- Environment verification: 3 minutes
- Dashboard access: 2 minutes
- Sample data creation: 3 minutes
- Basic search operations: 4 minutes
- Basic visualizations: 3 minutes

## 📝 Notes
- All sample data is temporary and can be safely deleted
- Default credentials should be changed in production
- Index patterns are reusable for similar data structures
- Save frequently used searches as saved objects

## 🧹 Cleanup
```bash
# Remove sample data after session
curl -X DELETE -u admin:SecureOpenSearchPass123! \
  http://localhost:9200/logs-sample

# Remove index pattern from Dashboards UI:
# Stack Management → Index Patterns → logs-sample → Delete
```
