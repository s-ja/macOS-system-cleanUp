# Changelog - System Upgrade Utility

## [v2.7] - 2025-08-22

### 주요 개선/Major Improvements

- **homebrew-cask-upgrade 플러그인 완전 제거**: Homebrew 4.x 호환성 문제 해결
- **update_casks() 함수 구현**: 안정적인 개별 Cask 업데이트 시스템
- **Git merge conflict 해결**: 코드 일관성 및 가독성 향상

### 개선/Improved

- Cask 업데이트 로직 단순화 및 안정성 향상
- 플러그인 의존성 제거로 실행 속도 개선
- 코드 복잡성 대폭 감소 (~30줄 감소)
- 에러 처리 및 복구 메커니즘 개선

### 수정/Fixed

- `ohai` 메서드 오류로 인한 Cask 업데이트 실패 문제 완전 해결
- 불필요한 플러그인 설치/제거 과정 제거
- 중복된 안드로이드 스튜디오 확인 코드 통합
- 임시 파일 정리 함수 호출 문제 해결

## [v2.6] - 2025-06-26

### 개선/Improved

- 임시 디렉토리 권한 설정 및 오류 처리 강화
- 안드로이드 스튜디오를 topgrade에서 제외하고 별도 관리 옵션 제공
- 에러 처리 및 복구 방법 개선
- 코드 구조화 및 가독성 향상을 위한 섹션 구분선 추가
- 파일 검색 및 처리 로직 성능 최적화

### 수정/Fixed

- 임시 디렉토리 생성 실패 시 더 명확한 오류 메시지 제공
- 안드로이드 스튜디오 업데이트 시 사용자 선택 옵션 추가
- Applications 디렉토리 접근 실패 시 안전한 처리

## [v2.5] - 2025-06-06

### 수정/Fixed

- sudo 실행 시 발생하는 권한 문제 보완
- 시스템 권한 관련 오류 처리 개선

## [v2.4] - 2025-05-31

### 개선/Improved

- 전반적인 스크립트 안정성 향상
- 오류 처리 메커니즘 강화
- 로깅 시스템 개선

## [v2.3] - 2023-05-20

### Added

- Ruby version compatibility checks

### Changed

- Enforced /tmp directory usage
- Removed home directory fallback

### Improved

- Permission validation system
- Error messages with solutions

## [v2.0] - 2023-04-14

### Added

- Enhanced logging system
- Improved error handling
- Automatic recovery mechanisms

## [v1.3] - 2023-07-15

### Added

- Automatic app detection
- Installation verification

### Improved

- Package management system

## [v1.0] - 2023-05-20

### Initial Release

- Basic upgrade functionality
- Homebrew integration
- System update checks
