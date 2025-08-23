# Changelog - System Upgrade Utility

## [v3.1] - 2024-12-28

### 버그 수정/Fixed

- **brew doctor 오탐 문제**: PATH 경고를 무시하고 실제 오류만 감지하도록 `check_homebrew_health()` 함수 개선
- **Android Studio 버전 추출**: 3단계 fallback 방식으로 버전 정보 추출 안정성 대폭 향상
- **사용자 입력 처리**: 엔터 키 입력 시 업데이트 취소 문제 해결 (기본값 'n'에서 'y'로 변경)
- **zsh 환경 호환성**: awk 명령어 접근, 변수 확장, 날짜 형식 등 zsh 환경 문제 완전 해결

### 개선/Improved

- **Homebrew 상태 검사**: `brew doctor` 출력 분석 로직 개선으로 불필요한 경고 제거
- **사용자 경험**: 더 직관적인 기본값과 프롬프트로 사용성 향상
- **크로스 셸 호환성**: bash와 zsh 양쪽 환경에서 일관된 동작 보장
- **에러 처리**: 더 정확한 문제 감지와 사용자 친화적인 메시지 제공

### 기술적 개선/Technical

- **PATH 환경변수 명시적 설정**: 시스템 명령어 접근성 완전 보장
- **날짜 형식 표준화**: 로케일 독립적인 `YYYY-MM-DD HH:MM:SS` 형식 적용
- **변수 확장 안전성**: zsh 환경에서의 변수 확장 문제 해결 (`$var` → `${var}`)
- **명령어 별칭 설정**: `awk='/usr/bin/awk'` 별칭으로 명령어 접근성 향상

## [v3.0] - 2024-12-28

### 추가/Added

- **공통 함수 라이브러리 통합**: common.sh 활용으로 코드 모듈화
- **UI 요소 표준화**: 섹션 헤더, 구분선, 메시지 형식 통일
- **향상된 명령줄 옵션**: --help, --dry-run, --auto-yes, --no-brew, --no-cask, --no-topgrade, --no-android, --no-apps

### 개선/Improved

- **코드 모듈화**: common.sh를 활용한 중복 제거 및 함수 인터페이스 통일
- **로깅 시스템 통합**: 일관된 로깅 및 오류 처리
- **사용자 인터페이스**: 표준화된 메시지 출력 및 진행 상황 표시
- **Android Studio 관리**: topgrade에서 분리하여 별도 관리

### 보안 강화/Security

- **안전한 파일 작업**: rm -rf 직접 호출을 safe_remove(), safe_clear_cache() 안전 함수로 교체
- **권한 검증**: sudo 권한 체크 및 안전한 임시 파일 처리

### 버그 수정/Fixed

- **topgrade 실행 실패**: --disable gem --no-retry 옵션과 타임아웃 추가로 안정성 향상
- **Android Studio 버전 추출**: 3단계 fallback 방식으로 버전 정보 추출 안정성 향상
- **사용자 입력 처리**: 엔터 키 입력 시 업데이트 취소 문제 해결 (기본값 'y'로 변경)

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
