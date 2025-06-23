# PostgreSQL Application Integration Session

## 🎯 Objective

Learn how to properly integrate applications with PostgreSQL in the K3s development environment, including connection pooling, migration strategies, environment configuration, and development best practices.

## 📋 Prerequisites

- Completed PostgreSQL Quick Start Session
- Basic knowledge of application development
- Understanding of environment variables and configuration
- Familiarity with at least one programming language (Node.js, Python, Go, etc.)

## 🚀 Session Steps

### Step 1: Connection Configuration Patterns (10 minutes)

#### Environment-Based Configuration

1. **Create application configuration template**:
   ```yaml
   # Create ConfigMap for database configuration
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: app-db-config
     namespace: development
   data:
     DB_HOST: "postgres.development.svc.cluster.local"
     DB_PORT: "5432"
     DB_NAME: "devdb"
     DB_SSL_MODE: "disable"
     DB_MAX_CONNECTIONS: "20"
     DB_IDLE_CONNECTIONS: "5"
     DB_CONNECTION_TIMEOUT: "30s"
     DB_IDLE_TIMEOUT: "300s"
     DB_LIFETIME: "3600s"
   ```

2. **Create secret for credentials**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: app-db-credentials
     namespace: development
   type: Opaque
   data:
     DB_USER: YWRtaW4=      # admin (base64)
     DB_PASSWORD: MXEydzNlNHJAMTIz  # 1q2w3e4r@123 (base64)
   ```

3. **Apply configurations**:
   ```bash
   # Save the YAML content to files and apply
   kubectl apply -f app-db-config.yaml
   kubectl apply -f app-db-credentials.yaml
   ```

#### Connection String Patterns

4. **Test different connection string formats**:
   ```bash
   # Environment variables approach
   export DB_HOST=postgres.development.svc.cluster.local
   export DB_PORT=5432
   export DB_NAME=devdb
   export DB_USER=admin
   export DB_PASSWORD=1q2w3e4r@123

   # Full connection string
   export DATABASE_URL="postgresql://admin:1q2w3e4r@123@postgres.development.svc.cluster.local:5432/devdb?sslmode=disable"

   # Test connection
   kubectl run db-test --rm -it --image=postgres:15-alpine --restart=Never -- psql "$DATABASE_URL" -c "SELECT 'Connection successful!' as result;"
   ```

### Step 2: Language-Specific Integration Examples (15 minutes)

#### Node.js Integration

1. **Create Node.js application example**:
   ```bash
   # Create a test deployment
   kubectl run nodejs-db-app --image=node:18-alpine --restart=Never -it --rm -- /bin/sh
   ```

   ```javascript
   # Inside the container, create app.js
   cat > app.js << 'EOF'
   const { Pool } = require('pg');
   const express = require('express');

   const app = express();
   app.use(express.json());

   // Database connection pool
   const pool = new Pool({
     host: process.env.DB_HOST || 'postgres.development.svc.cluster.local',
     port: process.env.DB_PORT || 5432,
     database: process.env.DB_NAME || 'devdb',
     user: process.env.DB_USER || 'admin',
     password: process.env.DB_PASSWORD || '1q2w3e4r@123',
     max: parseInt(process.env.DB_MAX_CONNECTIONS) || 20,
     idleTimeoutMillis: 30000,
     connectionTimeoutMillis: 2000,
   });

   // Health check endpoint
   app.get('/health', async (req, res) => {
     try {
       const client = await pool.connect();
       const result = await client.query('SELECT NOW() as timestamp');
       client.release();
       res.json({
         status: 'healthy',
         database: 'connected',
         timestamp: result.rows[0].timestamp
       });
     } catch (err) {
       res.status(500).json({
         status: 'unhealthy',
         error: err.message
       });
     }
   });

   // Users API
   app.get('/users', async (req, res) => {
     try {
       const result = await pool.query('SELECT * FROM users ORDER BY id');
       res.json(result.rows);
     } catch (err) {
       res.status(500).json({ error: err.message });
     }
   });

   app.post('/users', async (req, res) => {
     const { name, email } = req.body;
     try {
       const result = await pool.query(
         'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
         [name, email]
       );
       res.status(201).json(result.rows[0]);
     } catch (err) {
       res.status(400).json({ error: err.message });
     }
   });

   // Database connection monitoring
   app.get('/db-stats', async (req, res) => {
     try {
       const stats = {
         totalCount: pool.totalCount,
         idleCount: pool.idleCount,
         waitingCount: pool.waitingCount
       };
       res.json(stats);
     } catch (err) {
       res.status(500).json({ error: err.message });
     }
   });

   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () => {
     console.log(`Server running on port ${PORT}`);
   });

   // Graceful shutdown
   process.on('SIGTERM', () => {
     pool.end(() => {
       console.log('Database pool closed');
       process.exit(0);
     });
   });
   EOF

   # Install dependencies and run
   npm init -y
   npm install pg express
   node app.js
   ```

#### Python Integration

2. **Create Python application example**:
   ```python
   # Create Python app in a new test pod
   kubectl run python-db-app --image=python:3.9-slim --restart=Never -it --rm -- /bin/bash

   # Inside the container
   pip install psycopg2-binary flask python-dotenv

   cat > app.py << 'EOF'
   import os
   import psycopg2
   from psycopg2 import pool
   from flask import Flask, request, jsonify
   from contextlib import contextmanager
   import logging

   app = Flask(__name__)
   logging.basicConfig(level=logging.INFO)

   # Database configuration
   DB_CONFIG = {
       'host': os.getenv('DB_HOST', 'postgres.development.svc.cluster.local'),
       'port': os.getenv('DB_PORT', '5432'),
       'database': os.getenv('DB_NAME', 'devdb'),
       'user': os.getenv('DB_USER', 'admin'),
       'password': os.getenv('DB_PASSWORD', '1q2w3e4r@123')
   }

   # Create connection pool
   connection_pool = psycopg2.pool.SimpleConnectionPool(
       1, 20, **DB_CONFIG
   )

   @contextmanager
   def get_db_connection():
       conn = None
       try:
           conn = connection_pool.getconn()
           yield conn
       except psycopg2.Error as e:
           if conn:
               conn.rollback()
           raise
       finally:
           if conn:
               connection_pool.putconn(conn)

   @app.route('/health')
   def health_check():
       try:
           with get_db_connection() as conn:
               cursor = conn.cursor()
               cursor.execute("SELECT NOW()")
               timestamp = cursor.fetchone()[0]
               return jsonify({
                   'status': 'healthy',
                   'database': 'connected',
                   'timestamp': timestamp.isoformat()
               })
       except Exception as e:
           return jsonify({
               'status': 'unhealthy',
               'error': str(e)
           }), 500

   @app.route('/users', methods=['GET'])
   def get_users():
       try:
           with get_db_connection() as conn:
               cursor = conn.cursor()
               cursor.execute("SELECT * FROM users ORDER BY id")
               users = cursor.fetchall()
               return jsonify([{
                   'id': user[0],
                   'name': user[1],
                   'email': user[2],
                   'created_at': user[3].isoformat() if user[3] else None
               } for user in users])
       except Exception as e:
           return jsonify({'error': str(e)}), 500

   @app.route('/users', methods=['POST'])
   def create_user():
       data = request.json
       try:
           with get_db_connection() as conn:
               cursor = conn.cursor()
               cursor.execute(
                   "INSERT INTO users (name, email) VALUES (%s, %s) RETURNING *",
                   (data['name'], data['email'])
               )
               user = cursor.fetchone()
               conn.commit()
               return jsonify({
                   'id': user[0],
                   'name': user[1],
                   'email': user[2],
                   'created_at': user[3].isoformat()
               }), 201
       except Exception as e:
           return jsonify({'error': str(e)}), 400

   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000, debug=True)
   EOF

   python app.py
   ```

#### Go Integration

3. **Create Go application example**:
   ```go
   # Create Go app
   kubectl run go-db-app --image=golang:1.19-alpine --restart=Never -it --rm -- /bin/sh

   # Inside the container
   go mod init db-app
   go get github.com/lib/pq
   go get github.com/gin-gonic/gin

   cat > main.go << 'EOF'
   package main

   import (
       "database/sql"
       "fmt"
       "log"
       "net/http"
       "os"
       "strconv"
       "time"

       "github.com/gin-gonic/gin"
       _ "github.com/lib/pq"
   )

   type User struct {
       ID        int       `json:"id"`
       Name      string    `json:"name"`
       Email     string    `json:"email"`
       CreatedAt time.Time `json:"created_at"`
   }

   var db *sql.DB

   func getEnv(key, fallback string) string {
       if value, ok := os.LookupEnv(key); ok {
           return value
       }
       return fallback
   }

   func initDB() error {
       host := getEnv("DB_HOST", "postgres.development.svc.cluster.local")
       port := getEnv("DB_PORT", "5432")
       user := getEnv("DB_USER", "admin")
       password := getEnv("DB_PASSWORD", "1q2w3e4r@123")
       dbname := getEnv("DB_NAME", "devdb")

       psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
           host, port, user, password, dbname)

       var err error
       db, err = sql.Open("postgres", psqlInfo)
       if err != nil {
           return err
       }

       // Configure connection pool
       maxOpenConns, _ := strconv.Atoi(getEnv("DB_MAX_CONNECTIONS", "20"))
       maxIdleConns, _ := strconv.Atoi(getEnv("DB_IDLE_CONNECTIONS", "5"))
       
       db.SetMaxOpenConns(maxOpenConns)
       db.SetMaxIdleConns(maxIdleConns)
       db.SetConnMaxLifetime(time.Hour)

       return db.Ping()
   }

   func healthCheck(c *gin.Context) {
       var timestamp time.Time
       err := db.QueryRow("SELECT NOW()").Scan(&timestamp)
       if err != nil {
           c.JSON(http.StatusInternalServerError, gin.H{
               "status": "unhealthy",
               "error":  err.Error(),
           })
           return
       }

       c.JSON(http.StatusOK, gin.H{
           "status":    "healthy",
           "database":  "connected",
           "timestamp": timestamp,
       })
   }

   func getUsers(c *gin.Context) {
       rows, err := db.Query("SELECT id, name, email, created_at FROM users ORDER BY id")
       if err != nil {
           c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
           return
       }
       defer rows.Close()

       var users []User
       for rows.Next() {
           var user User
           err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt)
           if err != nil {
               c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
               return
           }
           users = append(users, user)
       }

       c.JSON(http.StatusOK, users)
   }

   func createUser(c *gin.Context) {
       var user User
       if err := c.ShouldBindJSON(&user); err != nil {
           c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
           return
       }

       err := db.QueryRow(
           "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, created_at",
           user.Name, user.Email,
       ).Scan(&user.ID, &user.CreatedAt)

       if err != nil {
           c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
           return
       }

       c.JSON(http.StatusCreated, user)
   }

   func main() {
       if err := initDB(); err != nil {
           log.Fatal("Failed to connect to database:", err)
       }
       defer db.Close()

       r := gin.Default()
       
       r.GET("/health", healthCheck)
       r.GET("/users", getUsers)
       r.POST("/users", createUser)

       port := getEnv("PORT", "8080")
       log.Printf("Server starting on port %s", port)
       r.Run(":" + port)
   }
   EOF

   go run main.go
   ```

### Step 3: Migration Strategies and Database Versioning (8 minutes)

#### Database Migration Setup

1. **Create migration structure**:
   ```bash
   # Connect to PostgreSQL
   kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb
   ```

   ```sql
   -- Create migration tracking table
   CREATE TABLE IF NOT EXISTS schema_migrations (
       version VARCHAR(255) PRIMARY KEY,
       applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       description TEXT
   );

   -- Create initial migration
   INSERT INTO schema_migrations (version, description) 
   VALUES ('001_initial_schema', 'Create users table and initial data');
   ```

2. **Example migration scripts**:
   ```sql
   -- Migration: 002_add_user_profiles
   BEGIN;

   CREATE TABLE user_profiles (
       id SERIAL PRIMARY KEY,
       user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
       bio TEXT,
       avatar_url VARCHAR(500),
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

   CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

   INSERT INTO schema_migrations (version, description) 
   VALUES ('002_add_user_profiles', 'Add user profiles table');

   COMMIT;

   -- Migration: 003_add_audit_fields
   BEGIN;

   ALTER TABLE users 
   ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   ADD COLUMN created_by VARCHAR(100) DEFAULT 'system',
   ADD COLUMN updated_by VARCHAR(100) DEFAULT 'system';

   -- Create trigger for auto-updating updated_at
   CREATE OR REPLACE FUNCTION update_updated_at_column()
   RETURNS TRIGGER AS $$
   BEGIN
       NEW.updated_at = CURRENT_TIMESTAMP;
       RETURN NEW;
   END;
   $$ language 'plpgsql';

   CREATE TRIGGER update_users_updated_at 
   BEFORE UPDATE ON users 
   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

   INSERT INTO schema_migrations (version, description) 
   VALUES ('003_add_audit_fields', 'Add audit fields to users table');

   COMMIT;
   ```

3. **Check migration status**:
   ```sql
   -- View applied migrations
   SELECT * FROM schema_migrations ORDER BY version;

   -- Check table structure
   \d users
   \d user_profiles
   ```

#### Migration Best Practices

4. **Create migration script template**:
   ```bash
   # Create migration script
   kubectl exec -it -n development deployment/postgres -- /bin/bash

   cat > /usr/local/bin/migrate.sh << 'EOF'
   #!/bin/bash
   
   MIGRATION_VERSION=$1
   MIGRATION_FILE=$2
   
   if [ -z "$MIGRATION_VERSION" ] || [ -z "$MIGRATION_FILE" ]; then
       echo "Usage: $0 <version> <migration_file>"
       exit 1
   fi
   
   echo "Applying migration $MIGRATION_VERSION..."
   
   # Check if migration already applied
   APPLIED=$(psql -U admin -d devdb -t -c "SELECT 1 FROM schema_migrations WHERE version = '$MIGRATION_VERSION'")
   
   if [ ! -z "$APPLIED" ]; then
       echo "Migration $MIGRATION_VERSION already applied"
       exit 0
   fi
   
   # Apply migration
   psql -U admin -d devdb -f "$MIGRATION_FILE"
   
   if [ $? -eq 0 ]; then
       echo "Migration $MIGRATION_VERSION applied successfully"
   else
       echo "Migration $MIGRATION_VERSION failed"
       exit 1
   fi
   EOF

   chmod +x /usr/local/bin/migrate.sh
   exit
   ```

### Step 4: Connection Pooling and Performance Optimization (12 minutes)

#### Application-Level Connection Pooling

1. **Configure connection pools in applications**:
   ```javascript
   // Node.js - Advanced pool configuration
   const pool = new Pool({
     host: process.env.DB_HOST,
     port: process.env.DB_PORT,
     database: process.env.DB_NAME,
     user: process.env.DB_USER,
     password: process.env.DB_PASSWORD,
     
     // Pool configuration
     max: 20,                    // Maximum connections
     min: 5,                     // Minimum connections
     idleTimeoutMillis: 300000,  // 5 minutes
     connectionTimeoutMillis: 10000, // 10 seconds
     acquireTimeoutMillis: 60000,    // 1 minute
     
     // Health check
     allowExitOnIdle: false,
     
     // Custom connection validation
     Promise: Promise,
   });

   // Pool event handlers
   pool.on('connect', (client) => {
     console.log('New client connected');
   });

   pool.on('error', (err) => {
     console.error('Pool error:', err);
   });

   pool.on('remove', (client) => {
     console.log('Client removed from pool');
   });
   ```

2. **Monitor connection pool metrics**:
   ```sql
   -- Monitor active connections
   SELECT 
       application_name,
       client_addr,
       state,
       count(*) as connection_count
   FROM pg_stat_activity 
   WHERE datname = 'devdb'
   GROUP BY application_name, client_addr, state
   ORDER BY connection_count DESC;

   -- Check connection pool utilization
   SELECT 
       datname,
       numbackends as current_connections,
       setting::int as max_connections,
       round(numbackends::float / setting::int * 100, 2) as connection_utilization
   FROM pg_stat_database psd
   JOIN pg_settings ps ON ps.name = 'max_connections'
   WHERE datname = 'devdb';
   ```

#### External Connection Pooling with PgBouncer

3. **Deploy PgBouncer for connection pooling**:
   ```yaml
   # Create PgBouncer configuration
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: pgbouncer-config
     namespace: development
   data:
     pgbouncer.ini: |
       [databases]
       devdb = host=postgres port=5432 dbname=devdb
       
       [pgbouncer]
       listen_addr = 0.0.0.0
       listen_port = 6432
       auth_type = trust
       auth_file = /etc/pgbouncer/userlist.txt
       
       pool_mode = transaction
       max_client_conn = 100
       default_pool_size = 25
       reserve_pool_size = 5
       
       log_connections = 1
       log_disconnections = 1
       
     userlist.txt: |
       "admin" "1q2w3e4r@123"
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: pgbouncer
     namespace: development
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: pgbouncer
     template:
       metadata:
         labels:
           app: pgbouncer
       spec:
         containers:
         - name: pgbouncer
           image: pgbouncer/pgbouncer:latest
           ports:
           - containerPort: 6432
           volumeMounts:
           - name: config
             mountPath: /etc/pgbouncer
           resources:
             requests:
               memory: "64Mi"
               cpu: "50m"
             limits:
               memory: "128Mi"
               cpu: "100m"
         volumes:
         - name: config
           configMap:
             name: pgbouncer-config
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: pgbouncer
     namespace: development
   spec:
     selector:
       app: pgbouncer
     ports:
     - port: 6432
       targetPort: 6432
   ```

4. **Test PgBouncer connection**:
   ```bash
   # Apply PgBouncer configuration
   kubectl apply -f pgbouncer.yaml

   # Test connection through PgBouncer
   kubectl run pgbouncer-test --rm -it --image=postgres:15-alpine --restart=Never -- psql -h pgbouncer.development.svc.cluster.local -p 6432 -U admin -d devdb

   # Monitor PgBouncer stats
   kubectl exec -it -n development deployment/pgbouncer -- psql -h localhost -p 6432 -U admin pgbouncer -c "SHOW STATS;"
   kubectl exec -it -n development deployment/pgbouncer -- psql -h localhost -p 6432 -U admin pgbouncer -c "SHOW POOLS;"
   ```

### Step 5: Testing and Development Workflows (10 minutes)

#### Database Testing Strategies

1. **Create test database setup**:
   ```sql
   -- Connect to PostgreSQL
   CREATE DATABASE test_devdb;
   CREATE USER test_user WITH PASSWORD 'test_password';
   GRANT ALL PRIVILEGES ON DATABASE test_devdb TO test_user;

   -- Switch to test database
   \c test_devdb

   -- Create test schema
   CREATE SCHEMA test_data;
   GRANT ALL ON SCHEMA test_data TO test_user;

   -- Create test fixtures
   CREATE TABLE test_data.test_users (
       id SERIAL PRIMARY KEY,
       name VARCHAR(100),
       email VARCHAR(100),
       test_case VARCHAR(50)
   );

   INSERT INTO test_data.test_users (name, email, test_case) VALUES
   ('Test User 1', 'test1@example.com', 'basic_test'),
   ('Test User 2', 'test2@example.com', 'validation_test'),
   ('Test User 3', 'test3@example.com', 'edge_case_test');
   ```

2. **Create database seeding script**:
   ```bash
   # Create seed script
   kubectl exec -it -n development deployment/postgres -- /bin/bash

   cat > /usr/local/bin/seed-db.sh << 'EOF'
   #!/bin/bash
   
   DATABASE=${1:-devdb}
   
   echo "Seeding database: $DATABASE"
   
   psql -U admin -d $DATABASE << 'SQL'
   -- Clear existing data
   TRUNCATE users RESTART IDENTITY CASCADE;
   
   -- Insert seed data
   INSERT INTO users (name, email) VALUES
   ('Alice Johnson', 'alice@example.com'),
   ('Bob Smith', 'bob@example.com'),
   ('Carol Davis', 'carol@example.com'),
   ('David Wilson', 'david@example.com'),
   ('Eve Brown', 'eve@example.com');
   
   -- Create sample user profiles if table exists
   INSERT INTO user_profiles (user_id, bio, avatar_url)
   SELECT 
       id,
       'Sample bio for ' || name,
       'https://example.com/avatar/' || id || '.jpg'
   FROM users
   WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles');
   
   SELECT 'Database seeded successfully!' as result;
   SQL
   EOF

   chmod +x /usr/local/bin/seed-db.sh
   exit
   ```

3. **Test the seeding script**:
   ```bash
   # Run seeding
   kubectl exec -n development deployment/postgres -- /usr/local/bin/seed-db.sh

   # Verify seeded data
   kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT count(*) as user_count FROM users;"
   ```

#### Development Environment Management

4. **Create development reset script**:
   ```bash
   # Create reset script for development
   cat > reset-dev-db.sh << 'EOF'
   #!/bin/bash
   
   echo "Resetting development database..."
   
   # Drop and recreate database
   kubectl exec -n development deployment/postgres -- psql -U admin -c "DROP DATABASE IF EXISTS devdb;"
   kubectl exec -n development deployment/postgres -- psql -U admin -c "CREATE DATABASE devdb;"
   
   # Run migrations
   kubectl exec -n development deployment/postgres -- psql -U admin -d devdb << 'SQL'
   -- Recreate users table
   CREATE TABLE users (
       id SERIAL PRIMARY KEY,
       name VARCHAR(100) NOT NULL,
       email VARCHAR(100) UNIQUE NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       created_by VARCHAR(100) DEFAULT 'system',
       updated_by VARCHAR(100) DEFAULT 'system'
   );
   
   -- Recreate user_profiles table
   CREATE TABLE user_profiles (
       id SERIAL PRIMARY KEY,
       user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
       bio TEXT,
       avatar_url VARCHAR(500),
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
   
   -- Create update trigger
   CREATE OR REPLACE FUNCTION update_updated_at_column()
   RETURNS TRIGGER AS $$
   BEGIN
       NEW.updated_at = CURRENT_TIMESTAMP;
       RETURN NEW;
   END;
   $$ language 'plpgsql';
   
   CREATE TRIGGER update_users_updated_at 
   BEFORE UPDATE ON users 
   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
   
   -- Create migration tracking table
   CREATE TABLE schema_migrations (
       version VARCHAR(255) PRIMARY KEY,
       applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       description TEXT
   );
   
   INSERT INTO schema_migrations (version, description) VALUES
   ('001_initial_schema', 'Create users table and initial data'),
   ('002_add_user_profiles', 'Add user profiles table'),
   ('003_add_audit_fields', 'Add audit fields to users table');
   SQL
   
   # Seed with test data
   kubectl exec -n development deployment/postgres -- /usr/local/bin/seed-db.sh
   
   echo "Development database reset complete!"
   EOF

   chmod +x reset-dev-db.sh
   ```

5. **Create backup and restore for development**:
   ```bash
   # Create backup/restore scripts
   cat > backup-dev-db.sh << 'EOF'
   #!/bin/bash
   
   BACKUP_NAME="dev-backup-$(date +%Y%m%d-%H%M%S)"
   
   echo "Creating backup: $BACKUP_NAME"
   kubectl exec -n development deployment/postgres -- pg_dump -U admin devdb > "$BACKUP_NAME.sql"
   echo "Backup saved as: $BACKUP_NAME.sql"
   EOF

   cat > restore-dev-db.sh << 'EOF'
   #!/bin/bash
   
   BACKUP_FILE=$1
   
   if [ -z "$BACKUP_FILE" ]; then
       echo "Usage: $0 <backup_file.sql>"
       exit 1
   fi
   
   echo "Restoring from: $BACKUP_FILE"
   kubectl exec -i -n development deployment/postgres -- psql -U admin devdb < "$BACKUP_FILE"
   echo "Restore complete!"
   EOF

   chmod +x backup-dev-db.sh restore-dev-db.sh
   ```

## ✅ Success Criteria

After completing this session, you should be able to:
- ✅ Configure applications to connect to PostgreSQL securely
- ✅ Implement connection pooling at application and infrastructure levels
- ✅ Create and manage database migrations
- ✅ Set up proper development and testing workflows
- ✅ Integrate PostgreSQL with multiple programming languages
- ✅ Implement database seeding and reset procedures
- ✅ Monitor and optimize database connections

## 🔍 Troubleshooting

### Connection Issues

```bash
# Test connectivity from application pod
kubectl run app-connectivity-test --rm -it --image=postgres:15-alpine --restart=Never -- /bin/bash

# Inside the test pod
psql -h postgres.development.svc.cluster.local -U admin -d devdb -c "SELECT 'Connection works!' as result;"

# Test with different connection parameters
PGCONNECT_TIMEOUT=10 psql -h postgres.development.svc.cluster.local -U admin -d devdb
```

### Application Configuration Issues

```bash
# Check ConfigMap and Secret values
kubectl get configmap app-db-config -n development -o yaml
kubectl get secret app-db-credentials -n development -o yaml

# Decode secret values
kubectl get secret app-db-credentials -n development -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Test environment variables in pod
kubectl run env-test --rm -it --image=alpine --restart=Never --env="DB_HOST=postgres.development.svc.cluster.local" -- env | grep DB
```

### Performance Issues

```sql
-- Monitor connection pool usage
SELECT 
    application_name,
    count(*) as connections,
    max(backend_start) as oldest_connection
FROM pg_stat_activity 
WHERE datname = 'devdb'
GROUP BY application_name;

-- Check for connection leaks
SELECT 
    state,
    count(*) as connection_count,
    max(state_change) as last_state_change
FROM pg_stat_activity 
WHERE datname = 'devdb'
GROUP BY state;

-- Monitor slow queries from applications
SELECT 
    query,
    state,
    now() - query_start as duration
FROM pg_stat_activity 
WHERE datname = 'devdb' 
AND state = 'active'
AND now() - query_start > interval '1 second';
```

## 📚 Next Steps

After completing this integration session:
1. Implement proper logging and monitoring for applications
2. Set up automated testing with database fixtures
3. Configure staging environment with production-like settings
4. Implement database change management workflows
5. Set up performance monitoring and alerting
6. Explore advanced PostgreSQL features (JSONB, full-text search, etc.)

## 🕐 Time Estimate
**Total Duration**: 55 minutes
- Connection configuration: 10 minutes
- Language-specific examples: 15 minutes
- Migration strategies: 8 minutes
- Connection pooling: 12 minutes
- Testing workflows: 10 minutes

## 📝 Notes
- Always use environment variables for database configuration
- Implement proper connection pooling to avoid connection exhaustion
- Test database interactions thoroughly before deploying to production
- Keep migration scripts simple and reversible
- Monitor application database performance regularly
- Use separate databases for different environments (dev, test, prod)

## 🔗 Useful Resources

```bash
# Create development aliases
alias db-connect="kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb"
alias db-reset="./reset-dev-db.sh"
alias db-seed="kubectl exec -n development deployment/postgres -- /usr/local/bin/seed-db.sh"
alias db-backup="./backup-dev-db.sh"
alias db-stats="kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c \"SELECT * FROM pg_stat_activity WHERE datname = 'devdb';\""

# Environment setup function
function setup-db-env() {
    export DB_HOST=postgres.development.svc.cluster.local
    export DB_PORT=5432
    export DB_NAME=devdb
    export DB_USER=admin
    export DB_PASSWORD=1q2w3e4r@123
    echo "Database environment variables set"
}
```
