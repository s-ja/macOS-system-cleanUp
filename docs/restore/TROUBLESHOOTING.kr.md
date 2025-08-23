# 문제 해결 가이드 - 시스템 복원 유틸리티

[View in English](TROUBLESHOOTING.md)

## 일반적인 문제

### 백업 실패

#### 권한 오류

```bash
ERROR: 백업 디렉토리 생성 시 권한이 거부됨
```

**해결 방법**:

1. 백업 디렉토리 권한 확인:
   ```bash
   ls -la ~/.macos_utility_backups
   ```
2. 적절한 권한으로 백업 디렉토리 생성:
   ```bash
   mkdir -p ~/.macos_utility_backups
   chmod 755 ~/.macos_utility_backups
   ```
3. 디스크 공간 확인:
   ```bash
   df -h ~
   ```

#### Homebrew 백업 문제

```bash
ERROR: Homebrew bundle 생성 실패
```

**해결 방법**:

1. Homebrew 상태 확인:
   ```bash
   brew doctor
   ```
2. Homebrew 설치 확인:
   ```bash
   brew --version
   ```
3. 수동 bundle 생성 시도:
   ```bash
   brew bundle dump --file=~/test_bundle
   ```

#### npm 백업 문제

```bash
ERROR: npm 전역 패키지 목록 생성 실패
```

**해결 방법**:

1. npm 설치 확인:
   ```bash
   npm --version
   ```
2. npm 전역 패키지 확인:
   ```bash
   npm list -g --depth=0
   ```
3. npm 권한 확인:
   ```bash
   npm config get prefix
   ```

### 복원 실패

#### 백업 무결성 문제

```bash
ERROR: 백업 파일이 손상되었거나 불완전함
```

**해결 방법**:

1. 백업 내용 확인:
   ```bash
   ls -la /path/to/backup
   ```
2. 백업 요약 확인:
   ```bash
   cat /path/to/backup/backup_summary.txt
   ```
3. 백업 구조 검증:
   ```bash
   find /path/to/backup -type f -name "*.txt" -o -name "*.plist"
   ```

#### Homebrew 복원 문제

```bash
ERROR: Homebrew 패키지 복원 실패
```

**해결 방법**:

1. Homebrew 설치 확인:
   ```bash
   brew --version
   ```
2. Brewfile 무결성 확인:
   ```bash
   head -10 /path/to/backup/Brewfile_*
   ```
3. 수동 복원 시도:
   ```bash
   brew bundle --file=/path/to/backup/Brewfile_*
   ```

#### npm 복원 문제

```bash
ERROR: npm 패키지 복원 실패
```

**해결 방법**:

1. Node.js와 npm 확인:
   ```bash
   node --version
   npm --version
   ```
2. 패키지 목록 확인:
   ```bash
   cat /path/to/backup/npm_globals_*
   ```
3. 수동 복원 시도:
   ```bash
   cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g
   ```

### 권한 문제

#### 시스템 환경설정 접근

```bash
ERROR: 시스템 환경설정에 접근할 수 없음
```

**해결 방법**:

1. 디렉토리 권한 확인:
   ```bash
   ls -la ~/Library/Preferences
   ```
2. 소유권 확인:
   ```bash
   ls -la ~/Library/Preferences | head -5
   ```
3. 필요시 권한 수정:
   ```bash
   sudo chown -R $(whoami) ~/Library/Preferences
   ```

#### Android Studio 구성

```bash
ERROR: Android Studio 구성에 접근할 수 없음
```

**해결 방법**:

1. Android Studio 설치 확인:
   ```bash
   ls -la /Applications/Android\ Studio.app
   ```
2. 구성 디렉토리 확인:
   ```bash
   ls -la ~/.android
   ls -la ~/Library/Android
   ```
3. 파일 권한 확인:
   ```bash
   find ~/.android -type f -exec ls -la {} \;
   ```

## 복구 절차

### 수동 백업 검증

```bash
# 백업 디렉토리 구조 확인
ls -la ~/.macos_utility_backups/

# 최신 백업 확인
ls -la ~/.macos_utility_backups/ | grep "full_system" | tail -1

# 백업 내용 확인
ls -la ~/.macos_utility_backups/full_system_*/

# 백업 요약 확인
cat ~/.macos_utility_backups/full_system_*/backup_summary.txt
```

### 수동 복원

자동 복원이 실패한 경우 수동으로 구성 요소를 복원할 수 있습니다:

```bash
# Homebrew 패키지 복원
brew bundle --file=/path/to/backup/Brewfile_*

# npm 패키지 복원
cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g

# 환경설정 복원
cp -R /path/to/backup/preferences_*/* ~/Library/Preferences/

# Android Studio 구성 복원
cp -R /path/to/backup/android_studio_*/* ~/.android/
```

### 백업 복구

백업 파일이 손상된 경우:

```bash
# 백업 무결성 확인
find ~/.macos_utility_backups -type f -exec file {} \;

# 텍스트 파일 확인
find ~/.macos_utility_backups -name "*.txt" -exec head -5 {} \;

# 부분 백업 확인
find ~/.macos_utility_backups -name "*partial*" -o -name "*temp*"
```

## 예방 팁

### 시스템 포맷 전

1. **백업 프로세스 테스트**: `--dry-run`을 사용하여 백업 기능 확인
2. **백업 내용 확인**: 백업 요약 및 파일 무결성 확인
3. **다중 백업 위치**: 여러 위치에 백업 저장 (외장 드라이브, 클라우드)
4. **시스템 상태 문서화**: 사용자 정의 구성이나 특별한 설정 기록

### 복원 중

1. **시스템 요구사항 확인**: 모든 의존성이 사용 가능한지 확인
2. **드라이 런 모드 사용**: 변경 없이 복원 프로세스 테스트
3. **디스크 공간 모니터링**: 복원을 위한 충분한 공간 확보
4. **애플리케이션 종료**: 복원 전 모든 애플리케이션 종료

### 복원 후

1. **기능 확인**: 복원된 애플리케이션과 도구 테스트
2. **구성 확인**: 설정과 환경설정이 올바른지 확인
3. **필요시 업데이트**: 복원 후 시스템 업데이트 실행
4. **문제 문서화**: 향후 참조를 위해 문제점 기록

## 도움 받기

목록에 없는 문제가 발생한 경우:

1. **로그 확인**: `~/logs` 디렉토리의 로그 검토
2. **드라이 런 사용**: 먼저 `--dry-run` 옵션으로 테스트
3. **환경 확인**: 시스템 요구사항과 의존성 확인
4. **이슈 열기**: 상세한 오류 정보와 함께 이슈 보고:
   - 오류 메시지
   - 시스템 정보 (macOS 버전, 쉘 유형)
   - 사용한 백업/복원 명령
   - 관련 로그 파일
   - 재현 단계

## 일반적인 오류 코드

| 오류 코드 | 설명                           | 해결 방법                      |
| --------- | ------------------------------ | ------------------------------ |
| EACCES    | 권한이 거부됨                  | 파일/디렉토리 권한 확인        |
| ENOENT    | 해당 파일 또는 디렉토리가 없음 | 백업 경로와 내용 확인          |
| ENOSPC    | 장치에 공간이 부족함           | 사용 가능한 디스크 공간 확인   |
| EINVAL    | 잘못된 인수                    | 명령줄 옵션 확인               |
| EIO       | 입력/출력 오류                 | 디스크 상태와 파일 무결성 확인 |

---

추가 도움이 필요한 경우 메인 [문제 해결 가이드](../troubleshooting.md)를 참조하세요.
