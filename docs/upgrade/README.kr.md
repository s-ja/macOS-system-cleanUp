# 시스템 업그레이드 유틸리티

[View in English](README.md)

## 개요

`system_upgrade.sh`는 macOS 시스템의 패키지와 애플리케이션을 최신 상태로 유지하기 위한 자동화된 업그레이드 스크립트입니다. 이 스크립트는 Homebrew, Cask, 그리고 시스템 전체의 업데이트를 관리합니다.

## 주요 기능

- Homebrew 및 Cask 자동 업데이트
- topgrade를 통한 전체 시스템 업데이트
- Homebrew Cask 호환 앱 자동 감지
- 상세한 로깅 시스템
- 오류 처리 및 복구
- 임시 파일 자동 관리

## 빠른 시작

```bash
# 기본 사용법
./src/upgrade/system_upgrade.sh

# 사용 가능한 업데이트 확인
./src/upgrade/system_upgrade.sh --check-only

# 특정 업데이트 건너뛰기
./src/upgrade/system_upgrade.sh --no-cask
```

자세한 설치 방법은 [설치 가이드](../common/INSTALLATION.md)를 참조하세요.

문제 해결은 [문제 해결 가이드](TROUBLESHOOTING.md)를 참조하세요.

버전 기록과 변경사항은 [변경 이력](CHANGELOG.md)을 참조하세요.

## 안전 기능

- 시스템 상태 검증
- 캐시 무결성 검사
- 권한 검증
- 오류 복구 메커니즘
- 실패한 업데이트에 대한 자동 롤백

## 요구사항

- Ruby ≥ 3.2.0
- Homebrew
- macOS 10.15 이상

## 기여하기

기여 방법은 [기여 가이드라인](../common/CONTRIBUTING.md)을 참조하세요.

## 라이선스

MIT 라이선스 - 자세한 내용은 LICENSE 파일을 참조하세요.
