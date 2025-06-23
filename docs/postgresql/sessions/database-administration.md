# PostgreSQL Database Administration Session

## 🎯 Objective

Learn advanced PostgreSQL administration tasks in the K3s environment including user management, backup strategies, performance monitoring, and maintenance operations.

## 📋 Prerequisites

- Completed PostgreSQL Quick Start Session
- PostgreSQL service is running
- kubectl CLI access
- Basic understanding of PostgreSQL administration
- Port-forward setup (optional for external tools)

## 🚀 Session Steps

### Step 1: User and Permission Management (8 minutes)

#### Creating Application Users

1. **Connect to PostgreSQL as admin**:
   ```bash
   kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb
   ```

2. **Create application-specific users**:
   ```sql
   -- Create read-write application user
   CREATE USER app_user WITH PASSWORD 'app_secure_pass_123';
   GRANT CONNECT ON DATABASE devdb TO app_user;
   GRANT USAGE ON SCHEMA public TO app_user;
   GRANT CREATE ON SCHEMA public TO app_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

   -- Create read-only user for reporting
   CREATE USER readonly_user WITH PASSWORD 'readonly_pass_123';
   GRANT CONNECT ON DATABASE devdb TO readonly_user;
   GRANT USAGE ON SCHEMA public TO readonly_user;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

   -- Create monitoring user
   CREATE USER monitor_user WITH PASSWORD 'monitor_pass_123';
   GRANT CONNECT ON DATABASE devdb TO monitor_user;
   GRANT SELECT ON pg_stat_database, pg_stat_activity TO monitor_user;
   ```

3. **Set default privileges for future tables**:
   ```sql
   -- For app_user
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
   GRANT USAGE, SELECT ON SEQUENCES TO app_user;

   -- For readonly_user
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
   GRANT SELECT ON TABLES TO readonly_user;
   ```

4. **Verify user permissions**:
   ```sql
   -- List all users
   \du

   -- Check specific user privileges
   \z
   
   -- Test user connection
   \c devdb app_user
   SELECT current_user, current_database();
   \c devdb admin
   ```

#### Schema Management

5. **Create application schemas**:
   ```sql
   -- Create dedicated schemas
   CREATE SCHEMA app_data;
   CREATE SCHEMA audit_log;
   CREATE SCHEMA reporting;

   -- Grant schema permissions
   GRANT ALL ON SCHEMA app_data TO app_user;
   GRANT USAGE ON SCHEMA app_data TO readonly_user;
   GRANT USAGE ON SCHEMA audit_log TO readonly_user;
   GRANT ALL ON SCHEMA reporting TO readonly_user;

   -- Set search path for app_user
   ALTER USER app_user SET search_path TO app_data, public;
   ```

### Step 2: Database Backup and Restore (10 minutes)

#### Backup Strategies

1. **Create backup directory on host** (external terminal):
   ```bash
   # Create local backup directory
   mkdir -p ~/postgres-backups
   ```

2. **Logical backup with pg_dump**:
   ```bash
   # Full database backup
   kubectl exec -n development deployment/postgres -- pg_dump -U admin devdb > ~/postgres-backups/devdb_full_$(date +%Y%m%d_%H%M%S).sql

   # Compressed backup
   kubectl exec -n development deployment/postgres -- pg_dump -U admin -Fc devdb > ~/postgres-backups/devdb_compressed_$(date +%Y%m%d_%H%M%S).dump

   # Schema-only backup
   kubectl exec -n development deployment/postgres -- pg_dump -U admin -s devdb > ~/postgres-backups/devdb_schema_$(date +%Y%m%d_%H%M%S).sql

   # Data-only backup
   kubectl exec -n development deployment/postgres -- pg_dump -U admin -a devdb > ~/postgres-backups/devdb_data_$(date +%Y%m%d_%H%M%S).sql

   # Specific table backup
   kubectl exec -n development deployment/postgres -- pg_dump -U admin -t users devdb > ~/postgres-backups/users_table_$(date +%Y%m%d_%H%M%S).sql
   ```

3. **All databases backup**:
   ```bash
   # Backup all databases (includes users and roles)
   kubectl exec -n development deployment/postgres -- pg_dumpall -U admin > ~/postgres-backups/all_databases_$(date +%Y%m%d_%H%M%S).sql
   ```

#### Restore Operations

4. **Test restore procedures**:
   ```sql
   -- Create test database for restore testing
   CREATE DATABASE test_restore;
   ```

   ```bash
   # Restore to test database
   kubectl exec -i -n development deployment/postgres -- psql -U admin test_restore < ~/postgres-backups/devdb_full_*.sql

   # Restore from compressed backup
   kubectl exec -i -n development deployment/postgres -- pg_restore -U admin -d test_restore ~/postgres-backups/devdb_compressed_*.dump
   ```

5. **Point-in-time recovery simulation**:
   ```sql
   -- Connect and create test data
   \c test_restore
   CREATE TABLE backup_test (id SERIAL, data TEXT, created_at TIMESTAMP DEFAULT NOW());
   INSERT INTO backup_test (data) VALUES ('Before backup'), ('Critical data');
   SELECT * FROM backup_test;
   ```

#### Automated Backup Setup

6. **Create backup script**:
   ```bash
   # Inside PostgreSQL pod
   kubectl exec -it -n development deployment/postgres -- /bin/bash

   # Create backup script
   cat > /usr/local/bin/backup-db.sh << 'EOF'
   #!/bin/bash
   BACKUP_DIR="/var/lib/postgresql/backups"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   
   mkdir -p $BACKUP_DIR
   
   # Full backup
   pg_dump -U admin devdb | gzip > $BACKUP_DIR/devdb_$TIMESTAMP.sql.gz
   
   # Keep only last 7 days
   find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
   
   echo "Backup completed: devdb_$TIMESTAMP.sql.gz"
   EOF

   chmod +x /usr/local/bin/backup-db.sh
   exit
   ```

### Step 3: Performance Monitoring and Tuning (12 minutes)

#### Database Statistics and Monitoring

1. **Enable query statistics**:
   ```sql
   -- Check if pg_stat_statements is available
   SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';

   -- Enable extension (may require superuser)
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
   ```

2. **Current activity monitoring**:
   ```sql
   -- Active connections
   SELECT 
       pid,
       usename,
       application_name,
       client_addr,
       backend_start,
       state,
       query
   FROM pg_stat_activity 
   WHERE state = 'active';

   -- Connection summary by database
   SELECT 
       datname,
       count(*) as connections,
       max(backend_start) as oldest_connection
   FROM pg_stat_activity 
   GROUP BY datname
   ORDER BY connections DESC;

   -- Long running queries
   SELECT 
       pid,
       now() - pg_stat_activity.query_start AS duration,
       query,
       state
   FROM pg_stat_activity 
   WHERE (now() - pg_stat_activity.query_start) > interval '30 seconds'
   AND state = 'active';
   ```

3. **Database size and space usage**:
   ```sql
   -- Database sizes
   SELECT 
       datname as database_name,
       pg_size_pretty(pg_database_size(datname)) as size
   FROM pg_database 
   WHERE datistemplate = false
   ORDER BY pg_database_size(datname) DESC;

   -- Table sizes in current database
   SELECT 
       schemaname,
       tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
       pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
   FROM pg_tables 
   WHERE schemaname = 'public'
   ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

   -- Index usage statistics
   SELECT 
       schemaname,
       tablename,
       indexname,
       idx_tup_read,
       idx_tup_fetch,
       idx_scan
   FROM pg_stat_user_indexes
   ORDER BY idx_scan DESC;
   ```

#### Performance Analysis

4. **Query performance analysis**:
   ```sql
   -- Top slow queries (if pg_stat_statements is enabled)
   SELECT 
       substring(query, 1, 50) as query_snippet,
       calls,
       total_time,
       mean_time,
       stddev_time,
       rows
   FROM pg_stat_statements
   WHERE calls > 5
   ORDER BY mean_time DESC
   LIMIT 10;

   -- Most frequent queries
   SELECT 
       substring(query, 1, 50) as query_snippet,
       calls,
       total_time,
       mean_time
   FROM pg_stat_statements
   ORDER BY calls DESC
   LIMIT 10;

   -- Cache hit ratio
   SELECT 
       datname,
       round(blks_hit::float/(blks_hit + blks_read) * 100, 2) as cache_hit_ratio
   FROM pg_stat_database
   WHERE datname = 'devdb';
   ```

5. **Lock monitoring**:
   ```sql
   -- Current locks
   SELECT 
       l.locktype,
       l.database,
       l.relation::regclass,
       l.transactionid,
       l.mode,
       l.granted,
       a.query
   FROM pg_locks l
   LEFT JOIN pg_stat_activity a ON l.pid = a.pid
   WHERE NOT l.granted;

   -- Lock conflicts
   SELECT 
       blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement
   FROM pg_catalog.pg_locks blocked_locks
   JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
   JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
   JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.granted;
   ```

#### Configuration Optimization

6. **Check current configuration**:
   ```sql
   -- Important configuration parameters
   SELECT name, setting, unit, short_desc 
   FROM pg_settings 
   WHERE name IN (
       'max_connections',
       'shared_buffers',
       'effective_cache_size',
       'work_mem',
       'maintenance_work_mem',
       'checkpoint_completion_target',
       'wal_buffers',
       'default_statistics_target'
   );

   -- Memory settings
   SELECT 
       name,
       setting,
       unit,
       pg_size_pretty(setting::bigint * 
           CASE unit 
               WHEN 'kB' THEN 1024
               WHEN 'MB' THEN 1024*1024
               WHEN 'GB' THEN 1024*1024*1024
               ELSE 1
           END) as size
   FROM pg_settings 
   WHERE name LIKE '%mem%' OR name LIKE '%buffer%';
   ```

### Step 4: Maintenance Operations (8 minutes)

#### Vacuum and Analyze

1. **Manual vacuum operations**:
   ```sql
   -- Check table bloat
   SELECT 
       schemaname,
       tablename,
       n_dead_tup,
       n_live_tup,
       round(n_dead_tup::float/(n_live_tup + n_dead_tup)*100, 2) as dead_tuple_percent
   FROM pg_stat_user_tables
   WHERE n_live_tup > 0
   ORDER BY dead_tuple_percent DESC;

   -- Vacuum specific table
   VACUUM VERBOSE users;

   -- Vacuum and analyze
   VACUUM ANALYZE users;

   -- Full vacuum (use carefully, locks table)
   VACUUM FULL users;

   -- Analyze all tables
   ANALYZE;
   ```

2. **Autovacuum monitoring**:
   ```sql
   -- Autovacuum settings
   SELECT 
       schemaname,
       tablename,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       last_autoanalyze,
       vacuum_count,
       autovacuum_count
   FROM pg_stat_user_tables;

   -- Autovacuum configuration
   SHOW autovacuum;
   SHOW autovacuum_naptime;
   SHOW autovacuum_vacuum_threshold;
   ```

#### Index Maintenance

3. **Index analysis and maintenance**:
   ```sql
   -- Unused indexes
   SELECT 
       schemaname,
       tablename,
       indexname,
       idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) as size
   FROM pg_stat_user_indexes
   WHERE idx_scan = 0
   AND schemaname = 'public';

   -- Index bloat estimation
   SELECT 
       schemaname,
       tablename,
       indexname,
       pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
       idx_scan
   FROM pg_stat_user_indexes
   ORDER BY pg_relation_size(indexrelid) DESC;

   -- Reindex if needed
   REINDEX INDEX users_email_idx;
   REINDEX TABLE users;
   ```

#### Database Health Checks

4. **Comprehensive health check**:
   ```sql
   -- Transaction ID wraparound check
   SELECT 
       datname,
       age(datfrozenxid) as transaction_age,
       2147483648 - age(datfrozenxid) as transactions_until_wraparound
   FROM pg_database
   WHERE datallowconn;

   -- Database connectivity test
   SELECT 'Database connection OK' as status;

   -- Check for corrupted indexes
   -- (This would typically be done with REINDEX CONCURRENTLY in production)
   ```

### Step 5: Security Audit and Hardening (5 minutes)

#### Security Assessment

1. **User and privilege audit**:
   ```sql
   -- List all users and their attributes
   SELECT 
       rolname,
       rolsuper,
       rolinherit,
       rolcreaterole,
       rolcreatedb,
       rolcanlogin,
       rolconnlimit,
       rolvaliduntil
   FROM pg_roles
   ORDER BY rolname;

   -- Database privileges
   SELECT 
       datname,
       datacl
   FROM pg_database
   WHERE datname = 'devdb';

   -- Table privileges for specific user
   SELECT 
       schemaname,
       tablename,
       tableowner,
       hasselect,
       hasinsert,
       hasupdate,
       hasdelete
   FROM pg_stat_user_tables;
   ```

2. **Connection security check**:
   ```bash
   # Check authentication configuration
   kubectl exec -n development deployment/postgres -- cat /var/lib/postgresql/data/pg_hba.conf

   # Check PostgreSQL configuration
   kubectl exec -n development deployment/postgres -- cat /var/lib/postgresql/data/postgresql.conf | grep -E "(ssl|auth|password)"
   ```

3. **Security recommendations**:
   ```sql
   -- Remove default public schema privileges
   REVOKE CREATE ON SCHEMA public FROM PUBLIC;
   REVOKE ALL ON DATABASE devdb FROM PUBLIC;

   -- Create security monitoring view
   CREATE OR REPLACE VIEW security_audit AS
   SELECT 
       rolname,
       rolsuper,
       rolcreaterole,
       rolcreatedb,
       rolcanlogin,
       rolconnlimit
   FROM pg_roles
   WHERE rolcanlogin = true;

   SELECT * FROM security_audit;
   ```

## ✅ Success Criteria

After completing this session, you should be able to:
- ✅ Create and manage database users with appropriate privileges
- ✅ Perform database backups and restores
- ✅ Monitor database performance and identify bottlenecks
- ✅ Execute maintenance operations (vacuum, analyze, reindex)
- ✅ Conduct security audits and implement basic hardening
- ✅ Set up automated backup procedures
- ✅ Interpret database statistics and metrics

## 🔍 Troubleshooting

### Performance Issues

```sql
-- Identify slow queries
SELECT 
    query,
    state,
    now() - query_start as duration
FROM pg_stat_activity 
WHERE state != 'idle' 
AND query_start < now() - interval '5 minutes';

-- Kill long-running query
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <problematic_pid>;

-- Check for lock waits
SELECT 
    waiting.query as waiting_query,
    blocking.query as blocking_query
FROM pg_stat_activity waiting
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(waiting.pid))
WHERE waiting.state = 'active';
```

### Storage Issues

```bash
# Check disk usage in pod
kubectl exec -n development deployment/postgres -- df -h /var/lib/postgresql/data

# Check PVC status
kubectl describe pvc -n development postgres-pvc

# Monitor storage usage
kubectl exec -n development deployment/postgres -- du -sh /var/lib/postgresql/data/*
```

### Connection Issues

```sql
-- Check connection limits
SHOW max_connections;
SELECT count(*) FROM pg_stat_activity;

-- Identify connection sources
SELECT 
    client_addr,
    count(*) as connections,
    max(backend_start) as oldest_connection
FROM pg_stat_activity 
WHERE client_addr IS NOT NULL
GROUP BY client_addr
ORDER BY connections DESC;
```

## 📚 Next Steps

After completing this administration session:
1. Set up automated monitoring with Prometheus
2. Configure log aggregation
3. Implement connection pooling (PgBouncer)
4. Plan for high availability setup
5. Create disaster recovery procedures
6. Explore advanced security features

## 🕐 Time Estimate
**Total Duration**: 43 minutes
- User and permission management: 8 minutes
- Backup and restore: 10 minutes
- Performance monitoring: 12 minutes
- Maintenance operations: 8 minutes
- Security audit: 5 minutes

## 📝 Notes
- Always test backup and restore procedures in non-production environments
- Monitor performance trends over time to identify patterns
- Regular maintenance should be scheduled during low-traffic periods
- Keep security practices current with PostgreSQL recommendations
- Document all custom configurations and procedures

## 🔗 Useful Scripts

```bash
# Create aliases for common operations
alias pgadmin="kubectl exec -it -n development deployment/postgres -- psql -U admin -d devdb"
alias pgbackup="kubectl exec -n development deployment/postgres -- pg_dump -U admin devdb"
alias pgstats="kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c \"SELECT * FROM pg_stat_activity WHERE state = 'active';\""
alias pgsize="kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c \"SELECT pg_size_pretty(pg_database_size('devdb'));\""

# Monitoring script
function pg-health() {
    echo "=== PostgreSQL Health Check ==="
    kubectl exec -n development deployment/postgres -- pg_isready -U admin
    kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
    kubectl exec -n development deployment/postgres -- psql -U admin -d devdb -c "SELECT pg_size_pretty(pg_database_size('devdb')) as database_size;"
}
```
