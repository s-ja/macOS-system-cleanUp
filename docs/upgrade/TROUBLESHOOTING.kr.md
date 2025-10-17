# 문제 해결 가이드 - 시스템 업그레이드 유틸리티

[View in English](TROUBLESHOOTING.md)

## 일반적인 문제

### 로그 파일 생성 권한 오류

```bash
🛑 FATAL: 로깅 시스템 초기화 실패
```

**해결 방법**:

1. logs 디렉토리 권한 수정:
   ```bash
   sudo chown -R $(whoami):staff logs/
   ```
2. logs 디렉토리 완전 재생성:
   ```bash
   sudo rm -rf logs && mkdir -p logs
   ```
3. 대체 로그 위치 확인:
   ```bash
   ls -la ~/.macos-system-cleanup/logs/
   ```

**참고**: v3.1.1부터는 logs 디렉토리 권한 문제 시 자동으로 `~/.macos-system-cleanup/logs/`에 로그를 생성합니다.

### Ruby 버전 문제

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
   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
3. 버전 관리자 사용:
   ```bash
   brew install rbenv
   rbenv install 3.2.0
   rbenv global 3.2.0
   ```

### Homebrew 업데이트 실패

```bash
Error: Failed to update Homebrew
```

**해결 방법**:

1. Homebrew 상태 확인:
   ```bash
   brew doctor
   ```
2. Homebrew 초기화:
   ```bash
   cd $(brew --repository)
   git fetch
   git reset --hard origin/master
   ```
3. 캐시 정리:
   ```bash
   rm -rf $(brew --cache)
   ```

### Cask 업데이트 문제

```bash
Error: Cask 'app-name' is not installed
```

**해결 방법**:

1. 강제 재설치:
   ```bash
   brew reinstall --cask app-name
   ```
2. Cask 소스 업데이트:
   ```bash
   brew update
   brew tap --repair
   ```

### 권한 문제

```bash
Error: Permission denied @ dir_s_mkdir
```

**해결 방법**:

1. 디렉토리 소유권 확인:
   ```bash
   ls -la /usr/local/Cellar
   ```
2. 권한 수정:
   ```bash
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```

### Topgrade 통합

```bash
Error: Command 'topgrade' not found
```

**해결 방법**:

1. topgrade 설치:
   ```bash
   brew install topgrade
   ```
2. topgrade 없이 실행:
   ```bash
   ./src/upgrade/system_upgrade.sh --no-topgrade
   ```

### 캐시 무결성 문제

```bash
Error: Checksum mismatch
```

**해결 방법**:

1. 다운로드 캐시 정리:
   ```bash
   brew cleanup -s
   rm -rf $(brew --cache)
   ```
2. 새로 다운로드하여 재시도:
   ```bash
   brew install --force-bottle package-name
   ```

## 복구 절차

### 업그레이드 전 백업

```bash
# Homebrew 패키지
brew bundle dump

# 앱 설정
cp -r ~/Library/Preferences ~/backup/preferences

# 시스템 설정
defaults read > ~/backup/defaults.txt
```

### 롤백 절차

업그레이드 실패 시:

```bash
# Homebrew 패키지 복원
brew bundle cleanup --force
brew bundle

# 설정 복원
cp -r ~/backup/preferences/* ~/Library/Preferences/
```

## 예방 팁

1. 항상 시스템 요구사항 확인
2. 주요 업그레이드 전 백업 유지
3. 먼저 `--check-only` 사용
4. 디스크 공간 모니터링
5. Homebrew 설치 상태 유지

## 도움 받기

목록에 없는 문제의 경우:

1. `~/logs`의 로그 확인
2. `--verbose`로 실행
3. 이슈 보고 시 포함할 내용:
   - 오류 메시지
   - 시스템 버전
   - Homebrew 진단 정보
   - 재현 단계
