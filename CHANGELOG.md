# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ✨ ArgoCD GitOps integration with Traefik ingress routing
- 📝 ArgoCD quick start documentation and troubleshooting guide
- 🔧 ArgoCD namespace and RBAC configuration
- 🌐 ArgoCD access via both domain (http://argocd.localhost) and port-forward (http://localhost:8080)
- ✅ ArgoCD service validation in URL verification scripts
- 📋 ArgoCD credentials display in service status scripts

### Changed
- 🔄 Migrated all shell scripts to `/scripts` directory for better organization
- 📝 Updated README.md to reflect new script locations
- 🎯 Enhanced service access documentation with ArgoCD integration
- 🔧 Configured ArgoCD server to run in insecure mode for HTTP access behind Traefik
- 📊 Updated all management scripts to include ArgoCD in service listings

### Removed
- 🗑️ Removed duplicate README files (README-NEW.md, README_NEW.md)
- 🗑️ Removed unused Docker Compose files (docker-compose.full.yml, docker-compose.clean.yml)
- 🧹 Cleaned up duplicate ArgoCD resources from default namespace

### Fixed
- 🐛 Fixed ArgoCD ingress routing configuration
- 🔧 Corrected ArgoCD port forwarding setup in management scripts
- ✅ Updated URL verification script to accept 307 redirects as successful
- 🎯 Fixed hosts file configuration to include argocd.localhost

### Security
- 🔒 Implemented proper ArgoCD RBAC configuration
- 🛡️ Configured ArgoCD with secure secret management

## [1.0.0] - 2025-06-21

### Added
- 🚀 Initial K3s development environment setup
- 🎛️ Traefik ingress controller with dashboard
- 📊 Grafana monitoring dashboards
- 📈 Prometheus metrics collection
- 🔍 Jaeger distributed tracing
- 🗄️ MinIO S3-compatible storage
- 🐄 Rancher Kubernetes management
- 🐘 PostgreSQL database
- 🔴 Redis caching
- 📝 Comprehensive documentation and setup scripts
- 🌐 Domain-based and port-forward access methods
- ✅ Health checks and URL verification tools

[Unreleased]: https://github.com/username/k3s-dev-environment/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/k3s-dev-environment/releases/tag/v1.0.0
