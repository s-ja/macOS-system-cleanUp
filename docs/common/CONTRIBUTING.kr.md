# 기여 가이드라인

[View in English](CONTRIBUTING.md)

## 행동 강령

- 다른 사람을 존중하세요
- 포용적인 언어를 사용하세요
- 건설적인 비판을 수용하세요
- 커뮤니티에 최선이 되는 것에 집중하세요

## 기여 방법

1. 저장소를 포크하세요
2. 기능 브랜치를 만드세요
3. 변경사항을 적용하세요
4. 테스트를 실행하세요
5. Pull Request를 제출하세요

## 개발 환경 설정

1. 의존성 설치:

   ```bash
   brew install ruby
   brew install shellcheck  # 쉘 스크립트 린팅용
   ```

2. pre-commit 훅 설정:
   ```bash
   cp hooks/pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit
   ```

## 코딩 표준

### 쉘 스크립트

- shellcheck를 사용하여 린팅
- Google 쉘 스타일 가이드 준수
- 복잡한 로직에 주석 추가
- 의미 있는 변수 이름 사용

### 문서

- README 파일을 최신 상태로 유지
- 모든 새로운 기능 문서화
- 적절한 예제 포함
- 영문과 한글 버전 모두 유지

## 테스트

- 새로운 기능에 대한 테스트 추가
- PR 제출 전 모든 테스트 통과 확인
- 단위 테스트와 통합 테스트 모두 포함
- 가능한 경우 다양한 macOS 버전에서 테스트

## Pull Request 프로세스

1. 문서 업데이트
2. CHANGELOG.md 업데이트
3. 버전 번호 업데이트
4. 메인테이너의 리뷰 받기

## 커밋 메시지

컨벤셔널 커밋 명세를 따르세요:

```
type(scope): description

[optional body]

[optional footer]
```

타입:

- feat: 새로운 기능
- fix: 버그 수정
- docs: 문서
- style: 포맷팅
- refactor: 코드 구조 변경
- test: 테스트 추가
- chore: 유지보수

## 질문이 있으신가요?

질문이나 우려사항이 있으시면 언제든 이슈를 열어주세요.
