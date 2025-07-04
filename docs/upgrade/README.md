# System Upgrade Utility

[한국어 문서 보기](README.kr.md)

## Overview

`system_upgrade.sh` is an automated upgrade script designed to keep your macOS system's packages and applications up to date. This script manages updates for Homebrew, Cask, and the entire system with enhanced stability and error recovery features.

## Features

- Automatic Homebrew and Cask updates
- Full system updates via topgrade
- Automatic detection of Homebrew Cask-compatible apps
- Enhanced Android Studio management (separate from topgrade)
- Detailed logging system
- Improved error handling and recovery
- Automatic temporary file management
- Enhanced permission validation
- Robust directory handling

## Quick Start

```bash
# Basic usage
./src/upgrade/system_upgrade.sh

# Check available updates
./src/upgrade/system_upgrade.sh --check-only

# Skip specific updates
./src/upgrade/system_upgrade.sh --no-cask
```

For detailed installation instructions, see [Installation Guide](../common/INSTALLATION.md).

For troubleshooting, see [Troubleshooting Guide](TROUBLESHOOTING.md).

For version history and changes, see [Changelog](CHANGELOG.md).

## Recent Improvements (v2.6)

- **Enhanced Directory Management**: Improved temporary directory creation with proper permission handling
- **Android Studio Separation**: Android Studio is now managed separately from topgrade for better control
- **Better Error Recovery**: More detailed error messages with specific recovery instructions
- **Code Organization**: Added section dividers and improved code structure for better maintainability
- **Performance Optimization**: Optimized file search and processing logic

## Safety Features

- System state verification
- Cache integrity checks
- Permission validation
- Error recovery mechanisms
- Automatic rollback for failed updates
- Safe temporary directory handling

## Requirements

- Ruby ≥ 3.2.0
- Homebrew
- macOS 10.15 or later

## Contributing

See [Contributing Guide](../common/CONTRIBUTING.md) for guidelines.

## License

MIT License - see LICENSE file for details.
