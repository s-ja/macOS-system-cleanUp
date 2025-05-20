# OpenWebUI 정리 기능

[View in English](OPENWEBUI.md)

## 개요

`system_cleanup.sh`의 OpenWebUI 정리 기능은 AI 모델을 위한 Docker 기반 웹 인터페이스인 OpenWebUI가 사용하는 디스크 공간을 관리하는 데 도움을 줍니다. 이 기능을 통해 시간이 지남에 따라 누적될 수 있는 캐시 파일, 임시 파일 및 기타 데이터를 정리할 수 있습니다.

## 작동 방식

스크립트는 다음과 같은 방법으로 OpenWebUI가 설치되어 있는지 감지합니다:

1. "open-webui"라는 이름의 실행 중인 Docker 컨테이너 확인
2. OpenWebUI 관련 Docker 볼륨 확인

OpenWebUI가 감지되면 스크립트는 여러 정리 옵션을 제공합니다:

### 정리 옵션

- **캐시 파일**: 안전하게 삭제할 수 있는 캐시 디렉토리 제거
- **임시 파일**: `.temp`, `.tmp`, `.downloading`, `.part` 파일 제거
- **로그 파일**: 30일 이상 된 로그 파일 제거
- **DeepSeek 모델 파일**: 더 이상 필요하지 않은 경우 DeepSeek 모델 파일 제거 옵션

### 공간 계산

스크립트는 다음을 보고합니다:

- 정리 전 볼륨 크기
- 정리 후 볼륨 크기
- 정리 작업으로 절약된 정확한 공간

## 사용법

### 기본 사용법

옵션 없이 정리 스크립트를 실행하면 대화형 프롬프트가 표시됩니다:

```bash
./src/cleanup/system_cleanup.sh
```

OpenWebUI의 각 정리 유형에 대한 옵션이 표시됩니다.

### 자동 정리 모드

모든 OpenWebUI 캐시 및 임시 파일을 자동으로 정리하려면:

```bash
./src/cleanup/system_cleanup.sh --auto-clean
```

### 드라이 런 모드

실제로 파일을 제거하지 않고 정리될 내용을 확인하려면:

```bash
./src/cleanup/system_cleanup.sh --dry-run
```

### OpenWebUI 정리 건너뛰기

OpenWebUI 정리는 Docker 정리의 일부입니다. 이를 건너뛰려면:

```bash
./src/cleanup/system_cleanup.sh --no-docker
```

## 안전 고려사항

- 스크립트는 대화 기록 및 중요 설정을 보존합니다
- 컨테이너 재시작은 선택 사항이지만 변경 사항을 적용하기 위해 권장됩니다
- 스크립트는 데이터에 안전하게 접근하기 위해 Docker 볼륨 작업을 사용합니다
- 스크립트는 컨테이너가 현재 실행 중이 아니더라도 작동할 수 있습니다

## 문제 해결

OpenWebUI 정리에 문제가 발생하는 경우:

1. Docker가 실행 중인지 확인
2. 볼륨 이름 패턴이 설치와 일치하는지 확인
3. 자세한 오류 메시지는 `logs` 디렉토리의 전체 로그 파일 참조

자세한 내용은 [문제 해결 가이드](TROUBLESHOOTING.kr.md)를 참조하세요.
