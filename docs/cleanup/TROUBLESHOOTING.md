# Troubleshooting Guide - System Cleanup Utility

[한국어 문서 보기](TROUBLESHOOTING.kr.md)

## Common Issues

### Permission Errors

```bash
ERROR: Permission denied
```

**Solutions**:

1. Check script permissions:
   ```bash
   chmod +x src/cleanup/system_cleanup.sh
   ```
2. Verify directory permissions:
   ```bash
   ls -la ~/Library/Caches
   ls -la /Library/Caches  # Requires sudo
   ```
3. For system logs:
   ```bash
   sudo ./src/cleanup/system_cleanup.sh
   ```

### Homebrew Cleanup Fails

```bash
Error: Could not cleanup old versions
```

**Solutions**:

1. Check Homebrew status:
   ```bash
   brew doctor
   ```
2. Reset Homebrew permissions:
   ```bash
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```
3. Try manual cleanup:
   ```bash
   rm -rf $(brew --cache)
   ```

### Docker Cleanup Issues

```bash
Error: Cannot connect to the Docker daemon
```

**Solutions**:

1. Check Docker service:
   ```bash
   docker info
   ```
2. Start Docker:
   ```bash
   open -a Docker
   ```
3. Skip Docker cleanup:
   ```bash
   ./src/cleanup/system_cleanup.sh --no-docker
   ```

### Android Studio Cleanup

```bash
ERROR: Failed to clean Gradle cache
```

**Solutions**:

1. Close Android Studio
2. Clear Gradle cache manually:
   ```bash
   rm -rf ~/.gradle/caches/*
   ```
3. Preserve AVD files:
   ```bash
   cp -r ~/.android/avd ~/avd_backup
   ```

### Command Not Found Errors on zsh

```bash
get_free_space:2: command not found: awk
```

**Solutions**:

1. PATH를 명시적으로 설정:
   ```bash
   export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
   ```
2. 최신 스크립트를 사용해 위 경로가 자동으로 적용되도록 합니다.

### Incorrect Timestamp Format

```bash
INFO: 스크립트 시작 시간: #오후
```

**Solutions**:

1. 명시적 날짜 형식 지정:
   ```bash
   date '+%Y-%m-%d %H:%M:%S'
   ```
2. 최신 스크립트는 해당 형식을 기본으로 사용합니다.

### System Cache Issues

```bash
ERROR: Cannot access system caches
```

**Solutions**:

1. Check directory existence:
   ```bash
   sudo ls -la /Library/Caches
   sudo ls -la /System/Library/Caches
   ```
2. Create missing directories:
   ```bash
   sudo mkdir -p /Library/Caches
   sudo chmod 755 /Library/Caches
   ```

### Log File Issues

```bash
ERROR: Could not create log file
```

**Solutions**:

1. Check logs directory:
   ```bash
   mkdir -p ~/logs
   chmod 755 ~/logs
   ```
2. Verify write permissions:
   ```bash
   touch ~/logs/test.log
   ```

## Recovery Procedures

### Backup Important Data

Before running cleanup:

```bash
# Backup Homebrew
brew bundle dump

# Backup npm global packages
npm list -g --depth=0 > npm-globals.txt

# Backup Android AVD
cp -r ~/.android/avd ~/avd_backup
```

### Restore from Backup

If needed:

```bash
# Restore Homebrew packages
brew bundle

# Restore npm packages
cat npm-globals.txt | grep -v npm | awk '{print $2}' | xargs npm install -g

# Restore Android AVD
cp -r ~/avd_backup/* ~/.android/avd/
```

## Prevention Tips

1. Always use `--dry-run` first
2. Keep backups of important data
3. Close applications before cleanup
4. Use appropriate flags to skip sensitive areas
5. Monitor disk space regularly

## Getting Help

If you encounter unlisted issues:

1. Check the logs in `~/logs`
2. Run with `--dry-run` option
3. Open an issue with:
   - Error message
   - System information
   - Steps to reproduce
   - Relevant log files
