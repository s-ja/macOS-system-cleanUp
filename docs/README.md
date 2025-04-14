# System Cleanup Utility

## Overview

`system_cleanup.sh` is an automated maintenance script designed to clean up your macOS system, free disk space, and maintain system health. It performs a series of cleanup operations on various parts of your system, including package managers, caches, and system logs.

## Features

- Disk usage analysis and reporting
- Homebrew package management and cleanup
- npm cache cleanup
- System log size checking
- Docker resource cleanup (optional)
- node_modules directory analysis and suggestions
- Yarn cache cleanup
- .DS_Store file cleanup
- Android Studio file cleanup
- Detailed logging of all operations
- Interactive options for sensitive operations
- Comprehensive summary reporting

## Installation

### Prerequisites

- macOS operating system
- Bash shell
- Homebrew package manager (for related cleanup functions)
- npm (optional, for JavaScript development cache cleanup)
- Docker (optional, for container cleanup)
- Android Studio (optional, for Android development file cleanup)

### Setup Instructions

1. Download the script to your preferred location:

   ```
   curl -o ~/src/system_cleanup.sh https://your-repository-url/system_cleanup.sh
   ```

   Or simply create the file manually using a text editor.

2. Make the script executable:

   ```
   chmod +x ~/src/system_cleanup.sh
   ```

3. (Optional) Create a symbolic link to make it accessible system-wide:
   ```
   sudo ln -s ~/src/system_cleanup.sh /usr/local/bin/system_cleanup
   ```

## Usage

### Basic Usage

Simply run the script from your terminal:

```
./system_cleanup.sh
```

Or if you created the symbolic link:

```
system_cleanup
```

### Command Line Options

The script supports the following options:

```
  --help          Show this help message
  --auto-clean    Run all cleanup operations without prompts
  --dry-run       Show what would be cleaned without actually cleaning
  --no-brew       Skip Homebrew cleanup
  --no-npm        Skip npm cache cleanup
  --no-docker     Skip Docker cleanup
  --no-android    Skip Android Studio cleanup
```

Example:

```
./system_cleanup.sh --auto-clean --no-docker
```

### Automated Execution

To run the script automatically on a schedule, you can use `crontab`:

1. Open your crontab for editing:

   ```
   crontab -e
   ```

2. Add a line to run the script weekly (e.g., every Sunday at midnight):

   ```
   0 0 * * 0 /path/to/system_cleanup.sh --auto-clean
   ```

3. Optionally add flags to skip certain cleanup tasks:
   ```
   0 0 * * 0 /path/to/system_cleanup.sh --auto-clean --no-android
   ```

## Script Sections Explained

### 1. Logging Setup

- Creates a log directory (`~/logs`) if it doesn't exist
- Generates timestamped log files for each run
- Implements error handling and message logging functions

### 2. Disk Usage Check

- Reports current disk usage at the beginning of the script
- Provides baseline metrics for comparison after cleanup

### 3. Cache Size Check

- Examines `~/Library/Caches` size
- Reports Downloads folder size
- Identifies potential large space consumers

### 4. Homebrew Cleanup

- Updates Homebrew package listings
- Identifies outdated packages
- Checks for unused dependencies
- Cleans up old versions and cache files

### 5. npm Cache Cleanup

- Checks if npm is installed
- Reports cache size before cleaning
- Performs cache cleanup
- Reports space saved after cleaning

### 6. System Log Check

- Reports the size of system log files
- Requires sudo access for complete information

### 7. Docker Cleanup (Optional)

- Checks if Docker is installed
- Reports Docker disk usage
- Offers interactive option to clean up unused Docker resources
- Includes dangling images, stopped containers, and unused networks

### 8. node_modules Directory Cleanup

- Find and report large node_modules directories
- Identify old projects and suggest manual cleanup

### 9. Yarn Cache Cleanup

- Check and clean Yarn cache size
- Report cleanup results

### 10. .DS_Store File Cleanup

- Find and count .DS_Store files
- Provide optional cleanup

### 11. Android Studio File Cleanup

- Check for Android Studio installation
- Clean Gradle caches and SDK temporary files
- Preserve AVD (Android Virtual Device) files
- Analyze build directories and suggest manual cleanup
- Identify outdated SDK packages

### 12. Summary Report

- Reports final disk usage after all cleanup operations
- Provides comparison with initial state
- Suggests additional manual cleanup options

## Log Files

All operations are logged to timestamped files in the `~/logs` directory. The log file contains:

- Timestamp for each operation
- Output from system commands
- Error messages (if any)
- Before and after metrics

The log filename format is: `cleanup_YYYYMMDD_HHMMSS.log`

## Customization Options

### Modifying Cleanup Targets

You can customize which sections of the script run by commenting out sections you don't need:

```bash
# To disable npm cleanup, comment out Section 4:
# log_message "SECTION 4: Cleaning npm cache"
# if command -v npm &>/dev/null; then
# ...
# fi
```

### Adding New Cleanup Tasks

To add a new cleanup task, follow this template:

```bash
# Section X: [New Task Name]
log_message "SECTION X: [New Task Description]"

# Your commands here
your_command_here 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to [description]"

log_message "----------------------------------------"
```

### Changing Log Location

Modify the `LOG_DIR` variable at the top of the script:

```bash
LOG_DIR="/your/preferred/log/directory"
```

## Potential Risks and Considerations

### Risk: Accidental Deletion

The script removes cache files and old versions that may occasionally be needed.

- **Mitigation**: The script avoids removing critical system files and focuses on safe cleanup areas.

### Risk: Docker Data Loss

Cleaning Docker resources can remove containers you might want to keep.

- **Mitigation**: Interactive confirmation is required before Docker cleanup.

### Risk: Sudo Access

The script requires sudo for accessing system logs.

- **Mitigation**: Only the log size check requires sudo; it does not modify system files with elevated privileges.

### Risk: Package Manager Updates

Homebrew updates might occasionally introduce issues.

- **Mitigation**: The script handles errors and continues with the next task if one fails.

### Risk: Android Development Environment

Android Studio cleanup might affect virtual device settings.

- **Mitigation**: The script does not automatically clean AVD files and only removes old caches and temporary files.

## Troubleshooting

### Script Fails with Permission Errors

```
ERROR: Permission denied
```

**Solution**: Ensure the script has execution permissions:

```
chmod +x system_cleanup.sh
```

### Homebrew Update Fails

```
ERROR: Failed to update Homebrew
```

**Solution**: Try running Homebrew update manually to see detailed errors:

```
brew update
```

### Cannot Access System Logs

```
Could not access system logs (sudo may be required)
```

**Solution**: Run the script with sudo or skip this section if you prefer not to use sudo.

### Docker Cleanup Hangs

**Solution**: Press Ctrl+C to skip Docker cleanup and continue with the rest of the script.

## Security Considerations

### Permissions

- The script only requires elevated permissions for reading system logs
- No system modifications are made with sudo privileges

### Data Safety

- Only known cache directories and temporary files are cleaned
- User data directories are not modified
- Interactive confirmation is required for potentially destructive operations (Docker cleanup)

### Log File Security

- Logs are stored in the user's home directory
- Logs do not contain sensitive information but may include system paths

## Contributing

### Reporting Issues

If you encounter any issues or have suggestions for improvements, please submit them to [your issue tracker URL].

### Pull Requests

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This script is released under the MIT License. See the LICENSE file for details.

## Author

[Your Name/Organization]

## Version History

- v1.0 (2023-05-20): Initial release
- v1.1 (2023-05-25): Added Docker cleanup, improved logging
- v1.2 (2023-06-10): Added node_modules and Yarn cache cleanup
- v1.3 (2023-07-15): Added .DS_Store file cleanup feature
- v2.0 (2025-04-14): Added Android Studio cleanup feature, implemented AVD file protection
