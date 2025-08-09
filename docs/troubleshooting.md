# Troubleshooting Guide 문제 해결 가이드

[English](#english) | [한국어](#korean)

<a id="english"></a>

## English

### Common Issues

#### Shell Compatibility Issues

##### Script Fails with "declare: -g: invalid option"

```bash
declare: -g: invalid option
declare: usage: declare [-afFirtx] [-p] [name[=value] ...]
```

**Solutions**:

1. Check your shell version:
   ```bash
   bash --version
   zsh --version
   ```
2. Use zsh instead of old bash:
   ```bash
   zsh src/system_upgrade.sh --help
   ```
3. Update to newer bash via Homebrew:
   ```bash
   brew install bash
   /usr/local/bin/bash src/system_upgrade.sh --help
   ```

##### Shell-specific Syntax Errors

```bash
bad substitution
```

**Solutions**:

1. Ensure you're using a compatible shell:

   ```bash
   # Check current shell
   echo $0

   # Run with specific shell
   zsh src/system_cleanup.sh
   bash src/system_cleanup.sh
   ```

2. The scripts auto-detect shell features, but you can force a specific shell if needed

<a id="cleanup"></a>

#### System Cleanup Utility Issues

##### Permission Errors

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

##### Homebrew Cleanup Fails

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

##### Docker Cleanup Issues

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

##### OpenWebUI Cleanup Issues

```bash
ERROR: Failed to clean OpenWebUI data
```

**Solutions**:

1. Check Docker and container status:
   ```bash
   docker ps | grep open-webui
   ```
2. Check volume existence:
   ```bash
   docker volume ls | grep open-webui
   ```
3. Skip OpenWebUI cleanup:
   ```bash
   ./src/cleanup/system_cleanup.sh --no-docker
   ```

##### Android Studio Cleanup

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

##### System Cache Issues

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

##### Log File Issues

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

<a id="upgrade"></a>

#### System Upgrade Utility Issues

##### Ruby Version Issues

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

##### Homebrew Update Failures

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

##### Cask Update Issues

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

##### Permission Problems

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

##### Topgrade Integration

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

##### Cache Integrity Issues

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

### Recovery Procedures

#### Backup Important Data

Before running cleanup or upgrade:

```bash
# Homebrew
brew bundle dump

# npm global packages
npm list -g --depth=0 > npm-globals.txt

# Android AVD
cp -r ~/.android/avd ~/avd_backup

# App configurations
cp -r ~/Library/Preferences ~/backup/preferences

# System settings
defaults read > ~/backup/defaults.txt
```

#### Restore from Backup

If needed:

```bash
# Restore Homebrew packages
brew bundle

# Restore npm packages
cat npm-globals.txt | grep -v npm | awk '{print $2}' | xargs npm install -g

# Restore Android AVD
cp -r ~/avd_backup/* ~/.android/avd/

# Restore preferences
cp -r ~/backup/preferences/* ~/Library/Preferences/
```

### Prevention Tips

1. Always use `--dry-run` or `--check-only` first
2. Keep backups of important data
3. Close applications before cleanup/upgrade
4. Use appropriate flags to skip sensitive areas
5. Monitor disk space regularly
6. Keep clean Homebrew installation

### Getting Help

If you encounter unlisted issues:

1. Check the logs in `~/logs`
2. Run with `--dry-run` or `--verbose` option
3. Open an issue with:
   - Error message
   - System information
   - Steps to reproduce
   - Relevant log files

---

<a id="korean"></a>

## 한국어

### 일반적인 문제

#### 쉘 호환성 문제

##### "declare: -g: invalid option" 오류로 스크립트 실패

```bash
declare: -g: invalid option
declare: usage: declare [-afFirtx] [-p] [name[=value] ...]
```

**해결 방법**:

1. 쉘 버전 확인:
   ```bash
   bash --version
   zsh --version
   ```
2. 오래된 bash 대신 zsh 사용:
   ```bash
   zsh src/system_upgrade.sh --help
   ```
3. Homebrew를 통해 최신 bash로 업데이트:
   ```bash
   brew install bash
   /usr/local/bin/bash src/system_upgrade.sh --help
   ```

##### 쉘별 문법 오류

```bash
bad substitution
```

**해결 방법**:

1. 호환 가능한 쉘 사용 확인:

   ```bash
   # 현재 쉘 확인
   echo $0

   # 특정 쉘로 실행
   zsh src/system_cleanup.sh
   bash src/system_cleanup.sh
   ```

2. 스크립트가 쉘 기능을 자동 감지하지만 필요시 특정 쉘 강제 지정 가능

#### 시스템 정리 유틸리티 문제

##### 권한 오류

```bash
ERROR: Permission denied
```

**해결 방법**:

1. 스크립트 권한 확인:
   ```bash
   chmod +x src/cleanup/system_cleanup.sh
   ```
2. 디렉토리 권한 확인:
   ```bash
   ls -la ~/Library/Caches
   ls -la /Library/Caches  # sudo 필요
   ```

#### 시스템 업그레이드 유틸리티 문제

##### Ruby 버전 문제

```bash
ERROR: Ruby version >= 3.2.0 is required
```

**해결 방법**:

1. 현재 Ruby 버전 확인:
   ```bash
   ruby -v
   ```
2. Homebrew로 Ruby 업데이트:
   ```bash
   brew upgrade ruby
   ```

### 예방 팁

1. 항상 먼저 `--dry-run` 또는 `--check-only` 사용
2. 중요 데이터 백업 유지
3. 스크립트 실행 전 애플리케이션 종료
4. 적절한 플래그로 민감한 영역 건너뛰기
5. 디스크 공간 정기 모니터링
6. 깔끔한 Homebrew 설치 상태 유지

### 도움 받기

목록에 없는 문제의 경우:

1. `~/logs`의 로그 확인
2. `--dry-run` 또는 `--verbose` 옵션으로 실행
3. 이슈 보고 시 포함할 내용:
   - 오류 메시지
   - 시스템 정보
   - 재현 단계
   - 관련 로그 파일
