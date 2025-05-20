# System Cleanup Utility 시스템 정리 유틸리티

[English](#english) | [한국어](#korean)

<a id="english"></a>

## English

### Overview

`system_cleanup.sh` is an automated maintenance script designed to clean up your macOS system, free disk space, and maintain system health. It performs a series of cleanup operations on various parts of your system.

### Features

- Disk usage analysis and reporting
- Homebrew package management and cleanup
- npm cache cleanup
- System log size checking
- Docker resource cleanup (optional)
- OpenWebUI container and data volume cleanup
- node_modules directory analysis
- Yarn cache cleanup
- .DS_Store file cleanup
- Android Studio file cleanup

### Quick Start

```bash
# Basic usage
./src/cleanup/system_cleanup.sh

# Auto-clean mode
./src/cleanup/system_cleanup.sh --auto-clean

# Skip specific cleanups
./src/cleanup/system_cleanup.sh --no-brew --no-docker
```

For detailed installation instructions, see [Installation Guide](installation.md).

For troubleshooting, see [Troubleshooting Guide](troubleshooting.md#cleanup).

For version history and changes, see [Changelog](../CHANGELOG.md).

### Command Line Options

```
--help          Show help message
--auto-clean    Run all cleanup operations without prompts
--dry-run       Show what would be cleaned without cleaning
--no-brew       Skip Homebrew cleanup
--no-npm        Skip npm cache cleanup
--no-docker     Skip Docker cleanup (also skips OpenWebUI cleanup)
--no-android    Skip Android Studio cleanup
```

### Cleanup Features

#### OpenWebUI Cleanup

The OpenWebUI cleanup feature helps manage disk space used by OpenWebUI, a Docker-based web interface for AI models. This feature detects OpenWebUI installations by:

1. Checking for running Docker containers named "open-webui"
2. Checking for Docker volumes related to OpenWebUI

##### Cleanup Options

- **Cache Files**: Removes cache directories that can safely be deleted
- **Temporary Files**: Removes `.temp`, `.tmp`, `.downloading`, and `.part` files
- **Log Files**: Removes log files older than 30 days
- **DeepSeek Model Files**: Option to remove DeepSeek model files if they're no longer needed

The script reports volume size before and after cleaning, along with the exact space saved.

##### Safety Considerations

- Preserves conversation history and important settings
- Container restart is optional but recommended to apply changes
- Uses Docker volume operations for safe access to data
- Can operate even if the container is not currently running

### Security Considerations

- Requires sudo only for system log access
- No system modifications with elevated privileges
- Safe cleanup areas only
- Interactive confirmation for sensitive operations

### Contributing

See [Contributing Guide](../CONTRIBUTING.md) for guidelines.

### License

MIT License - see LICENSE file for details.

---

<a id="korean"></a>

## 한국어

### 개요

`system_cleanup.sh`는 macOS 시스템의 디스크 공간을 확보하고 시스템 상태를 유지하기 위해 설계된 자동화된 유지보수 스크립트입니다. 이 스크립트는 시스템의 다양한 부분에 대한 정리 작업을 수행합니다.

### 주요 기능

- 디스크 사용량 분석 및 보고
- Homebrew 패키지 관리 및 정리
- npm 캐시 정리
- 시스템 로그 크기 확인
- Docker 리소스 정리(선택 사항)
- OpenWebUI 컨테이너 및 데이터 볼륨 정리
- node_modules 디렉토리 분석
- Yarn 캐시 정리
- .DS_Store 파일 정리
- 안드로이드 스튜디오 파일 정리

### 빠른 시작

```bash
# 기본 사용법
./src/cleanup/system_cleanup.sh

# 자동 정리 모드
./src/cleanup/system_cleanup.sh --auto-clean

# 특정 정리 작업 건너뛰기
./src/cleanup/system_cleanup.sh --no-brew --no-docker
```

자세한 설치 방법은 [설치 가이드](installation.md)를 참조하세요.

문제 해결은 [문제 해결 가이드](troubleshooting.md#cleanup)를 참조하세요.

버전 기록과 변경사항은 [변경 이력](../CHANGELOG.md)을 참조하세요.

### 명령행 옵션

```
--help          도움말 메시지 표시
--auto-clean    프롬프트 없이 모든 정리 작업 실행
--dry-run       실제 정리 없이 정리될 내용만 표시
--no-brew       Homebrew 정리 건너뛰기
--no-npm        npm 캐시 정리 건너뛰기
--no-docker     Docker 정리 건너뛰기 (OpenWebUI 정리도 건너뜁니다)
--no-android    안드로이드 스튜디오 정리 건너뛰기
```

### 정리 기능

#### OpenWebUI 정리

OpenWebUI 정리 기능은 AI 모델을 위한 Docker 기반 웹 인터페이스인 OpenWebUI가 사용하는 디스크 공간을 관리하는 데 도움을 줍니다. 이 기능은 다음과 같은 방법으로 OpenWebUI 설치를 감지합니다:

1. "open-webui"라는 이름의 실행 중인 Docker 컨테이너 확인
2. OpenWebUI 관련 Docker 볼륨 확인

##### 정리 옵션

- **캐시 파일**: 안전하게 삭제할 수 있는 캐시 디렉토리 제거
- **임시 파일**: `.temp`, `.tmp`, `.downloading`, `.part` 파일 제거
- **로그 파일**: 30일 이상 된 로그 파일 제거
- **DeepSeek 모델 파일**: 더 이상 필요하지 않은 경우 DeepSeek 모델 파일 제거 옵션

스크립트는 정리 전후 볼륨 크기와 절약된 정확한 공간을 보고합니다.

##### 안전 고려사항

- 대화 기록 및 중요 설정을 보존합니다
- 컨테이너 재시작은 선택 사항이지만 변경 사항을 적용하기 위해 권장됩니다
- 데이터에 안전하게 접근하기 위해 Docker 볼륨 작업을 사용합니다
- 컨테이너가 현재 실행 중이 아니더라도 작동할 수 있습니다

### 보안 고려사항

- 시스템 로그 접근에만 sudo 권한 필요
- 상승된 권한으로 시스템 수정하지 않음
- 안전한 정리 영역만 처리
- 민감한 작업에 대한 대화형 확인

### 기여하기

기여 방법은 [기여 가이드라인](../CONTRIBUTING.md)을 참조하세요.

### 라이선스

MIT 라이선스 - 자세한 내용은 LICENSE 파일을 참조하세요.
