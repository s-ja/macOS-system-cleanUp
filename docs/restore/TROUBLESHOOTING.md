# Troubleshooting Guide - System Restore Utility

[한국어 문서 보기](TROUBLESHOOTING.kr.md)

## Common Issues

### Backup Failures

#### Permission Errors

```bash
ERROR: Permission denied when creating backup directory
```

**Solutions**:

1. Check backup directory permissions:
   ```bash
   ls -la ~/.macos_utility_backups
   ```
2. Create backup directory with proper permissions:
   ```bash
   mkdir -p ~/.macos_utility_backups
   chmod 755 ~/.macos_utility_backups
   ```
3. Check disk space:
   ```bash
   df -h ~
   ```

#### Homebrew Backup Issues

```bash
ERROR: Failed to create Homebrew bundle
```

**Solutions**:

1. Check Homebrew status:
   ```bash
   brew doctor
   ```
2. Verify Homebrew installation:
   ```bash
   brew --version
   ```
3. Try manual bundle creation:
   ```bash
   brew bundle dump --file=~/test_bundle
   ```

#### npm Backup Issues

```bash
ERROR: Failed to list npm global packages
```

**Solutions**:

1. Check npm installation:
   ```bash
   npm --version
   ```
2. Verify npm global packages:
   ```bash
   npm list -g --depth=0
   ```
3. Check npm permissions:
   ```bash
   npm config get prefix
   ```

### Restore Failures

#### Backup Integrity Issues

```bash
ERROR: Backup file is corrupted or incomplete
```

**Solutions**:

1. Verify backup contents:
   ```bash
   ls -la /path/to/backup
   ```
2. Check backup summary:
   ```bash
   cat /path/to/backup/backup_summary.txt
   ```
3. Validate backup structure:
   ```bash
   find /path/to/backup -type f -name "*.txt" -o -name "*.plist"
   ```

#### Homebrew Restore Issues

```bash
ERROR: Failed to restore Homebrew packages
```

**Solutions**:

1. Check Homebrew installation:
   ```bash
   brew --version
   ```
2. Verify Brewfile integrity:
   ```bash
   head -10 /path/to/backup/Brewfile_*
   ```
3. Try manual restoration:
   ```bash
   brew bundle --file=/path/to/backup/Brewfile_*
   ```

#### npm Restore Issues

```bash
ERROR: Failed to restore npm packages
```

**Solutions**:

1. Check Node.js and npm:
   ```bash
   node --version
   npm --version
   ```
2. Verify package list:
   ```bash
   cat /path/to/backup/npm_globals_*
   ```
3. Try manual restoration:
   ```bash
   cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g
   ```

### Permission Issues

#### System Preferences Access

```bash
ERROR: Cannot access system preferences
```

**Solutions**:

1. Check directory permissions:
   ```bash
   ls -la ~/Library/Preferences
   ```
2. Verify ownership:
   ```bash
   ls -la ~/Library/Preferences | head -5
   ```
3. Fix permissions if needed:
   ```bash
   sudo chown -R $(whoami) ~/Library/Preferences
   ```

#### Android Studio Configuration

```bash
ERROR: Cannot access Android Studio configuration
```

**Solutions**:

1. Check Android Studio installation:
   ```bash
   ls -la /Applications/Android\ Studio.app
   ```
2. Verify configuration directory:
   ```bash
   ls -la ~/.android
   ls -la ~/Library/Android
   ```
3. Check file permissions:
   ```bash
   find ~/.android -type f -exec ls -la {} \;
   ```

## Recovery Procedures

### Manual Backup Verification

```bash
# Check backup directory structure
ls -la ~/.macos_utility_backups/

# Verify latest backup
ls -la ~/.macos_utility_backups/ | grep "full_system" | tail -1

# Check backup contents
ls -la ~/.macos_utility_backups/full_system_*/

# Verify backup summary
cat ~/.macos_utility_backups/full_system_*/backup_summary.txt
```

### Manual Restoration

If automated restore fails, restore components manually:

```bash
# Restore Homebrew packages
brew bundle --file=/path/to/backup/Brewfile_*

# Restore npm packages
cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g

# Restore preferences
cp -R /path/to/backup/preferences_*/* ~/Library/Preferences/

# Restore Android Studio configuration
cp -R /path/to/backup/android_studio_*/* ~/.android/
```

### Backup Recovery

If backup files are corrupted:

```bash
# Check backup integrity
find ~/.macos_utility_backups -type f -exec file {} \;

# Verify text files
find ~/.macos_utility_backups -name "*.txt" -exec head -5 {} \;

# Check for partial backups
find ~/.macos_utility_backups -name "*partial*" -o -name "*temp*"
```

## Prevention Tips

### Before System Format

1. **Test backup process**: Use `--dry-run` to verify backup functionality
2. **Verify backup contents**: Check backup summary and file integrity
3. **Multiple backup locations**: Store backups in multiple locations (external drive, cloud)
4. **Document system state**: Note any custom configurations or special settings

### During Restoration

1. **Check system requirements**: Ensure all dependencies are available
2. **Use dry-run mode**: Test restoration process without making changes
3. **Monitor disk space**: Ensure sufficient space for restoration
4. **Close applications**: Close all applications before restoration

### After Restoration

1. **Verify functionality**: Test restored applications and tools
2. **Check configurations**: Verify settings and preferences are correct
3. **Update if needed**: Run system updates after restoration
4. **Document issues**: Note any problems for future reference

## Getting Help

If you encounter unlisted issues:

1. **Check logs**: Review logs in `~/logs` directory
2. **Use dry-run**: Test with `--dry-run` option first
3. **Verify environment**: Check system requirements and dependencies
4. **Open issue**: Report with detailed error information:
   - Error messages
   - System information (macOS version, shell type)
   - Backup/restore commands used
   - Relevant log files
   - Steps to reproduce

## Common Error Codes

| Error Code | Description               | Solution                             |
| ---------- | ------------------------- | ------------------------------------ |
| EACCES     | Permission denied         | Check file/directory permissions     |
| ENOENT     | No such file or directory | Verify backup path and contents      |
| ENOSPC     | No space left on device   | Check available disk space           |
| EINVAL     | Invalid argument          | Verify command line options          |
| EIO        | Input/output error        | Check disk health and file integrity |

---

For additional help, see the main [Troubleshooting Guide](../troubleshooting.md).
