# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**macOS System Maintenance Tools** - A collection of Bash-based utilities for maintaining, cleaning, upgrading, and restoring macOS systems. The project emphasizes safety, logging, and user control through comprehensive error handling and optional dry-run modes.

## Core Scripts

### Main Utilities (in `src/`)

1. **system_cleanup.sh** (1318 lines) - System cleanup and cache management
2. **system_upgrade.sh** (376 lines) - Package and application updates
3. **system_restore.sh** (434 lines) - System backup and restore operations
4. **common.sh** (870 lines) - Shared utility library for all scripts

All utilities depend on `common.sh` for logging, error handling, and shared functions.

## Common Commands

### System Cleanup

```bash
# Basic cleanup
./src/system_cleanup.sh

# Selective cleanup (skip specific tools)
./src/system_cleanup.sh --no-brew --no-docker --no-android

# Dry run (preview without executing)
./src/system_cleanup.sh --dry-run

# View help
./src/system_cleanup.sh --help
```

### System Upgrade

```bash
# Standard upgrade
./src/system_upgrade.sh

# View logs
tail -f logs/upgrade_*.log
```

### System Restore

```bash
# Create backup
./src/system_restore.sh --backup

# Restore from backup
./src/system_restore.sh --restore --backup-dir=/path/to/backup

# Dry run restore
./src/system_restore.sh --restore --dry-run
```

### Testing and Validation

```bash
# Lint shell scripts
shellcheck src/*.sh

# Check logs directory permissions
ls -la logs/

# Fix logs permissions (if needed)
sudo chown -R $(whoami):staff logs/
```

## Architecture

### Dependency Structure

```
system_cleanup.sh  ──┐
system_upgrade.sh  ──┼──→ common.sh (shared functions)
system_restore.sh  ──┘
```

### Key Design Patterns

**1. Centralized Logging (`common.sh`)**
- `setup_logging(script_name)` - Initializes logging with permission fallback
- `log_message(msg)` - Standard logging
- `log_info()`, `log_success()`, `log_warning()` - Specialized logging
- `handle_error(msg, exit_on_error)` - Error handling with optional exit

**2. Permission Handling**
- All scripts use `setup_logging()` which automatically handles permission issues
- Falls back to `$HOME/.macos-system-cleanup/logs` if project logs/ directory is inaccessible
- Provides clear error messages with resolution commands

**3. Safety Features**
- Dry-run mode support (`--dry-run`)
- User confirmations for destructive operations
- Comprehensive error recovery
- Timeout handling for potentially hanging operations

### Script Structure Standard

All utility scripts follow this pattern:

```bash
#!/bin/bash
set -e

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Import common functions
source "$SCRIPT_DIR/common.sh"

# Initialize logging (handles permissions automatically)
if ! LOG_FILE=$(setup_logging "script_name"); then
    echo "🛑 FATAL: Logging initialization failed"
    exit 1
fi

# Function definitions
# Main execution
```

## Important Implementation Details

### Logging System

The logging system is the foundation of all scripts:

- **Location**: Primary logs in `logs/`, fallback to `$HOME/.macos-system-cleanup/logs`
- **Format**: `logs/{script}_YYYYMMDD_HHMMSS.log`
- **Permission handling**: Automatic detection and fallback with user guidance

When modifying scripts that previously had custom logging:
1. Remove custom `log_message()` functions
2. Import `common.sh`
3. Use `setup_logging()` before any logging operations
4. Use `handle_error(msg, false)` for non-fatal errors (second param controls exit behavior)

### Error Handling

`handle_error()` signature: `handle_error(error_message, exit_on_error)`
- First param: Error message string
- Second param: `true` to exit, `false` to continue (default: `false`)

Example:
```bash
if ! some_command; then
    handle_error "Command failed" false  # Log and continue
fi
```

### Common Functions in common.sh

**Logging:**
- `setup_logging(script_name)` - Must be called first
- `log_message(msg)`, `log_info(msg)`, `log_success(msg)`, `log_warning(msg)`
- `handle_error(msg, exit_on_error)`

**Utilities:**
- `format_disk_space(bytes)` - Format byte sizes
- `get_free_space(path)` - Get available disk space
- `safe_clear_cache(path, dry_run, max_age_days)` - Safe cache cleanup
- `create_backup(source, backup_dir)` - Create backups

**Backup/Restore:**
- `backup_homebrew_bundle(backup_dir)`
- `backup_npm_globals(backup_dir)`
- `restore_homebrew_bundle(bundle_file)`
- `restore_npm_globals(npm_file)`

## Documentation Structure

```
docs/
├── cleanup/          # System cleanup utility docs
│   ├── README.md, README.kr.md
│   ├── CHANGELOG.md
│   └── TROUBLESHOOTING.md, TROUBLESHOOTING.kr.md
├── upgrade/          # System upgrade utility docs
│   └── (same structure)
├── restore/          # System restore utility docs
│   └── (same structure)
└── common/           # Common documentation
    ├── CONTRIBUTING.md, CONTRIBUTING.kr.md
    ├── INSTALLATION.md, INSTALLATION.kr.md
    └── SECURITY.md, SECURITY.kr.md
```

### Documentation Guidelines (from AGENTS.md)

**Main vs. Detailed Documentation:**
- Root `CHANGELOG.md` - High-level summary only, link to script-specific changelogs
- Script-specific `CHANGELOG.md` - Detailed technical changes
- Always maintain both English and Korean versions

**When adding features:**
1. Update main `CHANGELOG.md` with summary
2. Update script-specific `CHANGELOG.md` with details
3. Update relevant `README.md` files
4. Update `TROUBLESHOOTING.md` if needed

## Commit Message Format

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Scopes:** `cleanup`, `upgrade`, `restore`, `common`, `docs`

**Examples:**
```
feat(cleanup): add timeout handling for Docker operations
fix(upgrade): resolve permission errors in logging system
docs(restore): update backup directory structure documentation
```

**Important:** Separate documentation-only commits from code changes. Use `docs:` type for documentation-only changes.

## Common Issues and Solutions

### Logs Directory Permission Errors

**Symptom:** `tee: Permission denied` when running scripts

**Solution:**
```bash
sudo chown -R $(whoami):staff logs/
```

The scripts now automatically handle this by falling back to `$HOME/.macos-system-cleanup/logs` with a warning.

### Upgrading Scripts to Use common.sh

When refactoring older scripts or fixing permission issues:

1. Add common.sh import after directory setup
2. Replace custom logging with `setup_logging()`
3. Replace custom error handling with `handle_error(msg, false)`
4. Remove duplicate function definitions that exist in common.sh
5. Test dry-run mode if applicable

## Testing Checklist (from AGENTS.md)

Before committing changes:

- [ ] Run `shellcheck src/*.sh` - Fix syntax errors
- [ ] Test script execution with `--dry-run` (if supported)
- [ ] Verify logs are created correctly
- [ ] Check both English and Korean documentation are updated
- [ ] Ensure commit message follows Conventional Commits format
- [ ] Verify no duplicate content across documentation files

## AI Agent Guidelines (from AGENTS.md)

When working on this project:

1. **Prioritize AGENTS.md rules** - This file contains comprehensive workflow guidelines
2. **Check existing architecture** - All scripts follow standard patterns; maintain consistency
3. **Document changes properly** - Update both code and related documentation
4. **Test before committing** - Use shellcheck and dry-run modes
5. **Maintain bilingual docs** - Keep English and Korean versions synchronized
6. **Follow security boundaries** - Always confirm before running sudo operations

## Key Dependencies

- **Homebrew** - Package management
- **shellcheck** - Shell script linting
- **topgrade** (optional) - Used by system_upgrade.sh for comprehensive updates
- **Docker** (optional) - Cleanup supported if installed
- **Android Studio** (optional) - Cleanup supported if installed
