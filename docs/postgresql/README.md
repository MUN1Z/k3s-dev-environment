# PostgreSQL Documentation

## 🐘 Overview

PostgreSQL is the primary relational database service in our Kubernetes development environment. It provides a robust, ACID-compliant database for application development and testing.

### Key Features
- **Version**: PostgreSQL 15 Alpine
- **Namespace**: development
- **Deployment**: Single-instance deployment with persistent storage
- **Access**: Internal cluster access, TCP Ingress via Traefik, and port-forward for development
- **Storage**: 5GB persistent volume claim
- **External Port**: 5432 (via Traefik TCP Ingress)
- **Web UI**: pgAdmin4 accessible at `http://postgres.localhost`

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "PostgreSQL Architecture"
        subgraph "Access Layer"
            PGADMIN[pgAdmin4 Web UI<br/>postgres.localhost<br/>Web-based Administration]
            TRAEFIK_TCP[Traefik TCP Ingress<br/>localhost:5432<br/>Direct External Access]
            KUBECTL[kubectl port-forward<br/>External Access]
            CLUSTER_ACCESS[Cluster Internal Access<br/>postgres.development.svc.cluster.local]
        end
        
        subgraph "PostgreSQL Service - 172.30.50.10"
            POSTGRES_SERVER[PostgreSQL Server<br/>Version 15 Alpine]
            CONFIG[PostgreSQL Configuration<br/>Default + Custom Settings]
            DATABASES[Databases<br/>devdb (default)]
            USERS[Users<br/>admin (superuser)]
        end
        
        subgraph "Storage Layer"
            PVC[Persistent Volume Claim<br/>postgres-pvc]
            STORAGE[Persistent Storage<br/>5GB Local Path]
            DATA_DIR[Data Directory<br/>/var/lib/postgresql/data]
        end
        
        subgraph "Monitoring"
            METRICS[Connection Metrics<br/>Query Performance]
            LOGS[PostgreSQL Logs<br/>Error & Slow Query Logs]
        end
    end
    
    PGADMIN --> POSTGRES_SERVER
    TRAEFIK_TCP --> POSTGRES_SERVER
    KUBECTL --> POSTGRES_SERVER
    CLUSTER_ACCESS --> POSTGRES_SERVER
    POSTGRES_SERVER --> DATABASES
    POSTGRES_SERVER --> USERS
    POSTGRES_SERVER --> PVC
    PVC --> STORAGE
    STORAGE --> DATA_DIR
    POSTGRES_SERVER --> METRICS
    POSTGRES_SERVER --> LOGS
```

## 🔧 Configuration

### Kubernetes Configuration

PostgreSQL is deployed as a Kubernetes Deployment with the following configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_USER
          value: "admin"
        - name: POSTGRES_PASSWORD
          value: "1q2w3e4r@123"
        - name: POSTGRES_DB
          value: "devdb"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - admin
            - -d
            - devdb
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - admin
            - -d
            - devdb
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

### Service Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: development
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
  type: ClusterIP
```

### Storage Configuration

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: development
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Traefik TCP Ingress Configuration

PostgreSQL is exposed externally through Traefik's TCP Ingress functionality, allowing direct database connections without using `kubectl port-forward`.

#### IngressRouteTCP Configuration

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: postgres-tcp
  namespace: development
spec:
  entryPoints:
    - postgres
  routes:
  - match: HostSNI(`*`)
    services:
    - name: postgres
      port: 5432
```

#### Traefik EntryPoint Configuration

The Traefik configuration includes a dedicated `postgres` entryPoint:

```yaml
entryPoints:
  postgres:
    address: ":5432"
```

#### Access Verification

```bash
# Test TCP connectivity
nc -zv 127.0.0.1 5432

# Test PostgreSQL connection
PGPASSWORD=1q2w3e4r@123 psql -h 127.0.0.1 -p 5432 -U admin -d devdb -c "SELECT version();"

# Check connection details
PGPASSWORD=1q2w3e4r@123 psql -h 127.0.0.1 -p 5432 -U admin -d devdb -c "SELECT current_database(), current_user, inet_server_addr(), inet_server_port();"
```

### pgAdmin4 Configuration

pgAdmin4 provides a comprehensive web-based administration interface for PostgreSQL, accessible via browser at `http://postgres.localhost`.

#### pgAdmin4 Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgadmin
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pgadmin
  template:
    metadata:
      labels:
        app: pgadmin
    spec:
      containers:
      - name: pgadmin
        image: dpage/pgadmin4:8.0
        env:
        - name: PGADMIN_DEFAULT_EMAIL
          value: "admin@localhost.local"
        - name: PGADMIN_DEFAULT_PASSWORD
          value: "1q2w3e4r@123"
        - name: PGADMIN_CONFIG_LOGIN_BANNER
          value: '"PostgreSQL Admin - K3s Development Environment"'
        ports:
        - name: http
          containerPort: 80
        volumeMounts:
        - name: pgadmin-storage
          mountPath: /var/lib/pgadmin
        - name: pgadmin-config
          mountPath: /pgadmin4/servers.json
          subPath: servers.json
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
```

#### pgAdmin4 Service and Ingress

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pgadmin
  namespace: development
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    name: http
  selector:
    app: pgadmin
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: pgadmin-ingress
  namespace: development
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`postgres.localhost`)
    kind: Rule
    services:
    - name: pgadmin
      port: 80
```

#### Pre-configured PostgreSQL Server

pgAdmin4 is pre-configured with the local PostgreSQL server connection:

```json
{
  "Servers": {
    "1": {
      "Name": "Local PostgreSQL",
      "Group": "Servers",
      "Host": "postgres.development.svc.cluster.local",
      "Port": 5432,
      "MaintenanceDB": "devdb",
      "Username": "admin"
    }
  }
}
```

#### Access Credentials

- **URL**: `http://postgres.localhost`
- **Email**: `admin@localhost.local`
- **Password**: `1q2w3e4r@123`
- **PostgreSQL Connection**: Pre-configured (password required on first use)

## 🚀 Getting Started

### Accessing PostgreSQL

#### 1. Via pgAdmin4 Web Interface (GUI) ⭐ **Recommended for Administration**

```bash
# Access pgAdmin4 via web browser
# URL: http://postgres.localhost
# Email: admin@localhost.local
# Password: 1q2w3e4r@123

# Pre-configured server connection available
# Server: Local PostgreSQL
# Password for PostgreSQL: 1q2w3e4r@123
```

#### 2. Via Traefik TCP Ingress (Direct External Access) ⭐ **Recommended for CLI**

```bash
# Connect directly without port-forward (requires psql installed locally)
psql -h 127.0.0.1 -p 5432 -U admin -d devdb

# Connect using environment variable for password
PGPASSWORD=1q2w3e4r@123 psql -h 127.0.0.1 -p 5432 -U admin -d devdb

# Connect from any application on the host machine
# Connection string: postgresql://admin:1q2w3e4r@123@127.0.0.1:5432/devdb
```

#### 3. Via kubectl port-forward (External Access)

```bash
# Forward PostgreSQL port to localhost
kubectl port-forward -n development svc/postgres 5432:5432

# Connect using psql (if installed locally)
psql -h localhost -p 5432 -U admin -d devdb

# Connect using environment variable for password
PGPASSWORD=1q2w3e4r@123 psql -h localhost -p 5432 -U admin -d devdb
```

#### 4. Via kubectl exec (Direct Pod Access)

```bash
# Get PostgreSQL pod name
kubectl get pods -n development -l app=postgres

# Connect directly to PostgreSQL pod
kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb

# Run one-off queries
kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT version();"
```

#### 5. From Applications (Cluster Internal)

```bash
# Connection string for applications
postgresql://admin:1q2w3e4r@123@postgres.development.svc.cluster.local:5432/devdb

# Host: postgres.development.svc.cluster.local
# Port: 5432
# Database: devdb
# Username: admin
# Password: 1q2w3e4r@123
```

### Initial Setup Verification

```bash
# Check if PostgreSQL is running
kubectl get pods -n development -l app=postgres

# Check if pgAdmin4 is running
kubectl get pods -n development -l app=pgadmin

# Check service status
kubectl get svc -n development postgres
kubectl get svc -n development pgadmin

# Check persistent volumes
kubectl get pvc -n development postgres-pvc
kubectl get pvc -n development pgadmin-pvc

# Verify database connection
kubectl exec -it -n development deployment/postgres -- pg_isready -U admin

# Access pgAdmin4 web interface
echo "pgAdmin4 URL: http://postgres.localhost"
echo "Login: admin@localhost.local / 1q2w3e4r@123"
```

## �️ pgAdmin4 Web Interface

### Overview

pgAdmin4 provides a comprehensive web-based administration interface for PostgreSQL, making database management intuitive and accessible through a modern web browser.

### Key Features

- **Web-based Interface**: Accessible from any modern web browser
- **Query Tool**: Interactive SQL editor with syntax highlighting
- **Database Browser**: Visual exploration of database objects
- **Dashboard**: Real-time monitoring and statistics
- **User Management**: Graphical user and permission management
- **Backup/Restore**: GUI-based backup and restore operations
- **Performance Monitoring**: Query performance analysis
- **Schema Visualization**: ERD (Entity Relationship Diagram) support

### Getting Started with pgAdmin4

#### Initial Login

1. Open your web browser and navigate to `http://postgres.localhost`
2. Login with the following credentials:
   - **Email**: `admin@localhost.local`
   - **Password**: `1q2w3e4r@123`

#### Connecting to PostgreSQL

1. After login, you'll see a pre-configured server connection: "Local PostgreSQL"
2. Right-click on "Local PostgreSQL" and select "Connect Server"
3. Enter the PostgreSQL password: `1q2w3e4r@123`
4. The connection will be established and you can browse the database

#### Common Tasks

##### Creating a Database

1. Right-click on "Databases" under the server
2. Select "Create" → "Database..."
3. Enter database name and configure options
4. Click "Save"

##### Running Queries

1. Right-click on the database you want to query
2. Select "Query Tool"
3. Write your SQL query in the editor
4. Click the "Execute" button (▶️) or press F5

##### Managing Users

1. Expand the server in the browser
2. Right-click on "Login/Group Roles"
3. Select "Create" → "Login/Group Role..."
4. Configure user properties and permissions

##### Backup Database

1. Right-click on the database
2. Select "Backup..."
3. Configure backup options (format, filename, etc.)
4. Click "Backup"

##### Restore Database

1. Right-click on "Databases"
2. Select "Restore..."
3. Select the backup file
4. Configure restore options
5. Click "Restore"

### pgAdmin4 Configuration

#### Environment Variables

The pgAdmin4 deployment uses the following configuration:

```yaml
env:
- name: PGADMIN_DEFAULT_EMAIL
  value: "admin@localhost.local"
- name: PGADMIN_DEFAULT_PASSWORD
  value: "1q2w3e4r@123"
- name: PGADMIN_CONFIG_LOGIN_BANNER
  value: '"PostgreSQL Admin - K3s Development Environment"'
- name: PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION
  value: "True"
- name: PGADMIN_LISTEN_PORT
  value: "80"
```

#### Server Configuration

The PostgreSQL server is pre-configured in pgAdmin4 with these settings:

```json
{
  "Name": "Local PostgreSQL",
  "Host": "postgres.development.svc.cluster.local",
  "Port": 5432,
  "MaintenanceDB": "devdb",
  "Username": "admin"
}
```

#### Storage and Persistence

pgAdmin4 uses a persistent volume for storing:
- User preferences and settings
- Query history
- Saved queries and scripts
- Dashboard configurations

```yaml
volumeMounts:
- name: pgadmin-storage
  mountPath: /var/lib/pgadmin
```

### Security Considerations

#### Development Environment

⚠️ **Note**: Current pgAdmin4 configuration is optimized for development:

- **HTTP Only**: No SSL/TLS encryption (suitable for local development)
- **Simple Authentication**: Basic email/password authentication
- **Local Access**: Accessible only via `postgres.localhost`
- **Persistent Storage**: User data persisted across restarts

#### Production Recommendations

For production environments, consider:

```yaml
# HTTPS/TLS Configuration
- name: PGADMIN_CONFIG_FORCE_SSL
  value: "True"

# Enhanced Security Headers
- name: PGADMIN_CONFIG_SECURE_COOKIE
  value: "True"

# External Authentication
- name: PGADMIN_CONFIG_AUTHENTICATION_SOURCES
  value: "['ldap', 'internal']"
```

### Troubleshooting pgAdmin4

#### Common Issues

1. **Cannot Access Web Interface**
   ```bash
   # Check if pgAdmin4 pod is running
   kubectl get pods -n development -l app=pgadmin
   
   # Check service and ingress
   kubectl get svc,ingressroute -n development | grep pgadmin
   
   # Verify hosts file
   grep postgres.localhost /etc/hosts
   ```

2. **Cannot Connect to PostgreSQL**
   ```bash
   # Test network connectivity from pgAdmin4 to PostgreSQL
   kubectl exec -it -n development deployment/pgadmin -- nc -zv postgres.development.svc.cluster.local 5432
   
   # Check PostgreSQL credentials in server configuration
   # Verify PostgreSQL is accepting connections
   ```

3. **Performance Issues**
   ```bash
   # Check resource usage
   kubectl top pod -n development -l app=pgadmin
   
   # Increase memory/CPU limits if needed
   kubectl patch deployment pgadmin -n development -p '{"spec":{"template":{"spec":{"containers":[{"name":"pgadmin","resources":{"limits":{"memory":"1Gi","cpu":"500m"}}}]}}}}'
   ```

## �💼 Database Management

### Common Database Operations

#### Creating Databases

```sql
-- Connect as admin user
CREATE DATABASE myapp_db;
CREATE USER myapp_user WITH PASSWORD 'myapp_password';
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp_user;

-- Create with specific encoding
CREATE DATABASE analytics 
  WITH ENCODING 'UTF8' 
  LC_COLLATE='C' 
  LC_CTYPE='C' 
  TEMPLATE=template0;
```

#### User Management

```sql
-- Create application user
CREATE USER app_user WITH PASSWORD 'secure_password';

-- Grant specific privileges
GRANT CONNECT ON DATABASE devdb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT CREATE ON SCHEMA public TO app_user;

-- Create read-only user
CREATE USER readonly_user WITH PASSWORD 'readonly_pass';
GRANT CONNECT ON DATABASE devdb TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

#### Schema Management

```sql
-- Create application schema
CREATE SCHEMA app_schema;
GRANT ALL ON SCHEMA app_schema TO app_user;

-- List all schemas
\dn

-- Set default schema for user
ALTER USER app_user SET search_path TO app_schema, public;
```

### Database Maintenance

#### Backup Operations

```bash
# Backup entire database
kubectl exec -i -n development deployment/postgres -- pg_dump -U admin devdb > devdb_backup.sql

# Backup with compression
kubectl exec -i -n development deployment/postgres -- pg_dump -U admin -Fc devdb > devdb_backup.dump

# Backup specific tables
kubectl exec -i -n development deployment/postgres -- pg_dump -U admin -t users -t orders devdb > tables_backup.sql

# Backup all databases
kubectl exec -i -n development deployment/postgres -- pg_dumpall -U admin > full_backup.sql
```

#### Restore Operations

```bash
# Restore database from SQL dump
kubectl exec -i -n development deployment/postgres -- psql -U admin devdb < devdb_backup.sql

# Restore from custom format
kubectl exec -i -n development deployment/postgres -- pg_restore -U admin -d devdb devdb_backup.dump

# Restore all databases
kubectl exec -i -n development deployment/postgres -- psql -U admin -f full_backup.sql
```

#### Performance Monitoring

```sql
-- Check database size
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database 
WHERE datistemplate = false;

-- Monitor active connections
SELECT 
    datname,
    count(*) as connections,
    max(state) as max_state
FROM pg_stat_activity 
GROUP BY datname;

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Long running queries
SELECT 
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

## 🔍 Application Integration

### Environment Variables

For applications running in the same cluster:

```yaml
env:
- name: DB_HOST
  value: "postgres.development.svc.cluster.local"
- name: DB_PORT
  value: "5432"
- name: DB_NAME
  value: "devdb"
- name: DB_USER
  value: "admin"
- name: DB_PASSWORD
  value: "1q2w3e4r@123"
```

For applications running on the host machine (via Traefik TCP Ingress):

```yaml
env:
- name: DB_HOST
  value: "127.0.0.1"
- name: DB_PORT
  value: "5432"
- name: DB_NAME
  value: "devdb"
- name: DB_USER
  value: "admin"
- name: DB_PASSWORD
  value: "1q2w3e4r@123"
```

### Connection Examples

#### Node.js (pg library)

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'admin',
  host: process.env.DB_HOST || 'postgres.development.svc.cluster.local',
  database: process.env.DB_NAME || 'devdb',
  password: process.env.DB_PASSWORD || '1q2w3e4r@123',
  port: process.env.DB_PORT || 5432,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Database connected:', res.rows[0]);
  }
});
```

#### Python (psycopg2)

```python
import psycopg2
import os
from contextlib import contextmanager

DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres.development.svc.cluster.local'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'devdb'),
    'user': os.getenv('DB_USER', 'admin'),
    'password': os.getenv('DB_PASSWORD', '1q2w3e4r@123')
}

@contextmanager
def get_db_connection():
    conn = None
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        yield conn
    except psycopg2.Error as e:
        if conn:
            conn.rollback()
        raise
    finally:
        if conn:
            conn.close()

# Usage example
with get_db_connection() as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT version()")
    version = cursor.fetchone()
    print(f"PostgreSQL version: {version[0]}")
```

#### Go (pq library)

```go
package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    
    _ "github.com/lib/pq"
)

func main() {
    host := getEnv("DB_HOST", "postgres.development.svc.cluster.local")
    port := getEnv("DB_PORT", "5432")
    user := getEnv("DB_USER", "admin")
    password := getEnv("DB_PASSWORD", "1q2w3e4r@123")
    dbname := getEnv("DB_NAME", "devdb")

    psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        host, port, user, password, dbname)
    
    db, err := sql.Open("postgres", psqlInfo)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    err = db.Ping()
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("Successfully connected to PostgreSQL!")
}

func getEnv(key, fallback string) string {
    if value, ok := os.LookupEnv(key); ok {
        return value
    }
    return fallback
}
```

## 📊 Monitoring & Observability

### Health Checks

```bash
# Check PostgreSQL status
kubectl exec -n development deployment/postgres -- pg_isready -U admin

# Check database accessibility
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT 1;"

# Check resource usage
kubectl top pod -n development -l app=postgres
```

### Metrics Collection

#### Prometheus Integration

Example PostgreSQL exporter configuration for monitoring:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
    spec:
      containers:
      - name: postgres-exporter
        image: prometheuscommunity/postgres-exporter:latest
        env:
        - name: DATA_SOURCE_NAME
          value: "postgresql://admin:1q2w3e4r@123@postgres:5432/devdb?sslmode=disable"
        ports:
        - containerPort: 9187
          name: metrics
```

#### Key Metrics to Monitor

```promql
# Database connections
pg_stat_database_numbackends

# Database size
pg_database_size_bytes

# Query execution time
pg_stat_database_blk_read_time + pg_stat_database_blk_write_time

# Lock monitoring
pg_locks_count

# Replication lag (if applicable)
pg_replication_lag_seconds
```

### Log Management

```bash
# View PostgreSQL logs
kubectl logs -n development deployment/postgres -f

# Search for specific errors
kubectl logs -n development deployment/postgres | grep -i error

# Check slow queries (if log_min_duration_statement is set)
kubectl logs -n development deployment/postgres | grep "duration:"
```

## 🛠️ Troubleshooting

### Local PostgreSQL Client Installation

To connect to PostgreSQL directly via Traefik TCP Ingress, you need `psql` installed locally:

#### macOS (using Homebrew)

```bash
# Install PostgreSQL 15 client tools
brew install postgresql@15

# Add to PATH (for current session)
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

# Add to PATH permanently
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
which psql
psql --version
```

#### Linux (Ubuntu/Debian)

```bash
# Install PostgreSQL client
sudo apt-get update
sudo apt-get install postgresql-client-15

# Verify installation
which psql
psql --version
```

#### Linux (CentOS/RHEL/Fedora)

```bash
# Install PostgreSQL client
sudo yum install postgresql15
# or for newer versions
sudo dnf install postgresql15

# Verify installation
which psql
psql --version
```

### Common Issues

#### 1. Connection Refused

```bash
# Check if pod is running
kubectl get pods -n development -l app=postgres

# Check service endpoints
kubectl get endpoints -n development postgres

# Verify network policies (if any)
kubectl get networkpolicies -n development

# Test connectivity from another pod
kubectl run test-connection --rm -it --image=postgres:15-alpine -- psql -h postgres.development.svc.cluster.local -U admin -d devdb
```

#### 6. pgAdmin4 Web Interface Issues

```bash
# Check if pgAdmin4 is running
kubectl get pods -n development -l app=pgadmin

# Check pgAdmin4 service
kubectl get svc -n development pgadmin

# Check pgAdmin4 IngressRoute
kubectl get ingressroute -n development pgadmin-ingress

# Check pgAdmin4 logs
kubectl logs -n development deployment/pgadmin -f

# Verify hosts file entry
grep postgres.localhost /etc/hosts

# Test pgAdmin4 accessibility
curl -I http://postgres.localhost

# Restart pgAdmin4 if needed
kubectl rollout restart deployment/pgadmin -n development
```

#### pgAdmin4 Connection Issues

```bash
# If pgAdmin4 can't connect to PostgreSQL
# 1. Verify PostgreSQL is running
kubectl get pods -n development -l app=postgres

# 2. Test connection from pgAdmin4 pod
kubectl exec -it -n development deployment/pgadmin -- ping postgres.development.svc.cluster.local

# 3. Check if PostgreSQL service is accessible
kubectl exec -it -n development deployment/pgadmin -- nc -zv postgres.development.svc.cluster.local 5432

# 4. Reset pgAdmin4 configuration
kubectl delete pvc -n development pgadmin-pvc
kubectl rollout restart deployment/pgadmin -n development
```

#### 5. Traefik TCP Ingress Issues

```bash
# Check if Traefik is running with the new configuration
kubectl get pods -n traefik-system

# Verify Traefik service has PostgreSQL port exposed
kubectl get svc -n traefik-system traefik -o yaml | grep -A 20 "ports:"

# Check IngressRouteTCP status
kubectl get ingressroutetcp -n development postgres-tcp

# Describe IngressRouteTCP for details
kubectl describe ingressroutetcp -n development postgres-tcp

# Check Traefik logs for TCP routing issues
kubectl logs -n traefik-system deployment/traefik -f

# Test TCP connectivity without PostgreSQL
nc -zv 127.0.0.1 5432

# Test PostgreSQL protocol specifically
PGPASSWORD=1q2w3e4r@123 psql -h 127.0.0.1 -p 5432 -U admin -d devdb -c "SELECT 1;"
```

#### 2. Authentication Failed

```bash
# Verify credentials
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT current_user;"

# Check pg_hba.conf configuration
kubectl exec -n development deployment/postgres -- cat /var/lib/postgresql/data/pg_hba.conf

# Reset password if needed
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "ALTER USER admin PASSWORD 'new_password';"
```

#### 3. Storage Issues

```bash
# Check PVC status
kubectl get pvc -n development postgres-pvc

# Check available disk space
kubectl exec -n development deployment/postgres -- df -h /var/lib/postgresql/data

# Check for storage events
kubectl describe pvc -n development postgres-pvc
```

#### 4. Performance Issues

```sql
-- Check for lock conflicts
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation 
FROM pg_stats 
WHERE schemaname = 'public'
ORDER BY n_distinct DESC;
```

### Debug Commands

```bash
# Access PostgreSQL container shell
kubectl exec -it -n development deployment/postgres -- /bin/bash

# View PostgreSQL configuration
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SHOW ALL;"

# Check current connections
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT * FROM pg_stat_activity;"

# Validate database integrity
kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT datname, age(datfrozenxid) FROM pg_database;"
```

## 🔐 Security Best Practices

### Development Environment

⚠️ **Note**: This configuration is for development only. Production environments require additional security measures.

#### Current Security Features

1. **Network Isolation**: Service is only accessible within the cluster
2. **Namespace Separation**: Deployed in `development` namespace
3. **No External Exposure**: ClusterIP service type (no external access)
4. **Volume Encryption**: Data at rest protection (depends on storage class)

#### Production Recommendations

```yaml
# Enhanced security configuration for production
env:
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: password
- name: POSTGRES_INITDB_ARGS
  value: "--auth-local=scram-sha-256 --auth-host=scram-sha-256"

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 999
  fsGroup: 999
  capabilities:
    drop:
    - ALL

# Network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-network-policy
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: development
    ports:
    - protocol: TCP
      port: 5432
```

### User Access Control

```sql
-- Create limited privilege users for applications
CREATE USER app_readonly WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE devdb TO app_readonly;
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

-- Create application user with limited write access
CREATE USER app_writer WITH PASSWORD 'writer_password';
GRANT CONNECT ON DATABASE devdb TO app_writer;
GRANT USAGE ON SCHEMA public TO app_writer;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_writer;

-- Revoke public schema creation
REVOKE CREATE ON SCHEMA public FROM public;
```

## 📚 Advanced Configuration

### Custom PostgreSQL Configuration

To apply custom PostgreSQL settings, you can mount a custom configuration:

```yaml
# ConfigMap with custom postgres.conf
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: development
data:
  postgres.conf: |
    # Custom PostgreSQL configuration
    shared_preload_libraries = 'pg_stat_statements'
    max_connections = 200
    shared_buffers = 256MB
    effective_cache_size = 1GB
    work_mem = 4MB
    maintenance_work_mem = 64MB
    
    # Logging
    log_statement = 'all'
    log_min_duration_statement = 1000
    log_checkpoints = on
    log_connections = on
    log_disconnections = on
    
    # Replication (for future HA setup)
    wal_level = replica
    max_wal_senders = 3
    wal_keep_segments = 64
```

### Database Initialization Scripts

```yaml
# ConfigMap with init scripts
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init-scripts
  namespace: development
data:
  01-create-extensions.sql: |
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
  
  02-create-schemas.sql: |
    CREATE SCHEMA IF NOT EXISTS app_schema;
    CREATE SCHEMA IF NOT EXISTS audit_schema;
  
  03-create-functions.sql: |
    CREATE OR REPLACE FUNCTION update_modified_time()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.modified_at = now();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
```

### Performance Tuning

```sql
-- Enable query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Configure autovacuum
ALTER TABLE your_table SET (autovacuum_vacuum_scale_factor = 0.1);
ALTER TABLE your_table SET (autovacuum_analyze_scale_factor = 0.05);

-- Create performance monitoring views
CREATE VIEW slow_queries AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    stddev_time,
    rows
FROM pg_stat_statements
WHERE mean_time > 1000
ORDER BY mean_time DESC;
```

## 🔗 Integration Points

### With Grafana

PostgreSQL can be configured as a Grafana data source for application data visualization:

```yaml
# Grafana data source configuration
apiVersion: 1
datasources:
  - name: PostgreSQL
    type: postgres
    access: proxy
    url: postgres.development.svc.cluster.local:5432
    database: devdb
    user: readonly_user
    basicAuth: false
    secureJsonData:
      password: readonly_password
    jsonData:
      sslmode: disable
      maxOpenConns: 100
      maxIdleConns: 100
      connMaxLifetime: 14400
```

### With Application Deployments

Example application deployment with PostgreSQL dependency:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: development
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      initContainers:
      - name: wait-for-postgres
        image: postgres:15-alpine
        command: ['sh', '-c', 'until pg_isready -h postgres -p 5432; do sleep 1; done']
      containers:
      - name: web-app
        image: your-app:latest
        env:
        - name: DATABASE_URL
          value: "postgresql://admin:1q2w3e4r@123@postgres.development.svc.cluster.local:5432/devdb"
        ports:
        - containerPort: 8080
```

### With Backup Solutions

Automated backup configuration using CronJob:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: development
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:15-alpine
            command:
            - /bin/bash
            - -c
            - |
              export PGPASSWORD=1q2w3e4r@123
              pg_dump -h postgres -U admin devdb | gzip > /backup/devdb-$(date +%Y%m%d-%H%M%S).sql.gz
              # Keep only last 7 days of backups
              find /backup -name "*.sql.gz" -mtime +7 -delete
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: postgres-backup-pvc
          restartPolicy: OnFailure
```

## 📖 References

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Kubernetes PostgreSQL Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [PostgreSQL Security Guidelines](https://www.postgresql.org/docs/current/security.html)

## 📄 Session Files

### Quick Start Session
**File**: `docs/postgresql/sessions/quick-start.md`
- Database connection setup
- Basic operations walkthrough
- Connection testing

### pgAdmin4 Web Interface Session
**File**: `docs/postgresql/sessions/pgadmin4-setup.md`
- pgAdmin4 installation and configuration
- Web-based database administration
- GUI database management tasks
- Backup and restore via web interface

### Traefik TCP Ingress Session
**File**: `docs/postgresql/sessions/traefik-tcp-ingress.md`
- TCP Ingress configuration with Traefik
- Direct external access without port-forward
- Step-by-step implementation guide
- Troubleshooting and monitoring

### Database Administration Session
**File**: `docs/postgresql/sessions/database-administration.md`
- User management
- Backup and restore procedures
- Performance monitoring

### Application Integration Session
**File**: `docs/postgresql/sessions/application-integration.md`
- Connection pool configuration
- Migration strategies
- Development best practices

## 📋 Implementation Documentation

### pgAdmin4 Implementation
**File**: `docs/postgresql/pgadmin4-implementation.md`
- Complete pgAdmin4 deployment details
- Configuration specifications
- Verification and testing results
- Maintenance and operations guide

### Traefik TCP Ingress Implementation
**File**: `docs/postgresql/traefik-tcp-postgres-implementation.md`
- Traefik TCP Ingress configuration details
- Step-by-step implementation process
- Network architecture and routing
- Performance and security considerations
