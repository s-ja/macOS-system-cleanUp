# 시스템 정리 유틸리티

[View in English](README.md)

## 개요

`system_cleanup.sh`는 macOS 시스템의 디스크 공간을 확보하고 시스템 상태를 유지하기 위해 설계된 자동화된 유지보수 스크립트입니다. 이 스크립트는 시스템의 다양한 부분에 대한 정리 작업을 수행합니다.

## 주요 기능

- 디스크 사용량 분석 및 보고
- Homebrew 패키지 관리 및 정리
- npm 캐시 정리
- 시스템 로그 크기 확인
- Docker 리소스 정리(선택 사항)
- node_modules 디렉토리 분석
- Yarn 캐시 정리
- .DS_Store 파일 정리
- 안드로이드 스튜디오 파일 정리

## 빠른 시작

```bash
# 기본 사용법
./src/cleanup/system_cleanup.sh

# 자동 정리 모드
./src/cleanup/system_cleanup.sh --auto-clean

# 특정 정리 작업 건너뛰기
./src/cleanup/system_cleanup.sh --no-brew --no-docker
```

자세한 설치 방법은 [설치 가이드](../common/INSTALLATION.md)를 참조하세요.

문제 해결은 [문제 해결 가이드](TROUBLESHOOTING.md)를 참조하세요.

버전 기록과 변경사항은 [변경 이력](CHANGELOG.md)을 참조하세요.

## 명령행 옵션

```
--help          도움말 메시지 표시
--auto-clean    프롬프트 없이 모든 정리 작업 실행
--dry-run       실제 정리 없이 정리될 내용만 표시
--no-brew       Homebrew 정리 건너뛰기
--no-npm        npm 캐시 정리 건너뛰기
--no-docker     Docker 정리 건너뛰기
--no-android    안드로이드 스튜디오 정리 건너뛰기
```

## 보안 고려사항

- 시스템 로그 접근에만 sudo 권한 필요
- 상승된 권한으로 시스템 수정하지 않음
- 안전한 정리 영역만 처리
- 민감한 작업에 대한 대화형 확인

## 기여하기

기여 방법은 [기여 가이드라인](../common/CONTRIBUTING.md)을 참조하세요.

## 라이선스

MIT 라이선스 - 자세한 내용은 LICENSE 파일을 참조하세요.
