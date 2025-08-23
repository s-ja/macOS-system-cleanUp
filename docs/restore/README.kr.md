# 시스템 복원 유틸리티

[View in English](README.md)

## 개요

`system_restore.sh`는 완전히 포맷된 macOS 시스템에서 클린 상태로부터 모든 애플리케이션과 설정을 복원해야 하는 경우를 위해 설계된 포괄적인 시스템 복원 유틸리티입니다. 이 유틸리티는 전체 개발 환경에 대한 자동화된 백업 및 복원 기능을 제공합니다.

## 주요 기능

### 🔄 완전한 시스템 백업

- **Homebrew Bundle**: 설치된 모든 패키지와 cask
- **npm 전역 패키지**: Node.js 개발 도구
- **시스템 설정**: macOS 시스템 환경설정
- **앱 설정**: 애플리케이션 구성 및 설정
- **Android Studio**: 완전한 개발 환경 백업
- **백업 요약**: 복원 지침이 포함된 상세한 백업 보고서

### 🚀 자동화된 시스템 복원

- **원클릭 복원**: 백업에서 전체 시스템 복원
- **선택적 복원**: 복원할 구성 요소 선택
- **스마트 감지**: 최신 백업 자동 찾기
- **오류 복구**: 강력한 오류 처리 및 복구
- **진행 추적**: 실시간 복원 진행 상황 모니터링

### 🛡️ 안전 기능

- **드라이 런 모드**: 변경 없이 작업 테스트
- **확인 프롬프트**: 중요 작업에 대한 사용자 확인
- **백업 검증**: 복원 전 백업 무결성 확인
- **충돌 해결**: 기존 구성과의 안전한 처리
- **롤백 지원**: 덮어쓰기 전 백업 생성

## 사용 사례

### 시스템 포맷 전

```bash
# 완전한 시스템 백업 생성
./src/system_restore.sh --backup-only --auto-yes
```

### 시스템 포맷 후

```bash
# 백업에서 전체 시스템 복원
./src/system_restore.sh --restore-only --auto-yes
```

### 선택적 복원

```bash
# Homebrew 패키지만 복원
./src/system_restore.sh --restore-only --no-npm --no-prefs --no-android

# 특정 백업 위치에서 복원
./src/system_restore.sh --restore-only --restore-from=/path/to/backup
```

## 빠른 시작

### 1. 시스템 백업 (포맷 전)

```bash
# 프로젝트 디렉토리로 이동
cd /path/to/macos-system-util

# 완전한 시스템 백업 생성
./src/system_restore.sh --backup-only

# 또는 자동 확인으로
./src/system_restore.sh --backup-only --auto-yes
```

### 2. 시스템 복원 (포맷 후)

```bash
# 최신 백업에서 복원
./src/system_restore.sh --restore-only

# 또는 특정 백업에서 복원
./src/system_restore.sh --restore-only --restore-from=/path/to/backup
```

### 3. 테스트 모드

```bash
# 변경 없이 백업 및 복원 테스트
./src/system_restore.sh --dry-run
```

## 명령줄 옵션

### 주요 작업

- `--backup-only`: 시스템 백업만 실행
- `--restore-only`: 백업에서 시스템 복원만 실행
- `--restore-from=DIR`: 복원할 백업 디렉토리 지정

### 백업 옵션

- `--auto-yes`: 모든 확인 프롬프트에 자동으로 'y' 응답
- `--dry-run`: 실제 작업 없이 실행할 내용만 표시

### 복원 옵션

- `--no-brew`: Homebrew 패키지 복원 건너뛰기
- `--no-npm`: npm 전역 패키지 복원 건너뛰기
- `--no-prefs`: 애플리케이션 설정 복원 건너뛰기
- `--no-android`: Android Studio 설정 복원 건너뛰기

### 일반 옵션

- `--help`: 도움말 정보 표시

## 백업 내용

### Homebrew Bundle

- 설치된 모든 Homebrew 패키지
- 설치된 모든 Homebrew cask
- 패키지 버전 및 의존성

### npm 전역 패키지

- 전역으로 설치된 npm 패키지
- 패키지 버전 및 구성

### 시스템 설정

- macOS 시스템 환경설정
- 사용자 기본값 및 구성

### 애플리케이션 설정

- 앱별 설정 및 구성
- 사용자 환경설정 및 사용자 정의

### Android Studio

- Android SDK 구성
- AVD (Android Virtual Device) 설정
- 프로젝트 템플릿 및 구성
- Gradle 캐시 및 빌드 설정

## 복원 프로세스

### 1. 복원 전 확인

- 백업 무결성 확인
- 시스템 요구사항 확인
- 사용자 의도 확인
- 안전 백업 생성

### 2. 구성 요소 복원

- Homebrew 패키지 및 cask
- npm 전역 패키지
- 애플리케이션 설정
- Android Studio 구성

### 3. 복원 후 검증

- 복원된 구성 요소 확인
- 시스템 안정성 확인
- 다음 단계 안내 제공

## 파일 구조

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

## 요구사항

### 시스템 요구사항

- macOS 10.15 (Catalina) 이상
- Bash 4.0 이상
- 시스템 수준 작업을 위한 관리자 권한

### 의존성

- Homebrew (패키지 관리용)
- Node.js 및 npm (npm 패키지 복원용)
- Android Studio (Android 개발 환경용)

## 설치

### 1. 저장소 클론

```bash
git clone https://github.com/yourusername/macos-system-util.git
cd macos-system-util
```

### 2. 실행 권한 부여

```bash
chmod +x src/system_restore.sh
```

### 3. 설치 확인

```bash
./src/system_restore.sh --help
```

## 예시

### 완전한 워크플로우 예시

```bash
# 1. 시스템 포맷 전 완전한 백업 생성
./src/system_restore.sh --backup-only --auto-yes

# 2. 시스템 포맷 및 새 macOS 설치 후
# 먼저 Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. 전체 시스템 복원
./src/system_restore.sh --restore-only --auto-yes
```

### 선택적 복원 예시

```bash
# 개발 도구만 복원
./src/system_restore.sh --restore-only --no-prefs --no-android

# 외부 백업에서 복원
./src/system_restore.sh --restore-only --restore-from=/Volumes/External/backup
```

### 테스트 예시

```bash
# 백업 프로세스 테스트
./src/system_restore.sh --backup-only --dry-run

# 복원 프로세스 테스트
./src/system_restore.sh --restore-only --dry-run
```

## 문제 해결

### 일반적인 문제

#### 백업 실패

```bash
# 권한 확인
ls -la ~/.macos_utility_backups

# Homebrew 상태 확인
brew doctor

# npm 설치 확인
npm --version
```

#### 복원 실패

```bash
# 백업 무결성 확인
ls -la /path/to/backup

# 시스템 요구사항 확인
brew --version
node --version

# 로그 검토
tail -f logs/system_restore_*.log
```

#### 권한 문제

```bash
# 백업 디렉토리 권한 수정
chmod 755 ~/.macos_utility_backups

# 스크립트 권한 수정
chmod +x src/system_restore.sh
```

### 복구 절차

#### 수동 복원

자동 복원이 실패한 경우 수동으로 구성 요소를 복원할 수 있습니다:

```bash
# Homebrew 패키지 복원
brew bundle --file=/path/to/backup/Brewfile_*

# npm 패키지 복원
cat /path/to/backup/npm_globals_* | grep -v npm | awk '{print $2}' | xargs npm install -g

# 환경설정 복원
cp -R /path/to/backup/preferences_*/* ~/Library/Preferences/
```

#### 백업 검증

```bash
# 백업 내용 확인
ls -la ~/.macos_utility_backups/

# 백업 요약 확인
cat ~/.macos_utility_backups/full_system_*/backup_summary.txt
```

## 모범 사례

### 시스템 포맷 전

1. **완전한 백업 생성**: `--backup-only`를 사용하여 포괄적인 백업 생성
2. **백업 확인**: 백업 내용 및 요약 확인
3. **복원 테스트**: `--dry-run`을 사용하여 백업 무결성 확인
4. **안전한 저장**: 백업을 안전한 위치에 보관 (외장 드라이브, 클라우드)

### 시스템 포맷 중

1. **새 macOS 설치**: 깨끗한 macOS 버전 설치
2. **사전 요구사항 설치**: 필요한 경우 Homebrew 및 Node.js 설치
3. **시스템 확인**: 복원 전 시스템이 안정적인지 확인

### 시스템 포맷 후

1. **요구사항 확인**: 모든 의존성이 사용 가능한지 확인
2. **복원 실행**: `--restore-only`를 사용하여 시스템 복원
3. **복원 확인**: 모든 구성 요소가 작동하는지 확인
4. **애플리케이션 테스트**: 앱과 도구가 올바르게 작동하는지 확인

## 보안 고려사항

### 데이터 보호

- 백업에는 민감한 구성 데이터가 포함됩니다
- 백업을 안전하고 암호화된 위치에 저장하세요
- 클라우드 저장소에 강력한 인증을 사용하세요
- 백업 암호화 키를 정기적으로 교체하세요

### 시스템 보안

- 복원 전 백업 소스를 확인하세요
- 변경 사항을 미리보기 위해 `--dry-run`을 사용하세요
- 복원된 구성을 보안을 위해 검토하세요
- 복원 후 비밀번호와 키를 업데이트하세요

## 지원

### 도움 받기

- `~/logs` 디렉토리의 로그 확인
- 명령 옵션을 위해 `--help` 사용
- 문제 해결 섹션 검토
- 상세한 오류 정보와 함께 이슈 열기

### 기여하기

- 버그 및 기능 요청 보고
- 개선을 위한 풀 리퀘스트 제출
- 다양한 macOS 버전에서 테스트
- 사용 사례 및 워크플로우 공유

## 변경 이력

### v1.0 (2025-01-XX)

- 초기 릴리스
- 완전한 시스템 백업 및 복원
- Homebrew, npm 및 앱 설정 지원
- Android Studio 구성 백업
- 포괄적인 오류 처리 및 로깅

## 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다 - 자세한 내용은 [LICENSE](../LICENSE) 파일을 참조하세요.

---

자세한 설치 방법은 [설치 가이드](../common/INSTALLATION.md)를 참조하세요.

문제 해결은 [문제 해결 가이드](TROUBLESHOOTING.md)를 참조하세요.

버전 기록과 변경사항은 [변경 이력](CHANGELOG.md)을 참조하세요.
