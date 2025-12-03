# FKS GitHub Actions

CI/CD workflows for building and deploying FKS Trading applications across all platforms.

## Repositories

| Repository | Description | Build Workflow |
|------------|-------------|----------------|
| `fks_clients` | KMP native apps (Android, iOS, Desktop) | `build-android.yml`, `build-ios.yml`, `build-desktop.yml` |
| `fks_web` | SvelteKit web frontend | `build-web.yml` |

## Workflows

### Individual Platform Builds

#### `build-android.yml`
- Builds Android APK (debug + release)
- Runs unit tests
- Uploads artifacts

#### `build-ios.yml`
- Builds iOS framework from shared KMP code
- Archives iOS app (requires Xcode)
- Runs iOS simulator tests

#### `build-desktop.yml`
- Builds for Linux (DEB, RPM)
- Builds for macOS (DMG)
- Builds for Windows (MSI)
- Runs desktop tests

#### `build-web.yml`
- Builds SvelteKit app
- Runs tests and linting
- Deploys to Netlify (preview + production)

### Unified Build

#### `build-all.yml`
Manual workflow to build all platforms and create a release:
1. Runs shared KMP tests
2. Builds Android, iOS, Desktop (all OS), Web in parallel
3. Creates GitHub release with all artifacts

## Setup

### Required Secrets

For `fks_clients` repository:
```
SIGNING_KEY_ALIAS       # Android signing key alias
SIGNING_KEY_PASSWORD    # Android signing key password
SIGNING_STORE_PASSWORD  # Android keystore password
```

For `fks_web` repository:
```
NETLIFY_AUTH_TOKEN      # Netlify authentication token
NETLIFY_SITE_ID         # Netlify site ID
```

### Required Variables

For `fks_web` repository:
```
PUBLIC_API_URL          # API gateway URL
PUBLIC_AUTH_URL         # Auth service URL
PUBLIC_WS_URL           # WebSocket URL
```

## Usage

### Automatic Builds
Workflows trigger automatically on push/PR to relevant paths.

### Manual Release
1. Go to Actions > "Build All Platforms"
2. Click "Run workflow"
3. Enter version number (e.g., "1.0.0")
4. Wait for all builds to complete
5. Review and publish the draft release

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FKS Trading Apps                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Android   │  │     iOS     │  │       Desktop       │  │
│  │    (APK)    │  │ (Framework) │  │ (DEB/RPM/DMG/MSI)   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │              │
│         └────────────────┼─────────────────────┘              │
│                          │                                    │
│                 ┌────────▼────────┐                          │
│                 │  Shared (KMP)   │                          │
│                 │  - API Client   │                          │
│                 │  - ViewModels   │                          │
│                 │  - UI Screens   │                          │
│                 └─────────────────┘                          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  Web (SvelteKit)                     │    │
│  │  - Signal Command Center                             │    │
│  │  - Portfolio Dashboard                               │    │
│  │  - Gamified Tasks                                    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT License - see LICENSE file
