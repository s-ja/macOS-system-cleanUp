# System Restore Utility

[한국어 문서 보기](README.kr.md)

## Overview

`system_restore.sh` is a comprehensive system restore utility designed for macOS systems that have been completely formatted and need to restore all applications and settings from a clean state. This utility provides automated backup and restore capabilities for your entire development environment.

## Features

### 🔄 Complete System Backup

- **Homebrew Bundle**: All installed packages and casks
- **npm Global Packages**: Node.js development tools
- **System Settings**: macOS system preferences
- **App Preferences**: Application configurations and settings
- **Android Studio**: Complete development environment backup
- **Backup Summary**: Detailed backup report with restore instructions

### 🚀 Automated System Restore

- **One-Command Restore**: Restore entire system from backup
- **Selective Restoration**: Choose which components to restore
- **Smart Detection**: Automatically find latest backup
- **Error Recovery**: Robust error handling and recovery
- **Progress Tracking**: Real-time restore progress monitoring

### 🛡️ Safety Features

- **Dry Run Mode**: Test operations without making changes
- **Confirmation Prompts**: User verification for critical operations
- **Backup Validation**: Verify backup integrity before restore
- **Conflict Resolution**: Handle existing configurations safely
- **Rollback Support**: Create backups before overwriting

## Use Cases

### Before System Format

```bash
# Create complete system backup
./src/system_restore.sh --backup-only --auto-yes
```

### After System Format

```bash
# Restore entire system from backup
./src/system_restore.sh --restore-only --auto-yes
```

### Selective Restoration

```bash
# Restore only Homebrew packages
./src/system_restore.sh --restore-only --no-npm --no-prefs --no-android

# Restore from specific backup location
./src/system_restore.sh --restore-only --restore-from=/path/to/backup
```

## Quick Start

### 1. System Backup (Before Format)

```bash
# Navigate to project directory
cd /path/to/macos-system-util

# Create complete system backup
./src/system_restore.sh --backup-only

# Or with auto-confirmation
./src/system_restore.sh --backup-only --auto-yes
```

### 2. System Restore (After Format)

```bash
# Restore from latest backup
./src/system_restore.sh --restore-only

# Or restore from specific backup
./src/system_restore.sh --restore-only --restore-from=/path/to/backup
```

### 3. Test Mode

```bash
# Test backup and restore without making changes
./src/system_restore.sh --dry-run
```

## Command Line Options

### Main Operations

- `--backup-only`: Create system backup only
- `--restore-only`: Restore system from backup only
- `--restore-from=DIR`: Specify backup directory for restore

### Backup Options

- `--auto-yes`: Automatically confirm all prompts
- `--dry-run`: Show what would be done without making changes

### Restore Options

- `--no-brew`: Skip Homebrew package restoration
- `--no-npm`: Skip npm global package restoration
- `--no-prefs`: Skip application preferences restoration
- `--no-android`: Skip Android Studio configuration restoration

### General Options

- `--help`: Display help information

## Backup Contents

### Homebrew Bundle

- All installed Homebrew packages
- All installed Homebrew casks
- Package versions and dependencies

### npm Global Packages

- Globally installed npm packages
- Package versions and configurations

### System Settings

- macOS system preferences
- User defaults and configurations

### Application Preferences

- App-specific settings and configurations
- User preferences and customizations

### Android Studio

- Android SDK configurations
- AVD (Android Virtual Device) settings
- Project templates and configurations
- Gradle cache and build settings

## Restore Process

### 1. Pre-Restore Checks

- Verify backup integrity
- Check system requirements
- Confirm user intentions
- Create safety backups

### 2. Component Restoration

- Homebrew packages and casks
- npm global packages
- Application preferences
- Android Studio configurations

### 3. Post-Restore Verification

- Verify restored components
- Check system stability
- Provide next steps guidance

## File Structure

```
~/.macos_utility_backups/
├── full_system_YYYYMMDD_HHMMSS/
│   ├── Brewfile_YYYYMMDD_HHMMSS
│   ├── npm_globals_YYYYMMDD_HHMMSS.txt
│   ├── system_settings_YYYYMMDD_HHMMSS.txt
│   ├── preferences_YYYYMMDD_HHMMSS/
│   ├── android_studio_YYYYMMDD_HHMMSS/
│   └── backup_summary.txt
└── ...
```

## Requirements

### System Requirements

- macOS 10.15 (Catalina) or later
- Bash 4.0 or later
- Administrator privileges for system-level operations

### Dependencies

- Homebrew (for package management)
- Node.js and npm (for npm package restoration)
- Android Studio (for Android development environment)

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/macos-system-util.git
cd macos-system-util
```

### 2. Make Executable

```bash
chmod +x src/system_restore.sh
```

### 3. Verify Installation

```bash
./src/system_restore.sh --help
```

## Examples

### Complete Workflow Example

```bash
# 1. Create backup before system format
./src/system_restore.sh --backup-only --auto-yes

# 2. After system format and fresh macOS install
# Install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Restore entire system
./src/system_restore.sh --restore-only --auto-yes
```

### Selective Restoration Example

```bash
# Restore only development tools
./src/system_restore.sh --restore-only --no-prefs --no-android

# Restore from external backup
./src/system_restore.sh --restore-only --restore-from=/Volumes/External/backup
```

### Testing Example

```bash
# Test backup process
./src/system_restore.sh --backup-only --dry-run

# Test restore process
./src/system_restore.sh --restore-only --dry-run
```

## Troubleshooting

### Common Issues

#### Backup Failures

```bash
# Check permissions
ls -la ~/.macos_utility_backups

# Verify Homebrew status
brew doctor

# Check npm installation
npm --version
```

#### Restore Failures

```bash
# Verify backup integrity
ls -la /path/to/backup

# Check system requirements
brew --version
node --version

# Review logs
tail -f logs/system_restore_*.log
```

#### Permission Issues

```bash
# Fix backup directory permissions
chmod 755 ~/.macos_utility_backups

# Fix script permissions
chmod +x src/system_restore.sh
```

### Recovery Procedures

#### Manual Restoration

If automated restore fails, you can manually restore components:

```bash
# Restore Homebrew packages
brew bundle --file=/path/to/backup/Brewfile_*

# Restore npm packages
cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g

# Restore preferences
cp -R /path/to/backup/preferences_*/* ~/Library/Preferences/
```

#### Backup Verification

```bash
# Check backup contents
ls -la ~/.macos_utility_backups/

# Verify backup summary
cat ~/.macos_utility_backups/full_system_*/backup_summary.txt
```

## Best Practices

### Before System Format

1. **Create Complete Backup**: Use `--backup-only` to create comprehensive backup
2. **Verify Backup**: Check backup contents and summary
3. **Test Restore**: Use `--dry-run` to verify backup integrity
4. **Store Safely**: Keep backup in safe location (external drive, cloud)

### During System Format

1. **Fresh macOS Install**: Install clean macOS version
2. **Install Prerequisites**: Install Homebrew and Node.js if needed
3. **Verify System**: Ensure system is stable before restore

### After System Format

1. **Verify Requirements**: Check all dependencies are available
2. **Run Restore**: Use `--restore-only` to restore system
3. **Verify Restoration**: Check all components are working
4. **Test Applications**: Verify apps and tools function correctly

## Security Considerations

### Data Protection

- Backups contain sensitive configuration data
- Store backups in secure, encrypted locations
- Use strong authentication for cloud storage
- Regularly rotate backup encryption keys

### System Security

- Verify backup sources before restoration
- Use `--dry-run` to preview changes
- Review restored configurations for security
- Update passwords and keys after restore

## Support

### Getting Help

- Check logs in `~/logs` directory
- Use `--help` for command options
- Review troubleshooting section
- Open issue with detailed error information

### Contributing

- Report bugs and feature requests
- Submit pull requests for improvements
- Test on different macOS versions
- Share use cases and workflows

## Changelog

### v1.0 (2025-01-XX)

- Initial release
- Complete system backup and restore
- Homebrew, npm, and app preference support
- Android Studio configuration backup
- Comprehensive error handling and logging

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

For detailed installation instructions, see [Installation Guide](../common/INSTALLATION.md).

For troubleshooting, see [Troubleshooting Guide](TROUBLESHOOTING.md).

For version history and changes, see [Changelog](CHANGELOG.md).
