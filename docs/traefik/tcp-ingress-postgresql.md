# TCP Ingress for PostgreSQL

## 📄 Overview

This document provides information about configuring Traefik TCP Ingress to expose PostgreSQL database services.

## 🔗 Implementation Documentation

For the complete implementation details of PostgreSQL TCP Ingress using Traefik, see:

**[PostgreSQL Traefik TCP Ingress Implementation](../postgresql/traefik-tcp-postgres-implementation.md)**

## 🎯 Key Features

- **Direct Database Access**: Connect to PostgreSQL without port-forwarding
- **TCP Load Balancing**: Native TCP protocol support
- **External Accessibility**: Host machine access to cluster databases
- **Production Ready**: Suitable for development and staging environments

## 🔧 Configuration Summary

### EntryPoint Configuration
```yaml
entryPoints:
  postgres:
    address: ":5432"
```

### IngressRouteTCP Resource
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

## 🌐 Access Methods

### Direct Connection
```bash
# PostgreSQL connection via Traefik TCP Ingress
PGPASSWORD="1q2w3e4r@123" psql -h 127.0.0.1 -p 5432 -U admin -d devdb
```

### Application Connection String
```
postgresql://admin:1q2w3e4r@123@127.0.0.1:5432/devdb
```

## 📚 Related Documentation

- **[PostgreSQL Main Documentation](../postgresql/README.md)** - Complete PostgreSQL setup
- **[PostgreSQL Sessions](../postgresql/sessions/)** - Step-by-step guides
- **[Traefik Main Documentation](README.md)** - Traefik configuration overview

## 🔍 Verification

Test TCP connectivity:
```bash
# Test port accessibility
nc -zv 127.0.0.1 5432

# Test PostgreSQL connection
psql -h 127.0.0.1 -p 5432 -U admin -d devdb -c "SELECT version();"
```

For detailed troubleshooting and implementation steps, refer to the [complete implementation documentation](../postgresql/traefik-tcp-postgres-implementation.md).
