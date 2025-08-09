# System Upgrade Utility

[한국어 문서 보기](README.kr.md)

## Overview

`system_upgrade.sh` is an automated upgrade script designed to keep your macOS system's packages and applications up to date. This script manages updates for Homebrew, Cask, and the entire system.

## Features

- Automatic Homebrew and Cask updates
- Full system updates via topgrade
- Automatic detection of Homebrew Cask-compatible apps
- Detailed logging system
- Error handling and recovery
- Automatic temporary file management

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

## Safety Features

- System state verification
- Cache integrity checks
- Permission validation
- Error recovery mechanisms
- Automatic rollback for failed updates

## Requirements

- Ruby ≥ 3.2.0
- Homebrew
- macOS 10.15 or later

## Contributing

See [Contributing Guide](../common/CONTRIBUTING.md) for guidelines.

## License

MIT License - see LICENSE file for details.
