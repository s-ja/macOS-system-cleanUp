# OpenWebUI Cleanup Feature

[한국어 문서 보기](OPENWEBUI.kr.md)

## Overview

The OpenWebUI cleanup feature in `system_cleanup.sh` helps you manage disk space used by OpenWebUI, a Docker-based web interface for AI models. This feature allows you to clean cache files, temporary files, and other data that can accumulate over time.

## How It Works

The script detects if you have OpenWebUI installed by:

1. Checking for running Docker containers named "open-webui"
2. Checking for Docker volumes related to OpenWebUI

When OpenWebUI is detected, the script offers several cleanup options:

### Cleanup Options

- **Cache Files**: Removes cache directories that can safely be deleted
- **Temporary Files**: Removes `.temp`, `.tmp`, `.downloading`, and `.part` files
- **Log Files**: Removes log files older than 30 days
- **DeepSeek Model Files**: Option to remove DeepSeek model files if they're no longer needed

### Space Calculation

The script reports:

- Volume size before cleaning
- Volume size after cleaning
- Exact space saved from the cleanup operation

## Usage

### Basic Usage

When running the cleanup script without options, you'll be presented with interactive prompts:

```bash
./src/cleanup/system_cleanup.sh
```

You'll see options for each type of cleanup for OpenWebUI.

### Auto-Clean Mode

To automatically clean all OpenWebUI cache and temporary files:

```bash
./src/cleanup/system_cleanup.sh --auto-clean
```

### Dry Run Mode

To see what would be cleaned without actually removing files:

```bash
./src/cleanup/system_cleanup.sh --dry-run
```

### Skip OpenWebUI Cleanup

OpenWebUI cleanup is part of Docker cleanup. To skip it:

```bash
./src/cleanup/system_cleanup.sh --no-docker
```

## Safety Considerations

- The script preserves conversation history and important settings
- Container restart is optional but recommended to apply changes
- The script uses Docker volume operations for safe access to data
- The script can operate even if the container is not currently running

## Troubleshooting

If you encounter issues with OpenWebUI cleanup:

1. Ensure Docker is running
2. Check that volume name patterns match your installation
3. See the full log file in the `logs` directory for detailed error messages

For more details, see the [Troubleshooting Guide](TROUBLESHOOTING.md).
