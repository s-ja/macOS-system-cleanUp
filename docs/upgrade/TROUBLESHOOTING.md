# Troubleshooting Guide - System Upgrade Utility

[한국어 문서 보기](TROUBLESHOOTING.kr.md)

## Common Issues

### Ruby Version Issues

```bash
ERROR: Ruby version >= 3.2.0 is required
```

**Solutions**:

1. Check current Ruby version:
   ```bash
   ruby -v
   ```
2. Update Ruby via Homebrew:
   ```bash
   brew upgrade ruby
   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
3. Use version manager:
   ```bash
   brew install rbenv
   rbenv install 3.2.0
   rbenv global 3.2.0
   ```

### Homebrew Update Failures

```bash
Error: Failed to update Homebrew
```

**Solutions**:

1. Check Homebrew status:
   ```bash
   brew doctor
   ```
2. Reset Homebrew:
   ```bash
   cd $(brew --repository)
   git fetch
   git reset --hard origin/master
   ```
3. Clear cache:
   ```bash
   rm -rf $(brew --cache)
   ```

### Cask Update Issues

```bash
Error: Cask 'app-name' is not installed
```

**Solutions**:

1. Force reinstall:
   ```bash
   brew reinstall --cask app-name
   ```
2. Update Cask sources:
   ```bash
   brew update
   brew tap --repair
   ```

### Android Studio Detection Problems

```bash
INFO: 현재 안드로이드 스튜디오 버전:
```

**Solutions**:

1. 설치 여부 확인:
   ```bash
   ls "/Applications/Android Studio.app"
   ```
2. 버전 정보 확인:
   ```bash
   brew info --cask android-studio | head -1
   ```
3. 최신 스크립트를 사용하면 확인 프롬프트 기본값이 'y'이므로 엔터 키만 눌러도 업데이트가 진행됩니다.
4. 업데이트를 건너뛰려면:
   ```bash
   ./src/upgrade/system_upgrade.sh --no-android
   ```

### Permission Problems

```bash
Error: Permission denied @ dir_s_mkdir
```

**Solutions**:

1. Check directory ownership:
   ```bash
   ls -la /usr/local/Cellar
   ```
2. Fix permissions:
   ```bash
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```

### Topgrade Integration

```bash
Error: Command 'topgrade' not found
```

**Solutions**:

1. Install topgrade:
   ```bash
   brew install topgrade
   ```
2. Run without topgrade:
   ```bash
   ./src/upgrade/system_upgrade.sh --no-topgrade
   ```

### Cache Integrity Issues

```bash
Error: Checksum mismatch
```

**Solutions**:

1. Clear download cache:
   ```bash
   brew cleanup -s
   rm -rf $(brew --cache)
   ```
2. Retry with fresh download:
   ```bash
   brew install --force-bottle package-name
   ```

## Recovery Procedures

### Backup Before Upgrade

```bash
# Homebrew packages
brew bundle dump

# App configurations
cp -r ~/Library/Preferences ~/backup/preferences

# System settings
defaults read > ~/backup/defaults.txt
```

### Rollback Procedures

If upgrade fails:

```bash
# Restore Homebrew packages
brew bundle cleanup --force
brew bundle

# Restore preferences
cp -r ~/backup/preferences/* ~/Library/Preferences/
```

## Prevention Tips

1. Always check system requirements
2. Keep backups before major upgrades
3. Use `--check-only` first
4. Monitor disk space
5. Keep clean Homebrew installation

## Getting Help

For unlisted issues:

1. Check logs in `~/logs`
2. Run with `--verbose`
3. Include in issue report:
   - Error messages
   - System version
   - Homebrew diagnostics
   - Steps to reproduce
