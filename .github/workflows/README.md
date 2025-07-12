# GitHub Actions Workflows

This directory contains GitHub Actions workflows for BrowserOS development and CI/CD.

## Workflows

### 1. `copilot-setup-steps.yml` - Reusable Development Environment Setup

A reusable workflow that sets up the BrowserOS development environment. This workflow:
- Installs Python dependencies
- Sets up platform-specific tools (Xcode on macOS, Visual Studio on Windows)
- Installs and configures Chromium's depot_tools
- Optionally checks out Chromium source code
- Caches dependencies for faster subsequent runs

**Usage:**
```yaml
jobs:
  setup:
    uses: ./.github/workflows/copilot-setup-steps.yml
    with:
      platform: 'macos'  # or 'windows' or 'auto' for both
      python-version: '3.12'
      checkout-chromium: true  # Set to false for lightweight CI
      chromium-cache-key: 'my-chromium-cache'
```

### 2. `build.yml` - Full Build Workflow

Performs a complete build of BrowserOS:
- Uses the setup workflow to prepare the environment
- Applies BrowserOS patches to Chromium
- Builds debug or release versions
- Packages the final application
- Uploads build artifacts

**Triggers:**
- Push to main/develop branches
- Pull requests to main
- Manual workflow dispatch with build type and platform selection

### 3. `ci.yml` - Continuous Integration

Lightweight CI checks that run on every push and PR:
- Python type checking with Pyright
- Code linting (Ruff)
- Patch file validation
- Build configuration validation
- Security scanning for secrets
- Chrome extension manifest validation

This workflow doesn't require Chromium checkout, making it fast for PR validation.

### 4. `release.yml` - Automated Release

Creates releases when version tags are pushed:
- Triggers on tags matching `v*.*.*` (e.g., v1.0.0, v2.1.3-beta)
- Builds release versions for macOS and Windows
- Signs and notarizes applications
- Creates installers (DMG for macOS, MSI for Windows)
- Generates checksums (SHA256, MD5)
- Creates draft GitHub release with artifacts
- Optionally uploads to Google Cloud Storage
- Sends Slack notifications

**Usage:**
```bash
# Create and push a release tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 5. `update-appcast.yml` - Auto-Update Manifest

Updates auto-update manifests when releases are published:
- Triggers when a GitHub release is published (not draft)
- Updates `appcast.xml` for macOS Sparkle updates
- Updates `windows-updates.json` for Windows updates
- Commits changes back to the repository
- Optionally syncs to update server

This enables automatic updates for users running BrowserOS.

## Local Development

To use these workflows locally with [act](https://github.com/nektos/act):

```bash
# Run CI checks
act push -W .github/workflows/ci.yml

# Run full build (requires significant resources)
act workflow_dispatch -W .github/workflows/build.yml -e event.json
```

Example `event.json`:
```json
{
  "inputs": {
    "build-type": "debug",
    "platform": "macos"
  }
}
```

## Caching Strategy

The workflows implement comprehensive caching to dramatically reduce build times:

### 1. **Source Code Caching**
- **depot_tools**: Cached based on OS and workflow file hash
- **Chromium source**: Cached based on OS and version in CHROMIUM_VERSION
- **Python dependencies**: Cached based on requirements.txt hash

### 2. **Build Artifacts Caching**
- **Build outputs**: The `out/` directory is cached based on:
  - Operating system
  - Build type (debug/release)
  - Chromium version
  - Patch files hash
  - Build configuration hash
- This means unchanged code results in near-instant builds

### 3. **Compiler Caching**
- **ccache** (Linux/macOS): Caches individual compilation units
  - 10GB cache size limit
  - Compressed storage for efficiency
  - Shared across builds of the same type
- **sccache** (Windows): Mozilla's distributed compiler cache
  - Similar benefits to ccache
  - Optimized for MSVC compiler

### Build Time Improvements
With proper caching:
- **First build**: ~3 hours (full compilation)
- **Subsequent builds** (no changes): ~5 minutes (cache restoration)
- **Incremental builds** (small changes): ~15-30 minutes (partial recompilation)

## Environment Variables

For release builds, set these secrets in your GitHub repository:
- `MACOS_CERTIFICATE_NAME`: macOS code signing certificate
- `PROD_MACOS_NOTARIZATION_APPLE_ID`: Apple ID for notarization
- `PROD_MACOS_NOTARIZATION_TEAM_ID`: Apple Developer Team ID
- `PROD_MACOS_NOTARIZATION_PWD`: App-specific password for notarization
- `WINDOWS_CERTIFICATE_NAME`: Windows code signing certificate (optional)

## Troubleshooting

1. **Chromium checkout fails**: Ensure you have enough disk space (100GB+) and stable internet
2. **Build fails on Windows**: Check that Visual Studio 2022 is properly installed
3. **Cache misses**: Clear caches in GitHub Actions settings if builds are failing
4. **Patch conflicts**: Ensure patches are rebased against the version in CHROMIUM_VERSION