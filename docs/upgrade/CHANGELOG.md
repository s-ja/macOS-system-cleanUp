# Changelog - System Upgrade Utility

<<<<<<< HEAD
=======
## [v3.1] - 2024-12-28

### 추가/Added

- **zsh 호환성**: zsh와 bash 양쪽 쉘에서 모두 정상 작동
- **크로스 쉘 문자열 처리**: 대소문자 변환에 쉘별 문법 자동 선택

### 개선/Improved

- **런타임 쉘 감지**: `ZSH_VERSION` 변수를 통한 동적 기능 선택
- **하위 호환성**: 기존 bash 사용자도 변경 없이 계속 사용 가능

>>>>>>> bc475dc26d6de204561fa8d5e6778fbb2f2c48ca
## [v3.0] - 2024-12-28

### 추가/Added

- `--help`, `--dry-run`, `--auto-yes` 옵션 추가
- 세분화된 스킵 옵션: `--no-brew`, `--no-cask`, `--no-topgrade`, `--no-android`, `--no-apps`
- 표준화된 UI 함수 적용
- 안전한 파일 작업 함수(safe_remove 등) 도입

### 개선/Improved

- 중요 시스템 경로 보호 로직 강화
- 사용자 확인 시스템 및 DRY RUN 경고 개선
<<<<<<< HEAD
- 안드로이드 스튜디오 버전 감지를 다중 Fallback 방식으로 강화하고 설치 경로를 직접 확인
- 안드로이드 스튜디오 업데이트 프롬프트 기본값을 'y'로 변경하고 DRY RUN에서도 현재 버전을 표시
=======
>>>>>>> bc475dc26d6de204561fa8d5e6778fbb2f2c48ca

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
