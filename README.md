# macOS System Maintenance Tools / macOS 시스템 유지보수 도구

[English](#english) | [한국어](#korean)

<a id="english"></a>

## English

A collection of utilities for maintaining and optimizing your macOS system.

### Available Tools

#### System Cleanup Utility

Automated maintenance script for cleaning up your macOS system, freeing disk space, and maintaining system health.

**Key Features:**

- Cross-shell compatibility (works with both zsh and bash)
- Comprehensive system cleanup (caches, logs, temporary files)
- Development tool cleanup (Homebrew, npm, Yarn, Docker, Android Studio)
- Selective cleanup with skip options (`--no-brew`, `--no-npm`, `--no-docker`, `--no-android`)
- Enhanced stability with timeout handling and error recovery
- Detailed logging for tracking cleanup activities

[Learn more about System Cleanup Utility](docs/cleanup.md)

#### System Upgrade Utility

Automated upgrade script for keeping your macOS system's packages and applications up to date.

**Key Features:**

- Cross-shell compatibility (works with both zsh and bash)
- Automatic package manager updates (Homebrew, Cask, topgrade)
- Smart application detection and management
- Comprehensive command-line options for fine-grained control
- Safe operation with dry-run mode and user confirmations

[Learn more about System Upgrade Utility](docs/upgrade.md)

### Quick Links

- [Installation Guide](docs/installation.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

### License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<a id="korean"></a>

## 한국어

macOS 시스템 유지보수 및 최적화를 위한 유틸리티 모음입니다.

### 제공 도구

#### 시스템 정리 유틸리티

macOS 시스템의 디스크 공간을 확보하고 시스템 상태를 유지하기 위한 자동화된 유지보수 스크립트입니다.

**주요 기능:**

- 크로스 쉘 호환성 (zsh와 bash 모두에서 작동)
- 종합적인 시스템 정리(캐시, 로그, 임시 파일)
- 개발 도구 정리(Homebrew, npm, Yarn, Docker, Android Studio)
- 선택적 정리를 위한 스킵 옵션(`--no-brew`, `--no-npm`, `--no-docker`, `--no-android`)
- 타임아웃 처리와 오류 복구를 통한 향상된 안정성
- 정리 활동 추적을 위한 상세 로깅

[시스템 정리 유틸리티에 대해 자세히 알아보기](docs/cleanup.md)

#### 시스템 업그레이드 유틸리티

macOS 시스템의 패키지와 애플리케이션을 최신 상태로 유지하기 위한 자동화된 업그레이드 스크립트입니다.

**주요 기능:**

- 크로스 쉘 호환성 (zsh와 bash 모두에서 작동)
- 자동 패키지 관리자 업데이트 (Homebrew, Cask, topgrade)
- 스마트 애플리케이션 감지 및 관리
- 세밀한 제어를 위한 포괄적인 명령줄 옵션
- 드라이 런 모드와 사용자 확인을 통한 안전한 작업

[시스템 업그레이드 유틸리티에 대해 자세히 알아보기](docs/upgrade.md)

### 빠른 링크

- [설치 가이드](docs/installation.md)
- [문제 해결 가이드](docs/troubleshooting.md)
- [기여 가이드라인](CONTRIBUTING.md)
- [보안 정책](SECURITY.md)
- [변경 이력](CHANGELOG.md)

### 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 LICENSE 파일을 참조하세요.
