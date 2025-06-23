# PostgreSQL Quick Start Session

## 🎯 Objective

Get up and running with PostgreSQL in the K3s development environment. This session covers basic connection setup, database verification, and essential operations for immediate productivity.

## 📋 Prerequisites

- K3s development environment is running
- PostgreSQL service is deployed
- kubectl CLI is configured
- Basic SQL knowledge

## 🚀 Session Steps

### Step 1: Environment Verification (2 minutes)

1. **Check PostgreSQL pod status**:
   ```bash
   kubectl get pods -n development -l app=postgres
   ```
   Expected output: `postgres-xxx-xxx` with STATUS `Running`

2. **Verify service availability**:
   ```bash
   kubectl get svc -n development postgres
   ```
   Expected output: Service with CLUSTER-IP and PORT 5432

3. **Check persistent storage**:
   ```bash
   kubectl get pvc -n development postgres-pvc
   ```
   Expected output: PVC with STATUS `Bound`

### Step 2: Direct Pod Connection (3 minutes)

1. **Connect to PostgreSQL directly from pod**:
   ```bash
   kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb
   ```

2. **Verify database connection**:
   ```sql
   SELECT version();
   SELECT current_database();
   SELECT current_user;
   ```

3. **List existing databases**:
   ```sql
   \l
   ```

4. **Exit psql**:
   ```sql
   \q
   ```

### Step 3: Port Forward Setup (2 minutes)

1. **Set up port forwarding** (in a separate terminal):
   ```bash
   kubectl port-forward -n development svc/postgres 5432:5432
   ```
   Keep this terminal open during the session.

2. **Test external connection** (if psql is installed locally):
   ```bash
   PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d devdb
   ```

3. **Alternative: Test connection with kubectl**:
   ```bash
   kubectl run psql-client --rm -it --image=postgres:15-alpine --restart=Never -- psql -h postgres.development.svc.cluster.local -U admin -d devdb
   ```

### Step 4: Basic Database Operations (3 minutes)

1. **Create a sample table**:
   ```sql
   CREATE TABLE users (
       id SERIAL PRIMARY KEY,
       name VARCHAR(100) NOT NULL,
       email VARCHAR(100) UNIQUE NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **Insert sample data**:
   ```sql
   INSERT INTO users (name, email) VALUES 
       ('John Doe', 'john@example.com'),
       ('Jane Smith', 'jane@example.com'),
       ('Bob Johnson', 'bob@example.com');
   ```

3. **Query the data**:
   ```sql
   SELECT * FROM users;
   SELECT name, email FROM users WHERE name LIKE '%John%';
   ```

4. **Check table structure**:
   ```sql
   \d users
   ```

### Step 5: Connection String Testing (2 minutes)

1. **Test connection string format**:
   ```bash
   # Full connection string
   postgresql://admin:1q2w3e4r@123@postgres.development.svc.cluster.local:5432/devdb
   ```

2. **Environment variables for applications**:
   ```bash
   export DB_HOST=postgres.development.svc.cluster.local
   export DB_PORT=5432
   export DB_NAME=devdb
   export DB_USER=admin
   export DB_PASSWORD=1q2w3e4r@123
   ```

3. **Test with simple client** (Python example):
   ```bash
   kubectl run python-client --rm -it --image=python:3.9-slim --restart=Never -- /bin/bash
   # Inside the container:
   pip install psycopg2-binary
   python3 -c "
   import psycopg2
   conn = psycopg2.connect(
       host='postgres.development.svc.cluster.local',
       port=5432,
       database='devdb',
       user='admin',
       password='1q2w3e4r@123'
   )
   cursor = conn.cursor()
   cursor.execute('SELECT version()')
   print('PostgreSQL version:', cursor.fetchone()[0])
   conn.close()
   "
   ```

### Step 6: Health Check and Monitoring (1 minute)

1. **Check PostgreSQL readiness**:
   ```bash
   kubectl exec -n development deployment/postgres -- pg_isready -U admin
   ```

2. **Monitor resource usage**:
   ```bash
   kubectl top pod -n development -l app=postgres
   ```

3. **View recent logs**:
   ```bash
   kubectl logs -n development deployment/postgres --tail=20
   ```

## ✅ Success Criteria

After completing this session, you should be able to:
- ✅ Connect to PostgreSQL from within the cluster
- ✅ Connect to PostgreSQL via port-forward
- ✅ Execute basic SQL commands
- ✅ Create and query tables
- ✅ Understand the connection parameters
- ✅ Monitor PostgreSQL health status

## 🔍 Troubleshooting

### Issue: Pod not running
```bash
# Check pod details
kubectl describe pod -n development -l app=postgres

# Check events
kubectl get events -n development --sort-by='.metadata.creationTimestamp'

# Restart deployment if needed
kubectl rollout restart -n development deployment/postgres
```

### Issue: Connection refused
```bash
# Verify service endpoints
kubectl get endpoints -n development postgres

# Check if port-forward is running
netstat -tulpn | grep :5432

# Test network connectivity
kubectl run test-net --rm -it --image=busybox --restart=Never -- nc -zv postgres.development.svc.cluster.local 5432
```

### Issue: Authentication failed
```bash
# Verify environment variables in pod
kubectl exec -n development deployment/postgres -- env | grep POSTGRES

# Check PostgreSQL authentication configuration
kubectl exec -n development deployment/postgres -- cat /var/lib/postgresql/data/pg_hba.conf
```

### Issue: Database not found
```bash
# List all databases
kubectl exec -n development deployment/postgres -- psql -U admin -l

# Check if database exists
kubectl exec -n development deployment/postgres -- psql -U admin -c "SELECT datname FROM pg_database WHERE datname='devdb';"
```

## 📚 Next Steps

After completing this quick start:
1. Try the **Database Administration Session**
2. Explore **Application Integration Session**
3. Set up automated backups
4. Configure monitoring and alerting
5. Create additional databases for different applications

## 🕐 Time Estimate
**Total Duration**: 12 minutes
- Environment verification: 2 minutes
- Direct pod connection: 3 minutes
- Port forward setup: 2 minutes
- Basic operations: 3 minutes
- Connection string testing: 2 minutes
- Health check: 1 minute

## 📝 Notes
- Keep this session under 15 minutes for optimal onboarding
- Save the port-forward command for future use
- Document any custom connection strings or configurations
- All default credentials are for development only
- Consider setting up connection pooling for production applications

## 🔗 Useful Commands Reference

```bash
# Quick access commands
alias pgpod="kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb"
alias pgforward="kubectl port-forward -n development svc/postgres 5432:5432"
alias pgstatus="kubectl get pods -n development -l app=postgres"
alias pglogs="kubectl logs -n development deployment/postgres -f"

# Connection testing
function test-pg() {
    kubectl run pg-test --rm -it --image=postgres:15-alpine --restart=Never -- psql -h postgres.development.svc.cluster.local -U admin -d devdb -c "SELECT 'Connection successful!' as status;"
}
```
