# Changelog - System Cleanup Utility

## [v3.0] - 2024-12-28

### 추가/Added

- **공통 함수 라이브러리 통합**: common.sh 활용으로 코드 모듈화
- **UI 요소 표준화**: 섹션 헤더, 구분선, 메시지 형식 통일
- **향상된 명령줄 옵션**: --help, --dry-run, --auto-yes 등 새로운 옵션들

### 개선/Improved

- **코드 모듈화**: common.sh를 활용한 중복 제거 및 함수 인터페이스 통일
- **로깅 시스템 통합**: 일관된 로깅 및 오류 처리
- **사용자 인터페이스**: 표준화된 메시지 출력 및 진행 상황 표시
- **zsh 환경 호환성**: PATH 환경변수 명시적 설정, 변수 확장 안전성 개선

### 보안 강화/Security

- **안전한 파일 작업**: rm -rf 직접 호출을 safe_remove(), safe_clear_cache() 안전 함수로 교체
- **중요 시스템 디렉토리 보호**: 시스템 보호 목록과 사용자 확인 시스템 강화
- **권한 검증**: sudo 권한 체크 및 안전한 임시 파일 처리

### 버그 수정/Fixed

- **zsh 환경 호환성**: awk 명령어 접근, 변수 확장, 날짜 형식 등 zsh 환경 문제 완전 해결
- **PATH 환경변수**: 시스템 명령어 접근성 완전 보장
- **변수 확장 안전성**: `$var` → `${var}` 패턴으로 zsh 호환성 향상

## [v2.6] - 2025-05-31

### 개선/Improved

- 전반적인 스크립트 안정성 및 기능 개선
- 오류 처리 메커니즘 강화
- 로깅 시스템 개선
- 성능 최적화

### 수정/Fixed

- 다양한 시스템 환경에서의 호환성 문제 해결
- 권한 관련 오류 처리 개선

## [v2.5] - 2025-05-30

### 추가/Added

- Android Studio 다중 버전 관리 기능 강화
- 무효 데이터 정리 기능 추가
- 에러 발생 시에도 중단 없이 다음 단계로 진행하는 로직 추가

### 개선/Improved

- 시스템 정리 스크립트 안정성 대폭 개선
- 타임아웃 처리를 통한 무한 실행 방지
- 모든 섹션에 오류 복구 및 계속 진행 로직 추가
- 스크립트 중단 시 자원 정리를 위한 트랩 핸들러 구현
- 복잡한 조건문 구조 단순화 및 가독성 개선

### 수정/Fixed

- Android Studio 정리 섹션에서 스크립트 중단 문제 해결
- node_modules 검색 무한 대기 문제 수정
- Docker 명령 실패 시 스크립트 중단 방지

## [Unreleased]

### Added

- OpenWebUI container and data volume cleanup feature
- Enhanced volume size calculation and reporting
- Granular cleanup options for OpenWebUI data

### Improved

- Standardized subsection numbering
- Better space saved calculation and reporting

## [v2.0] - 2025-04-14

### Added

- Android Studio cleanup feature
- AVD file protection implementation
- Enhanced logging system

## [v1.3] - 2023-07-15

### Added

- .DS_Store file cleanup feature
- Progress indicators for long operations

## [v1.2] - 2023-06-10

### Added

- node_modules directory cleanup
- Yarn cache cleanup

### Improved

- Error handling for package managers

## [v1.1] - 2023-05-25

### Added

- Docker cleanup functionality

### Improved

- Logging system
- Error reporting

## [v1.0] - 2023-05-20

### Initial Release

- Basic system cleanup functionality
- Homebrew cleanup
- npm cache cleanup
- System log management
