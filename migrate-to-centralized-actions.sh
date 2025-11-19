#!/bin/bash
# migrate-to-centralized-actions.sh
# Migrates service repos to use centralized GitHub Actions from fks_actions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Service configurations: name:port:language
PYTHON_SERVICES=(
  "ai:8007:python"
  "analyze:8002:python"
  "api:8000:python"
  "app:8003:python"
  "data:8001:python"
  "monitor:8011:python"
  "ninja:8013:python"
  "portfolio:8010:python"
  "training:8008:python"
  "web:8000:python"
)

RUST_SERVICES=(
  "auth:8009:rust"
  "execution:8005:rust"
  "main:8004:rust"
  "meta:8006:rust"
)

ALL_SERVICES=("${PYTHON_SERVICES[@]}" "${RUST_SERVICES[@]}")

REPO_DIR="${REPO_DIR:-$(pwd)}"

migrate_service() {
  local service_config="$1"
  IFS=':' read -r service port language <<< "$service_config"
  
  local service_path="$REPO_DIR/$service"
  
  if [ ! -d "$service_path" ]; then
    log_warning "Service directory not found: $service_path - skipping"
    return 1
  fi
  
  log_info "Migrating $service ($language, port $port)..."
  
  cd "$service_path"
  
  # Check if .github/workflows exists
  if [ ! -d ".github/workflows" ]; then
    log_warning "$service: No .github/workflows directory - skipping"
    return 1
  fi
  
  # Backup old workflows
  local backup_dir=".github/workflows.backup.$(date +%Y%m%d_%H%M%S)"
  if [ -f ".github/workflows/docker-build-push.yml" ] || [ -f ".github/workflows/tests.yml" ]; then
    log_info "$service: Backing up old workflows to $backup_dir"
    mkdir -p "$backup_dir"
    [ -f ".github/workflows/docker-build-push.yml" ] && mv ".github/workflows/docker-build-push.yml" "$backup_dir/" || true
    [ -f ".github/workflows/tests.yml" ] && mv ".github/workflows/tests.yml" "$backup_dir/" || true
  fi
  
  # Create new unified ci.yml
  if [ "$language" = "python" ]; then
    cat > ".github/workflows/ci.yml" <<EOF
name: CI

on:
  push:
    branches: [main, develop]
    tags:
      - "v*"
  pull_request:
    branches: [main, develop]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-python-service.yml@main
    with:
      service_name: $service
      service_port: '$port'
      python_version: '3.12'
      has_dev_requirements: true
      run_mypy: true
    secrets:
      docker_token: \${{ secrets.DOCKER_TOKEN }}
      codecov_token: \${{ secrets.CODECOV_TOKEN }}
EOF
  elif [ "$language" = "rust" ]; then
    cat > ".github/workflows/ci.yml" <<EOF
name: CI

on:
  push:
    branches: [main, develop]
    tags:
      - "v*"
  pull_request:
    branches: [main, develop]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: nuniesmith/fks_actions/.github/workflows/ci-rust-service.yml@main
    with:
      service_name: $service
      service_port: '$port'
      rust_toolchain: 'stable'
      needs_openssl: true
    secrets:
      docker_token: \${{ secrets.DOCKER_TOKEN }}
EOF
  else
    log_error "$service: Unknown language: $language"
    return 1
  fi
  
  log_success "$service: Created new unified ci.yml"
  
  # Commit changes if in git repo
  if [ -d ".git" ]; then
    git add .github/workflows/ci.yml
    if [ -d "$backup_dir" ]; then
      git add "$backup_dir" 2>/dev/null || true
    fi
    
    if git diff --cached --quiet; then
      log_info "$service: No changes to commit"
    else
      git commit -m "ci: migrate to centralized GitHub Actions from fks_actions

- Use reusable workflows from nuniesmith/fks_actions
- Remove duplicate docker-build-push.yml and tests.yml
- Add concurrency control to prevent duplicate runs
- Backup old workflows to $backup_dir"
      log_success "$service: Changes committed"
    fi
  fi
  
  echo ""
}

main() {
  echo -e "${BLUE}====================================${NC}"
  echo -e "${BLUE}  GitHub Actions Migration Script   ${NC}"
  echo -e "${BLUE}====================================${NC}"
  echo ""
  
  if [ $# -eq 0 ]; then
    log_info "No services specified - migrating all services"
    services_to_migrate=("${ALL_SERVICES[@]}")
  else
    # User specified services
    services_to_migrate=()
    for arg in "$@"; do
      found=false
      for svc_config in "${ALL_SERVICES[@]}"; do
        IFS=':' read -r svc port lang <<< "$svc_config"
        if [ "$svc" = "$arg" ]; then
          services_to_migrate+=("$svc_config")
          found=true
          break
        fi
      done
      if [ "$found" = false ]; then
        log_warning "Service not found: $arg"
      fi
    done
  fi
  
  if [ ${#services_to_migrate[@]} -eq 0 ]; then
    log_error "No services to migrate"
    exit 1
  fi
  
  log_info "Migrating ${#services_to_migrate[@]} services..."
  echo ""
  
  local success_count=0
  local failed_services=()
  
  for svc_config in "${services_to_migrate[@]}"; do
    if migrate_service "$svc_config"; then
      success_count=$((success_count + 1))
    else
      IFS=':' read -r svc _ _ <<< "$svc_config"
      failed_services+=("$svc")
    fi
  done
  
  echo ""
  echo -e "${BLUE}====================================${NC}"
  echo -e "${BLUE}  Migration Summary                 ${NC}"
  echo -e "${BLUE}====================================${NC}"
  log_success "Successfully migrated: $success_count/${#services_to_migrate[@]} services"
  
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed services: ${failed_services[*]}"
  fi
  
  echo ""
  log_info "Next steps:"
  echo "  1. Review the new .github/workflows/ci.yml files"
  echo "  2. Ensure DOCKER_TOKEN secret is set in each repo"
  echo "  3. Push changes: git push origin main"
  echo "  4. Monitor first workflow runs for any issues"
  echo ""
  log_info "Old workflows backed up to .github/workflows.backup.*/"
  log_info "You can delete backups after verifying the new workflows work"
}

main "$@"
