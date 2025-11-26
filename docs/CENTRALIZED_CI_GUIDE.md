# Centralized CI/CD System - Complete Guide

**Date**: November 19, 2025  
**Purpose**: Complete guide for the unified CI/CD system using reusable workflows

---

## 🎯 Overview

All FKS microservices now use a **fully centralized CI/CD system** with:
- ✅ Single `ci.yml` file per repo (50-100 lines)
- ✅ All logic in `fks_actions` repo (reusable workflows)
- ✅ Automatic code linting (Python, Rust)
- ✅ Automatic documentation linting
- ✅ Codecov integration for all services
- ✅ Automated config sync from `fks_config` repo
- ✅ Consistent health checks across all services

---

## 📁 Repository Structure

### Actions Repository (`fks_actions`)
**Contains all reusable workflows:**

```
fks_actions/.github/workflows/
├── ci-python-service.yml          # Python service CI (tests, Docker, health checks)
├── ci-rust-service.yml            # Rust service CI (tests, Docker, health checks, coverage)
├── ci-infra-service.yml           # Infrastructure service CI
├── build-docker-base-images.yml   # Docker base image builds
├── docs-lint.yml                  # Documentation linting
├── docs-build.yml                 # Documentation build & deploy
├── docs-audit.yml                 # Documentation audit
├── code-lint.yml                  # Code linting (Python/Rust)
└── config-sync.yml                # Config file sync to services
```

### Individual Service Repos
**Each has ONE simple `ci.yml` file:**

```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-python-service.yml@main
    with:
      service_name: myservice
      service_port: '8000'
      # ... other parameters
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

---

## 🔧 Available Reusable Workflows

### 1. Python Service CI
**File**: `ci-python-service.yml`  
**Use for**: Python-based microservices

**Key Features**:
- Python tests with pytest
- Code coverage with Codecov
- Linting with ruff
- Type checking with mypy
- Docker build and health check
- Automatic image push to Docker Hub

**Parameters**:
```yaml
with:
  service_name: "ai"                    # Required
  service_port: "8007"                  # Required
  python_version: "3.12"                # Optional (default: 3.12)
  healthcheck_enabled: true             # Optional (default: true)
  healthcheck_path: "/health"           # Optional (default: /health)
  healthcheck_retries: 30               # Optional (default: 30)
  has_dev_requirements: true            # Optional (default: true)
  run_mypy: true                        # Optional (default: true)
  dockerfile_path: "./Dockerfile"       # Optional (default: ./Dockerfile)
  cleanup_disk: false                   # Optional (default: false)
secrets:
  docker_token: ${{ secrets.DOCKER_TOKEN }}
  codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

### 2. Rust Service CI
**File**: `ci-rust-service.yml`  
**Use for**: Rust-based microservices

**Key Features**:
- Cargo tests
- Code coverage with cargo-tarpaulin
- Codecov integration
- Clippy linting
- Docker build and health check
- Disk cleanup option

**Parameters**:
```yaml
with:
  service_name: "auth"                  # Required
  service_port: "8009"                  # Required
  rust_toolchain: "stable"              # Optional (default: stable)
  healthcheck_enabled: true             # Optional (default: true)
  needs_openssl: true                   # Optional (default: true)
  dockerfile_path: "./Dockerfile"       # Optional (default: ./Dockerfile)
  cleanup_disk: false                   # Optional (default: false)
  run_coverage: true                    # Optional (default: true)
secrets:
  docker_token: ${{ secrets.DOCKER_TOKEN }}
  codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

### 3. Documentation Workflows

#### Lint Documentation
```yaml
lint:
  uses: nuniesmith/fks_actions/.github/workflows/docs-lint.yml@main
  with:
    docs_path: "**/*.md"
    auto_fix: true
    config_file: ".markdownlint.json"
```

#### Build & Deploy Docs
```yaml
build:
  uses: nuniesmith/fks_actions/.github/workflows/docs-build.yml@main
  with:
    python_version: "3.12"
    mkdocs_config: "mkdocs.yml"
    deploy_to_pages: true
```

#### Audit Documentation
```yaml
audit:
  uses: nuniesmith/fks_actions/.github/workflows/docs-audit.yml@main
  with:
    docs_dir: "docs"
    audit_script: "scripts/docs/audit_files.py"
```

### 4. Code Linting Workflow
**File**: `code-lint.yml`  
**Use for**: Standalone code linting (Python or Rust)

**Parameters**:
```yaml
lint:
  uses: nuniesmith/fks_actions/.github/workflows/code-lint.yml@main
  with:
    language: "python"                  # Required: "python" or "rust"
    source_paths: "src/ tests/"         # Optional (default: src/)
    auto_fix: false                     # Optional (default: false)
    run_mypy: true                      # Python only
```

### 5. Config Sync Workflow
**File**: `config-sync.yml`  
**Use for**: Distributing config files from `fks_config` repo to services

**Parameters**:
```yaml
sync:
  uses: nuniesmith/fks_actions/.github/workflows/config-sync.yml@main
  with:
    config_repo: "nuniesmith/fks_config"
    config_files: "fks-config-base.yaml tracing.yaml"
    target_repos: "fks_ai,fks_api,fks_web"
    target_path: "config/"
    create_pr: true
  secrets:
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

## 📋 Service Configuration Examples

### Python Service (e.g., AI, Analyze, API, Training)
```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-python-service.yml@main
    with:
      service_name: ai
      service_port: '8007'
      python_version: '3.12'
      has_dev_requirements: true
      run_mypy: true
      dockerfile_path: './docker/Dockerfile'
      cleanup_disk: true  # For large ML images
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

### Rust Service (e.g., Auth, Execution, Main, Meta)
```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-rust-service.yml@main
    with:
      service_name: auth
      service_port: '8009'
      rust_toolchain: 'stable'
      needs_openssl: true
      dockerfile_path: './docker/Dockerfile'
      run_coverage: true
      healthcheck_enabled: false  # If no /health endpoint
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

### Service Without Health Check (e.g., Monitor, Web)
```yaml
jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-python-service.yml@main
    with:
      service_name: web
      service_port: '8000'
      healthcheck_enabled: false  # Django needs DB/Redis
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}
```

---

## 🔐 Required Secrets

### Repository Secrets (Set in each service repo)
1. **`DOCKER_TOKEN`** - Docker Hub access token
   - Create at: https://hub.docker.com/settings/security
   - Required for: All services that build Docker images

2. **`CODECOV_TOKEN`** - Codecov upload token
   - Create at: https://codecov.io/gh/nuniesmith/<repo>/settings
   - Optional for public repos, required for private

### Organization Secrets (Set once, shared across all repos)
To avoid duplicating secrets, you can set these at the organization level:
- Go to: https://github.com/organizations/nuniesmith/settings/secrets/actions
- Add `DOCKER_TOKEN` and `CODECOV_TOKEN`
- Grant access to all repositories

---

## 🎨 Health Check Configuration

### When to Enable Health Checks
✅ **Enable** (default) for:
- Services with simple `/health` endpoints
- Stateless services
- Services with no external dependencies at startup

❌ **Disable** for:
- Services requiring database connections (Django, API services with DB)
- Services requiring Redis/cache connections
- Services without `/health` endpoints implemented
- Services connecting to external systems (Prometheus, external APIs)

### Configuration
```yaml
with:
  healthcheck_enabled: false          # Disable health check
  # OR customize:
  healthcheck_enabled: true
  healthcheck_path: "/api/health"     # Custom path
  healthcheck_retries: 60             # More retries for slow starts
  healthcheck_interval_seconds: 5     # Longer intervals
```

---

## 🔄 Config Distribution System

### How It Works
1. Update config files in `fks_config` repo
2. Push to `main` branch
3. Workflow automatically:
   - Clones each target service repo
   - Copies updated config files to `config/` directory
   - Creates PR for review
   - Or directly pushes to `main` (if `create_pr: false`)

### Config Files Synced
- `fks-config-base.yaml` - Base configuration for all services
- `tracing.yaml` - Distributed tracing configuration
- Service-specific configs from `services/` directory
- Shared configs from `shared/` directory

### Manual Trigger
```bash
# Sync to specific repos
gh workflow run sync-configs.yml \
  -f target_repos="fks_ai,fks_api" \
  -f create_pr=true

# Sync to all repos with direct push
gh workflow run sync-configs.yml \
  -f create_pr=false
```

---

## 📊 Codecov Integration

### Viewing Coverage
1. Go to: https://codecov.io/gh/nuniesmith/<repo>
2. View coverage reports by:
   - Service (flags: `ai`, `api`, `auth`, etc.)
   - Pull request
   - Commit
   - Time period

### Coverage Badges
Add to README.md:
```markdown
[![codecov](https://codecov.io/gh/nuniesmith/fks_ai/branch/main/graph/badge.svg)](https://codecov.io/gh/nuniesmith/fks_ai)
```

---

## 🚀 Migration Guide

### For New Services
1. Copy template `ci.yml` from above
2. Update `service_name` and `service_port`
3. Add secrets to repository settings
4. Done! Push to trigger CI

### For Existing Services
1. Replace entire `.github/workflows/` directory with single `ci.yml`
2. Update parameters to match your service
3. Ensure secrets are configured
4. Push and verify CI runs successfully

### Cleanup Old Workflows
After migrating to the unified system, delete these files from service repos:
```bash
rm .github/workflows/build.yml
rm .github/workflows/test.yml
rm .github/workflows/docker.yml
rm .github/workflows/lint.yml
# Keep only ci.yml
```

---

## 🛠️ Troubleshooting

### CI Failing on Disk Space
**Problem**: Docker build fails with "no space left on device"  
**Solution**: Enable disk cleanup
```yaml
with:
  cleanup_disk: true  # Frees ~14GB
```

### Health Check Failing
**Problem**: Service starts but health check times out  
**Solution**: Disable or customize health check
```yaml
with:
  healthcheck_enabled: false
  # OR
  healthcheck_retries: 60
  healthcheck_interval_seconds: 5
```

### Dockerfile Not Found
**Problem**: "failed to read dockerfile: no such file or directory"  
**Solution**: Specify correct path
```yaml
with:
  dockerfile_path: './docker/Dockerfile'  # If in subdirectory
```

### Codecov Upload Failing
**Problem**: Codecov upload fails or token invalid  
**Solution**: Verify token is set correctly
```bash
gh secret set CODECOV_TOKEN --body "your-token-here"
```

---

## 📚 Additional Resources

- **Actions Repo**: https://github.com/nuniesmith/fks_actions
- **Config Repo**: https://github.com/nuniesmith/fks_config
- **Docker Hub**: https://hub.docker.com/u/nuniesmith
- **Codecov**: https://codecov.io/gh/nuniesmith
- **GitHub Actions Docs**: https://docs.github.com/en/actions

---

## 🎯 Benefits Summary

### Before (Per-Service Workflows)
- ❌ 300-500 lines of CI config per repo
- ❌ Duplicate logic across 16 services
- ❌ Changes require updates to 16 repos
- ❌ Inconsistent implementations
- ❌ Difficult to maintain

### After (Centralized System)
- ✅ 50-100 lines of CI config per repo
- ✅ Single source of truth in `fks_actions`
- ✅ Changes apply to all services instantly
- ✅ Consistent behavior everywhere
- ✅ Easy to maintain and extend

---

## 📝 Next Steps

1. **Review** this guide and understand the system
2. **Migrate** remaining services to use reusable workflows
3. **Configure** health checks appropriately for each service
4. **Set up** Codecov tokens for all repositories
5. **Test** config sync workflow with non-critical config
6. **Document** service-specific configurations as needed

---

**Last Updated**: November 19, 2025  
**Maintained By**: DevOps Team
