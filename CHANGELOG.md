# macOS System Maintenance Tools - Changelog

이 문서는 macOS System Maintenance Tools 프로젝트의 모든 주요 변경 사항을 기록합니다.

## [v3.1.1] - 2024-12-28

### 주요 개선사항

- **로깅 시스템 대폭 개선**: 권한 문제 자동 해결 및 fallback 로깅 시스템 구현
- **안전한 로그 파일 생성**: 프로젝트 logs 디렉토리 권한 문제 시 자동 대체 위치 사용
- **공통 함수 라이브러리 통합**: 모든 스크립트에서 일관된 로깅 및 오류 처리
- **권한 문제 해결 가이드**: 사용자 친화적인 권한 문제 해결 방법 제공

> 📖 **상세 내용**: 각 스크립트별 CHANGELOG.md 참조
>
> - [시스템 정리 유틸리티](docs/cleanup/CHANGELOG.md)
> - [시스템 업그레이드 유틸리티](docs/upgrade/CHANGELOG.md)
> - [시스템 복원 유틸리티](docs/restore/CHANGELOG.md)

## [v3.1] - 2024-12-28

### 주요 개선사항

- **brew doctor 오탐 해결**: PATH 경고를 무시하고 실제 오류만 감지하도록 개선
- **Android Studio 버전 추출**: 3단계 fallback 방식으로 안정성 대폭 향상
- **사용자 입력 처리**: 엔터 키 입력 시 업데이트 취소 문제 해결
- **zsh 환경 호환성**: awk 명령어 접근, 변수 확장, 날짜 형식 등 완전 해결

> 📖 **상세 내용**: 각 스크립트별 CHANGELOG.md 참조
>
> - [시스템 정리 유틸리티](docs/cleanup/CHANGELOG.md)
> - [시스템 업그레이드 유틸리티](docs/upgrade/CHANGELOG.md)
> - [시스템 복원 유틸리티](docs/restore/CHANGELOG.md)

## [v3.0] - 2024-12-28

### 주요 개선사항

- **새로운 시스템 복원 유틸리티**: 완전 포맷 후 클린 상태에서의 모든 앱 재설치 기능
- **코드 모듈화**: common.sh를 활용한 중복 제거 및 함수 인터페이스 통일
- **UI 요소 표준화**: 섹션 헤더, 구분선, 메시지 형식 통일
- **보안 강화**: 안전한 파일 작업, 시스템 디렉토리 보호, 권한 검증
- **안정성 향상**: zsh 환경 호환성, 오류 처리 및 복구 메커니즘 개선

> 📖 **상세 내용**: 각 스크립트별 CHANGELOG.md 참조
>
> - [시스템 정리 유틸리티](docs/cleanup/CHANGELOG.md)
> - [시스템 업그레이드 유틸리티](docs/upgrade/CHANGELOG.md)
> - [시스템 복원 유틸리티](docs/restore/CHANGELOG.md)
