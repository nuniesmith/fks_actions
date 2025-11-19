# FKS Actions - Reusable GitHub Actions Workflows

Centralized GitHub Actions workflows for all FKS microservices.

## Available Workflows

### 1. Python Service CI (`ci-python-service.yml`)

Reusable workflow for Python-based services with the following features:
- Python setup with caching
- Linting (ruff), type checking (mypy), and unit tests (pytest)
- Code coverage reporting to Codecov
- Docker image build and health check testing
- Automatic push to Docker Hub on main/tags

**Usage Example:**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
    tags: ["v*"]
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
      python_version: '3.12'  # optional, defaults to 3.12
      has_dev_requirements: true  # optional, defaults to true
      run_mypy: true  # optional, defaults to true
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
      codecov_token: ${{ secrets.CODECOV_TOKEN }}  # optional
```

### 2. Rust Service CI (`ci-rust-service.yml`)

Reusable workflow for Rust-based services with the following features:
- Rust toolchain setup with caching
- Cargo tests and Clippy linting
- Docker image build and health check testing
- Automatic push to Docker Hub on main/tags

**Usage Example:**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
    tags: ["v*"]
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
      rust_toolchain: 'stable'  # optional, defaults to stable
      needs_openssl: true  # optional, defaults to true
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
```

## Required Secrets

All service repositories must have the following secret configured:

- `DOCKER_TOKEN`: Docker Hub Personal Access Token for pushing images

Optional secrets:
- `CODECOV_TOKEN`: Codecov token for private repositories (not needed for public repos)

## Service Configuration

### Python Services
- ai (port 8007)
- analyze (port 8002)
- api (port 8000)
- app (port 8003)
- data (port 8001)
- monitor (port 8011)
- ninja (port 8013)
- portfolio (port 8010)
- training (port 8008)
- web (port 8000)

### Rust Services
- auth (port 8009)
- execution (port 8005)
- main (port 8004)
- meta (port 8006)

### Infrastructure Services
- nginx (ports 80, 443)
- tailscale (no exposed port)

## Workflow Features

- **Concurrency control**: Prevents duplicate workflow runs
- **Conditional execution**: Tests run on all events; push only happens on main/tags
- **Health checks**: Validates Docker images by starting containers and testing health endpoints
- **Caching**: Speeds up builds with pip/cargo caching
- **Flexible configuration**: Inputs allow customization per service
- **Error handling**: Most test failures are non-blocking to allow image builds

## Migration Guide

To migrate an existing service to use these reusable workflows:

1. **Delete old workflow files** in your service repo:
   - `.github/workflows/docker-build-push.yml`
   - `.github/workflows/tests.yml`

2. **Create a single new workflow** `.github/workflows/ci.yml`:
   ```yaml
   name: CI
   
   on:
     push:
       branches: [main, develop]
       tags: ["v*"]
     pull_request:
       branches: [main, develop]
   
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   
   jobs:
     ci:
       uses: nuniesmith/fks_actions/.github/workflows/ci-python-service.yml@main
       with:
         service_name: YOUR_SERVICE_NAME
         service_port: 'YOUR_PORT'
       secrets:
         docker_token: ${{ secrets.DOCKER_TOKEN }}
   ```

3. **Adjust inputs** based on your service requirements

4. **Ensure secrets are set** in your repository settings

## Benefits

- ✅ Single source of truth for CI/CD logic
- ✅ Easy updates (change once, apply everywhere)
- ✅ Consistent behavior across all services
- ✅ Reduced maintenance burden
- ✅ No duplicate workflow runs
- ✅ Faster builds with proper caching

## Maintenance

To update CI logic for all services:

1. Make changes to the reusable workflows in this repository
2. Push to `main` branch
3. All services using `@main` will automatically use the updated workflows

For testing changes before rolling out:
1. Create a feature branch
2. Update service workflows to use `@your-branch-name`
3. Test thoroughly
4. Merge to `main` when ready

## License

Same as parent FKS project.
