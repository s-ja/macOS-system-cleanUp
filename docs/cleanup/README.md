# System Cleanup Utility

[한국어 문서 보기](README.kr.md)

## Overview

`system_cleanup.sh` is an automated maintenance script designed to clean up your macOS system, free disk space, and maintain system health. It performs a series of cleanup operations on various parts of your system with enhanced stability and error recovery features.

## Features

- Disk usage analysis and reporting
- Homebrew package management and cleanup
- npm cache cleanup
- System log size checking
- Docker resource cleanup (optional)
- OpenWebUI container and data volume cleanup
- node_modules directory analysis
- Yarn cache cleanup
- .DS_Store file cleanup
- Android Studio file cleanup with multi-version support
- Enhanced stability with timeout protection
- Error recovery and graceful continuation
- Selective cleanup with skip options

## Quick Start

```bash
# Basic usage
./src/cleanup/system_cleanup.sh

# Auto-clean mode
./src/cleanup/system_cleanup.sh --auto-clean

# Skip specific cleanups
./src/cleanup/system_cleanup.sh --no-brew --no-docker
```

For detailed installation instructions, see [Installation Guide](../common/INSTALLATION.md).

For troubleshooting, see [Troubleshooting Guide](TROUBLESHOOTING.md).

For version history and changes, see [Changelog](CHANGELOG.md).

## Recent Improvements (v3.1)

- **Cross-shell Compatibility**: Works perfectly with both zsh and bash
- **Runtime Shell Detection**: Automatically selects appropriate shell features when running
- **Backward Compatibility**: Existing bash users can continue using without changes
- **Unified UI**: Standardized section headers and dividers across all messages
- **Safe Operations**: Added `safe_remove`, `safe_clear_cache`, and `create_backup` helpers

## Command Line Options

```
--help          Show help message
--auto-clean    Run all cleanup operations without prompts
--dry-run       Show what would be cleaned without cleaning
--no-brew       Skip Homebrew cleanup
--no-npm        Skip npm cache cleanup
--no-docker     Skip Docker cleanup (also skips OpenWebUI cleanup)
--no-android    Skip Android Studio cleanup
```

## Cleanup Features

### OpenWebUI Cleanup

The OpenWebUI cleanup feature helps manage disk space used by OpenWebUI, a Docker-based web interface for AI models. This feature detects OpenWebUI installations by:

1. Checking for running Docker containers named "open-webui"
2. Checking for Docker volumes related to OpenWebUI

#### Cleanup Options

- **Cache Files**: Removes cache directories that can safely be deleted
- **Temporary Files**: Removes `.temp`, `.tmp`, `.downloading`, and `.part` files
- **Log Files**: Removes log files older than 30 days
- **DeepSeek Model Files**: Option to remove DeepSeek model files if they're no longer needed

The script reports volume size before and after cleaning, along with the exact space saved.

#### Safety Considerations

- Preserves conversation history and important settings
- Container restart is optional but recommended to apply changes
- Uses Docker volume operations for safe access to data
- Can operate even if the container is not currently running

## Security Considerations

- Requires sudo only for system log access
- No system modifications with elevated privileges
- Safe cleanup areas only
- Interactive confirmation for sensitive operations

## Contributing

See [Contributing Guide](../common/CONTRIBUTING.md) for guidelines.

## License

MIT License - see LICENSE file for details.
