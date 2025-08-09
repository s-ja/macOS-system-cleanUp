# 시스템 업그레이드 유틸리티

[View in English](README.md)

## 개요

`system_upgrade.sh`는 macOS 시스템의 패키지와 애플리케이션을 최신 상태로 유지하기 위한 자동화된 업그레이드 스크립트입니다. 이 스크립트는 향상된 안정성과 오류 복구 기능으로 Homebrew, Cask, 그리고 시스템 전체의 업데이트를 관리합니다.

## 주요 기능

- Homebrew 및 Cask 자동 업데이트
- topgrade를 통한 전체 시스템 업데이트
- Homebrew Cask 호환 앱 자동 감지
- 향상된 안드로이드 스튜디오 관리 (topgrade에서 분리)
- 상세한 로깅 시스템
- 개선된 오류 처리 및 복구
- 임시 파일 자동 관리
- 향상된 권한 검증
- 강화된 디렉토리 처리

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

<<<<<<< HEAD
## 최근 개선사항 (v3.0)

- **새로운 옵션**: `--help`, `--dry-run`, `--auto-yes` 추가
- **세분화된 스킵 옵션**: `--no-brew`, `--no-cask`, `--no-topgrade`, `--no-android`, `--no-apps`
- **UI 통일**: 모든 섹션에 표준 헤더와 구분선 적용
- **안전한 작업**: 파괴적 명령을 위한 경로 보호 및 안전한 파일 헬퍼
=======
## 최근 개선사항 (v3.1)

- **크로스 쉘 호환성**: zsh와 bash 모두에서 완벽하게 작동
- **크로스 쉘 문자열 처리**: 대소문자 변환에 쉘별 문법 자동 선택
- **런타임 쉘 감지**: `ZSH_VERSION` 변수를 통한 동적 기능 선택
- **하위 호환성**: 기존 bash 사용자도 변경 없이 계속 사용 가능
- **새로운 옵션**: `--help`, `--dry-run`, `--auto-yes` 추가
>>>>>>> bc475dc26d6de204561fa8d5e6778fbb2f2c48ca

## 안전 기능

- 시스템 상태 검증
- 캐시 무결성 검사
- 권한 검증
- 오류 복구 메커니즘
- 실패한 업데이트에 대한 자동 롤백
- 안전한 임시 디렉토리 처리

## 요구사항

- Ruby ≥ 3.2.0
- Homebrew
- macOS 10.15 이상

## 기여하기

기여 방법은 [기여 가이드라인](../common/CONTRIBUTING.md)을 참조하세요.

## 라이선스

MIT 라이선스 - 자세한 내용은 LICENSE 파일을 참조하세요.
