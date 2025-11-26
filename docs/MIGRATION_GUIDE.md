# Quick Migration Guide

## What Was Done

✅ Created centralized GitHub Actions repository: https://github.com/nuniesmith/fks_actions
✅ Two reusable workflows:
  - `ci-python-service.yml` - for Python services
  - `ci-rust-service.yml` - for Rust services
✅ Migration script to automate rollout
✅ Already migrated: `ai` and `auth` services as examples

## How to Migrate Remaining Services

### Option 1: Automated (Recommended)

```bash
cd /path/to/fks/repo
bash ../fks_actions/migrate-to-centralized-actions.sh
```

This will migrate all services automatically.

### Option 2: Specific Services Only

```bash
cd /path/to/fks/repo
bash ../fks_actions/migrate-to-centralized-actions.sh analyze api app data
```

### Option 3: Manual Per Service

1. Navigate to service: `cd repo/<service>`
2. Delete old workflows:
   ```bash
   rm .github/workflows/docker-build-push.yml
   rm .github/workflows/tests.yml
   ```
3. Create `.github/workflows/ci.yml`:

   **For Python services:**
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
         service_name: SERVICE_NAME
         service_port: 'PORT'
       secrets:
         docker_token: ${{ secrets.DOCKER_TOKEN }}
         codecov_token: ${{ secrets.CODECOV_TOKEN }}
   ```

   **For Rust services:**
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
         service_name: SERVICE_NAME
         service_port: 'PORT'
       secrets:
         docker_token: ${{ secrets.DOCKER_TOKEN }}
   ```

4. Commit and push:
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "ci: migrate to centralized GitHub Actions"
   git push
   ```

## Service Port Reference

### Python Services
- ai: 8007
- analyze: 8002
- api: 8000
- app: 8003
- data: 8001
- monitor: 8011
- ninja: 8013
- portfolio: 8010
- training: 8008
- web: 8000

### Rust Services
- auth: 8009
- execution: 8005
- main: 8004
- meta: 8006

## Required Secret

Ensure `DOCKER_TOKEN` secret is set in each repository:
- Go to repo Settings → Secrets and variables → Actions
- Add secret: `DOCKER_TOKEN` (Docker Hub PAT)

Optional: `CODECOV_TOKEN` for private repos

## Benefits

- ✅ No more duplicate workflow runs
- ✅ Single source of truth for CI/CD
- ✅ Easy to update (change once, applies everywhere)
- ✅ Consistent behavior across all services
- ✅ Better caching and faster builds
- ✅ Concurrency control built-in

## Troubleshooting

### Workflow not found
- Ensure fks_actions repo is public, OR
- Grant repo access: Settings → Actions → General → Workflow permissions

### Tests failing
- Check service has `/health` endpoint
- Verify port configuration matches actual service port
- Review Docker build context and Dockerfile location

### Push failing
- Verify `DOCKER_TOKEN` secret is set correctly
- Check Docker Hub credentials are valid
- Ensure repo has push access to nuniesmith/fks

## Rollback

If you need to revert:
```bash
cd repo/<service>
git checkout HEAD~1 -- .github/workflows/
git commit -m "Revert to old workflows"
git push
```

Or restore from backup:
```bash
mv .github/workflows.backup.*/* .github/workflows/
git add .github/workflows/
git commit -m "Restore old workflows"
git push
```
