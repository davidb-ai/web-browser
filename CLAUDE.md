# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BrowserOS (formerly Nxtscape) is an open-source agentic browser with AI superpowers, built on Chromium. It focuses on privacy-first AI features that run locally using your own API keys or local models.

## Build Commands

### Prerequisites
- macOS (tested on M4 Max) or Windows
- ~100GB free disk space
- Python 3, Git, Xcode (macOS)
- Chromium source checked out in `build` directory

### Common Build Commands

```bash
# Debug build (faster compilation, includes dev tools)
python build/build.py --config build/config/debug.yaml --chromium-src build

# Release build (optimized, for distribution)
python build/build.py --config build/config/release.yaml --chromium-src build

# Individual build steps
python build/build.py --clean         # Clean build artifacts
python build/build.py --git-setup     # Setup git config
python build/build.py --apply-patches # Apply BrowserOS patches
python build/build.py --build         # Compile Chromium
python build/build.py --sign          # Sign the app (macOS)
python build/build.py --package       # Create installer

# Run the browser (macOS)
out/Default/Nxtscape.app/Contents/MacOS/Nxtscape --use-mock-keychain
```

## Architecture

### Build System
The project uses a custom Python-based build system located in `build/`:
- **build.py**: Main orchestrator using Click CLI framework
- **modules/**: Individual build steps (patches, compile, package, sign)
- **config/**: YAML configurations for debug/release builds
- Platform-specific handling for macOS and Windows

### Patch-Based Customization
BrowserOS customizes Chromium through patches in `patches/nxtscape/`:
- **patches/series**: Lists patch order (28 patches total)
- Patches modify Chromium for AI integration, branding, and features
- Use `git apply` through the build system

### AI Integration
AI features are implemented as Chrome extensions in `resources/files/`:
- **ai_side_panel/**: Main AI agent interface
  - Keyboard shortcut: Cmd+E (Mac) / Ctrl+E (Windows)
  - Uses Chrome Extension APIs: tabs, debugger, sidePanel
- **bug_reporter/**: Bug reporting extension

### Version Management
- Chromium version tracked in `CHROMIUM_VERSION`
- BrowserOS build number: 32
- Combined version: chromium_version + build_number

## Key Development Patterns

1. **Modifying Browser Behavior**: Create patches in `patches/nxtscape/`
2. **AI Features**: Modify extensions in `resources/files/ai_side_panel/`
3. **Build Configuration**: Edit YAML files in `build/config/`
4. **Platform-Specific Code**: Check platform in build scripts

## Important Notes

- No dedicated test framework - relies on Chromium's tests
- No linting configuration - follow existing code style
- Python type checking via Pyright (see pyrightconfig.json)
- Build artifacts go to `out/` directory
- Always test patches against the specific Chromium version