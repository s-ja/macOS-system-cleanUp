# 문제 해결 가이드 - 시스템 정리 유틸리티

[View in English](TROUBLESHOOTING.md)

## 일반적인 문제

### 권한 오류

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
3. 시스템 로그의 경우:
   ```bash
   sudo ./src/cleanup/system_cleanup.sh
   ```

### 로그 파일 생성 권한 오류

```bash
🛑 FATAL: 로그 파일 생성 실패. 권한 확인 필요
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

### Homebrew 정리 실패

```bash
Error: Could not cleanup old versions
```

**해결 방법**:

1. Homebrew 상태 확인:
   ```bash
   brew doctor
   ```
2. Homebrew 권한 초기화:
   ```bash
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```
3. 수동 정리 시도:
   ```bash
   rm -rf $(brew --cache)
   ```

### Docker 정리 문제

```bash
Error: Cannot connect to the Docker daemon
```

**해결 방법**:

1. Docker 서비스 확인:
   ```bash
   docker info
   ```
2. Docker 시작:
   ```bash
   open -a Docker
   ```
3. Docker 정리 건너뛰기:
   ```bash
   ./src/cleanup/system_cleanup.sh --no-docker
   ```

### 안드로이드 스튜디오 정리

```bash
ERROR: Failed to clean Gradle cache
```

**해결 방법**:

1. 안드로이드 스튜디오 종료
2. Gradle 캐시 수동 정리:
   ```bash
   rm -rf ~/.gradle/caches/*
   ```
3. AVD 파일 보존:
   ```bash
   cp -r ~/.android/avd ~/avd_backup
   ```

### 시스템 캐시 문제

```bash
ERROR: Cannot access system caches
```

**해결 방법**:

1. 디렉토리 존재 여부 확인:
   ```bash
   sudo ls -la /Library/Caches
   sudo ls -la /System/Library/Caches
   ```
2. 누락된 디렉토리 생성:
   ```bash
   sudo mkdir -p /Library/Caches
   sudo chmod 755 /Library/Caches
   ```

### 로그 파일 문제

```bash
ERROR: Could not create log file
```

**해결 방법**:

1. 로그 디렉토리 확인:
   ```bash
   mkdir -p ~/logs
   chmod 755 ~/logs
   ```
2. 쓰기 권한 확인:
   ```bash
   touch ~/logs/test.log
   ```

## 복구 절차

### 중요 데이터 백업

정리 실행 전:

```bash
# Homebrew 백업
brew bundle dump

# npm 전역 패키지 백업
npm list -g --depth=0 > npm-globals.txt

# Android AVD 백업
cp -r ~/.android/avd ~/avd_backup
```

### 백업에서 복원

필요한 경우:

```bash
# Homebrew 패키지 복원
brew bundle

# npm 패키지 복원
cat npm-globals.txt | grep -v npm | awk '{print $2}' | xargs npm install -g

# Android AVD 복원
cp -r ~/avd_backup/* ~/.android/avd/
```

## 예방 팁

1. 항상 먼저 `--dry-run` 사용
2. 중요 데이터 백업 유지
3. 정리 전 애플리케이션 종료
4. 민감한 영역은 적절한 플래그로 건너뛰기
5. 디스크 공간 정기적 모니터링

## 도움 받기

목록에 없는 문제가 발생한 경우:

1. `~/logs`의 로그 확인
2. `--dry-run` 옵션으로 실행
3. 다음 정보와 함께 이슈 열기:
   - 오류 메시지
   - 시스템 정보
   - 재현 단계
   - 관련 로그 파일
