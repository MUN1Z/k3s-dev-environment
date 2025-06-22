# Git Workflow and Commit Conventions

This project follows gitflow branching strategy and conventional commits with emojis for better readability and automated changelog generation.

## Branch Naming Convention

All branches must follow the gitflow naming pattern:

```
type/branch-name-example
```

### Valid Branch Types
- `feature/` - New features or enhancements
- `bugfix/` - Bug fixes
- `hotfix/` - Critical fixes that need immediate deployment
- `release/` - Release preparation

### Examples
- `feature/add-argocd-integration`
- `bugfix/fix-traefik-routing`
- `hotfix/security-patch`
- `release/v1.2.0`

## Commit Message Convention

All commit messages must follow the conventional commits format with an emoji prefix:

```
🚀 type(scope): description
```

### Commit Types with Recommended Emojis

| Type | Emoji | Description | Changelog Section |
|------|-------|-------------|-------------------|
| `feat` | ✨ | New feature | Added |
| `fix` | 🐛 | Bug fix | Fixed |
| `docs` | 📝 | Documentation changes | Changed |
| `style` | 🎨 | Code style changes | Changed |
| `refactor` | ♻️ | Code refactoring | Changed |
| `perf` | 🚀 | Performance improvements | Changed |
| `test` | ✅ | Adding or updating tests | Changed |
| `chore` | 🔧 | Maintenance tasks | Changed |
| `build` | 👷 | Build system changes | Changed |
| `ci` | 💚 | CI/CD changes | Changed |

### Additional Emojis
- 🗑️ - Remove code or files
- 🔒 - Security improvements
- 🐳 - Docker related changes
- 📱 - Responsive design
- ⚡ - Performance improvements
- 🔥 - Remove code or files
- 💄 - UI/UX improvements

### Commit Message Examples

```bash
✨ feat(argocd): add argocd integration with traefik ingress
🐛 fix(scripts): correct port forwarding setup in setup-port-forwards.sh
📝 docs(readme): update installation instructions with new script locations
🔧 chore(deps): update kubernetes manifests to latest versions
🎨 style(ui): improve dashboard layout and styling
♻️ refactor(core): restructure service deployment configuration
🚀 perf(monitoring): optimize prometheus query performance
✅ test(e2e): add integration tests for service discovery
👷 build(docker): update dockerfile for multi-stage builds
💚 ci(github): add automated testing workflow
```

### Scope Guidelines
- Use lowercase kebab-case
- Common scopes: `argocd`, `traefik`, `grafana`, `scripts`, `docs`, `k8s`, `monitoring`
- Keep scopes concise and meaningful

## Automated Features

### Pre-commit Validation
The pre-commit hook validates:
- ✅ Branch naming follows gitflow convention
- ✅ Commit message follows emoji + conventional commits format

### Automatic Changelog Generation
- 📝 CHANGELOG.md is automatically updated after each commit
- 🏷️ Commits are categorized into: Added, Changed, Removed, Fixed, Security
- 📊 Follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format

### Manual Changelog Update
```bash
./scripts/update-changelog.sh
```

## Workflow Example

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/add-monitoring-alerts
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "✨ feat(monitoring): add prometheus alerting rules"
   ```

3. **Push and create PR:**
   ```bash
   git push origin feature/add-monitoring-alerts
   ```

4. **Merge to main:**
   ```bash
   git checkout main
   git merge feature/add-monitoring-alerts
   git push origin main
   ```

## Release Process

1. **Create release branch:**
   ```bash
   git checkout -b release/v1.2.0
   ```

2. **Update version and finalize changelog:**
   ```bash
   # Update version numbers
   # Finalize CHANGELOG.md
   git commit -m "🔖 chore(release): prepare v1.2.0"
   ```

3. **Merge to main and tag:**
   ```bash
   git checkout main
   git merge release/v1.2.0
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin main --tags
   ```

## Troubleshooting

### Commit Rejected
If your commit is rejected, check:
- Branch name follows `type/branch-name` format
- Commit message has emoji + conventional format
- No syntax errors in commit message

### Fix Branch Name
```bash
git branch -m old-branch-name feature/new-branch-name
```

### Fix Commit Message
```bash
git commit --amend -m "✨ feat(scope): corrected commit message"
```
