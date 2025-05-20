# System Cleanup Utility

[한국어 문서 보기](README.kr.md)

## Overview

`system_cleanup.sh` is an automated maintenance script designed to clean up your macOS system, free disk space, and maintain system health. It performs a series of cleanup operations on various parts of your system.

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
- Android Studio file cleanup

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

For more information about the OpenWebUI cleanup feature, see [OpenWebUI Cleanup Documentation](OPENWEBUI.md).

For version history and changes, see [Changelog](CHANGELOG.md).

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

## Security Considerations

- Requires sudo only for system log access
- No system modifications with elevated privileges
- Safe cleanup areas only
- Interactive confirmation for sensitive operations

## Contributing

See [Contributing Guide](../common/CONTRIBUTING.md) for guidelines.

## License

MIT License - see LICENSE file for details.
