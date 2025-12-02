# FKS Centralized CI/CD Actions

This directory contains reusable GitHub Actions workflows for building and releasing FKS applications.

## Available Workflows

### 1. `build-desktop-app.yml`
Builds Linux desktop applications (Kotlin Multiplatform + Compose Desktop).

**Location**: `.github/workflows/build-desktop-app.yml`

**Inputs:**
- `app_path`: Path to desktop app directory (e.g., `apps/desktop`)
- `package_name`: Package name for artifacts (e.g., `fks-desktop`)
- `gradle_task`: Gradle task to run (default: `:desktopApp:packageReleaseDeb :desktopApp:packageReleaseRpm`)

**Outputs:**
- `deb_file`: Path to .deb package
- `rpm_file`: Path to .rpm package

**Example Usage:**
```yaml
jobs:
  build:
    uses: ../../../infrastructure/actions/.github/workflows/build-desktop-app.yml@main
    with:
      app_path: apps/desktop
      package_name: fks-desktop
      gradle_task: ":desktopApp:packageReleaseDeb :desktopApp:packageReleaseRpm"
```

### 2. `build-android-app.yml`
Builds Android applications (APK and AAB).

**Location**: `.github/workflows/build-android-app.yml`

**Inputs:**
- `app_path`: Path to Android app directory (e.g., `apps/android`)
- `package_name`: Package name for artifacts (e.g., `fks-android`)
- `build_type`: Build type (`debug` or `release`, default: `release`)
- `gradle_task`: Gradle task to run (default: `assembleRelease`)

**Outputs:**
- `apk_file`: Path to APK file
- `aab_file`: Path to AAB file

**Example Usage:**
```yaml
jobs:
  build:
    uses: ../../../infrastructure/actions/.github/workflows/build-android-app.yml@main
    with:
      app_path: apps/android
      package_name: fks-android
      build_type: release
      gradle_task: "assembleRelease bundleRelease"
```

## Using in App Repositories

### Desktop App
The desktop app uses the centralized workflow in `.github/workflows/build-and-release.yml`:

```yaml
name: Build and Release Linux Packages

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    uses: ../../../infrastructure/actions/.github/workflows/build-desktop-app.yml@main
    with:
      app_path: apps/desktop
      package_name: fks-desktop
      
  release:
    needs: build
    uses: ./.github/workflows/create-release.yml
    with:
      package_files: ${{ needs.build.outputs.deb_file }};${{ needs.build.outputs.rpm_file }}
    if: startsWith(github.ref, 'refs/tags/')
```

### Android App
The Android app uses the centralized workflow in `.github/workflows/build-and-release.yml`:

```yaml
name: Build and Release Android App

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    uses: ../../../infrastructure/actions/.github/workflows/build-android-app.yml@main
    with:
      app_path: apps/android
      package_name: fks-android
      
  release:
    needs: build
    uses: ./.github/workflows/create-release.yml
    with:
      package_files: ${{ needs.build.outputs.apk_file }};${{ needs.build.outputs.aab_file }}
    if: startsWith(github.ref, 'refs/tags/')
```

## Notes

- All workflows use JDK 17
- Gradle wrapper is used (must be present in app directory)
- Artifacts are uploaded for 30 days
- Releases are only created on version tags (v*)
- Workflows are located in `.github/workflows/` directory within `infrastructure/actions/`
