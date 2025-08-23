# AGENTS.md - AI 에이전트 작업 가이드

## 📋 **프로젝트 개요**

이 문서는 macOS System Maintenance Tools 프로젝트에서 AI 에이전트들이 일관성 있게 작업할 수 있도록 하는 가이드입니다. 문서화, 코드 수정, 커밋 메시지 등 모든 작업에 대한 표준을 정의합니다.

## 🤖 **AI 에이전트 작업 규칙**

### **모델별 역할 매핑**

- **GPT-5**: 문서화, 코드 리뷰, 규칙 검증, 전체 아키텍처 분석
- **Claude**: 대규모 텍스트 요약, 논리적 분석, 복잡한 문제 해결
- **Cursor 내부 모델**: 코드 삽입/자동 리팩토링, 실시간 코드 수정
- **기타 모델**: 특화된 작업 (예: 보안 검사, 성능 분석)

### **에이전트 간 협업 원칙**

- **입력 우선순위**: `AGENTS.md` 규칙을 최우선으로 한다
- **산출물 관리**: 모든 결과물은 `docs/`에 기록, 로그는 `logs/`에 저장
- **세션 간 공유**: 작업 결과는 반드시 문서화하여 다음 세션에서 참조 가능하게 함
- **책임 범위**: 각 에이전트는 할당된 작업 영역 내에서만 수정 권한 가짐

### **세션 관리 규칙**

```bash
# 세션 시작 시 필수 확인사항
1. AGENTS.md 최신 버전 확인
2. 이전 세션의 작업 로그 검토
3. 현재 작업 범위와 책임 영역 확인
4. 공통 함수 라이브러리 변경사항 파악
```

## 🏗️ **프로젝트 아키텍처**

### **디렉토리 구조**

```
macos-system-util/
├── src/                          # 핵심 스크립트 소스
│   ├── common.sh                 # 공통 함수 라이브러리 (838줄)
│   ├── system_cleanup.sh         # 시스템 정리 유틸리티 (1309줄)
│   ├── system_upgrade.sh         # 시스템 업그레이드 유틸리티 (393줄)
│   └── system_restore.sh         # 시스템 복원 유틸리티 (435줄)
├── docs/                         # 문서화
│   ├── cleanup/                  # 정리 유틸리티 문서
│   ├── upgrade/                  # 업그레이드 유틸리티 문서
│   ├── restore/                  # 복원 유틸리티 문서
│   └── common/                   # 공통 문서
├── logs/                         # 실행 로그
├── scripts/                      # 유틸리티 스크립트
└── .github/workflows/            # CI/CD 파이프라인
```

### **스크립트 간 의존성**

```
system_cleanup.sh     ──┐
system_upgrade.sh     ──┼──→ common.sh (공통 함수)
system_restore.sh     ──┘
```

- **common.sh**: 모든 스크립트의 기반이 되는 공통 함수 라이브러리
- **각 유틸리티**: 독립적으로 실행 가능하지만 common.sh의 함수들을 공유

## 📊 **로그 ↔ 문서 자동 싱크 규칙**

### **로그 파일 명명 규칙**

```bash
# 각 스크립트 실행 로그는 다음 형식으로 저장
logs/스크립트명_YYYYMMDD_HHMMSS.log

# 예시
logs/cleanup_20241228_143022.log
logs/upgrade_20241228_143156.log
logs/restore_20241228_143245.log
```

### **로그 → 문서 자동 전환 규칙**

#### **1. CHANGELOG.md 업데이트**

```bash
# AI 에이전트는 로그를 분석하여:
- 주요 개선사항 추출
- 버그 수정 내용 파악
- 성능 향상 지표 기록
- 사용자 경험 개선사항 정리
```

#### **2. TROUBLESHOOTING.md 업데이트**

```bash
# 로그에서 문제/해결 패턴을 자동으로:
- 새로운 오류 유형 추가
- 해결 방법 검증 및 개선
- 예방 팁 업데이트
- 복구 절차 보완
```

#### **3. 자동화 스크립트 예시**

```bash
#!/bin/bash
# scripts/sync_logs_to_docs.sh

# 로그 분석 및 문서 업데이트
analyze_logs() {
    local log_file="$1"
    local script_name="$2"

    # 주요 개선사항 추출
    grep -E "(SUCCESS|IMPROVED|ENHANCED)" "$log_file" | \
        while read -r line; do
            update_changelog "$script_name" "$line"
        done

    # 문제/해결 패턴 추출
    grep -E "(ERROR|WARNING|FIXED)" "$log_file" | \
        while read -r line; do
            update_troubleshooting "$script_name" "$line"
        done
}
```

## 🔧 **코드 구조 및 표준**

### **common.sh 표준 함수들**

#### **로깅 함수**

```bash
# 기본 로깅
log_message "메시지"

# 특화된 로깅
log_info "정보 메시지"
log_success "성공 메시지"
log_warning "경고 메시지"
handle_error "오류 메시지" [exit_on_error]
```

#### **유틸리티 함수**

```bash
# 디스크 공간 포맷
format_disk_space $bytes

# 안전한 파일 삭제
safe_remove "$path"

# 사용자 확인
confirm_action "질문" [default_value]
```

#### **환경 설정 함수**

```bash
# 로깅 설정
setup_logging "스크립트명"

# PATH 환경변수 설정
setup_environment
```

### **스크립트별 표준 구조**

#### **1. 헤더 및 설정**

```bash
#!/bin/bash

# 스크립트명 - 간단한 설명
# 버전 - 날짜
#
# 상세한 설명

# 에러 발생 시 스크립트 중단
set -e

# 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
```

#### **2. 변수 및 설정**

```bash
# 스크립트 설정
SCRIPT_NAME="script_name"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE=""

# 명령줄 옵션
DRY_RUN=false
AUTO_YES=false
# ... 기타 옵션들
```

#### **3. 함수 정의**

```bash
# 도움말 표시
show_help() {
    # 표준화된 도움말 형식
}

# 명령줄 인수 처리
process_arguments() {
    # 표준화된 인수 처리
}

# 메인 함수
main() {
    # 표준화된 메인 로직
}
```

#### **4. 메인 실행부**

```bash
# 메인 함수 실행
main "$@"
exit 0
```

## 🛡️ **보안 실행 경계**

### **권한 관리 규칙**

#### **Root 권한 요구 스크립트 실행 전 필수 단계**

```bash
# 1. 사용자 확인 (confirm_action)
if ! confirm_action "이 작업은 root 권한이 필요합니다. 계속하시겠습니까?" "n"; then
    log_warning "사용자가 root 권한 작업을 취소했습니다"
    exit 0
fi

# 2. 로그에 명시적 기록
log_info "ROOT 권한으로 실행 중: $SCRIPT_NAME"
log_info "실행 사용자: $(whoami)"
log_info "실행 시간: $(date)"

# 3. 자동화 시 root 단계 분리 실행
if [[ "$AUTO_YES" == "true" ]]; then
    log_warning "자동화 모드에서는 root 권한 작업을 건너뜁니다"
    return 0
fi
```

#### **보안 경계 명시**

```bash
# ⚠️ 보안 주의사항
# 다음 작업은 반드시 사용자 확인 후 실행:
# - 시스템 파일 수정
# - 권한 변경
# - 네트워크 설정 변경
# - 사용자 계정 관리
```

## 🚀 **CI/CD 자동 검증**

### **GitHub Actions 기반 자동화**

#### **문서 및 코드 일관성 검증**

```yaml
# .github/workflows/validate-consistency.yml
name: Docs & Code Consistency
on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup environment
        run: |
          chmod +x src/*.sh
          chmod +x scripts/*.sh

      - name: Validate system cleanup script
        run: bash src/system_cleanup.sh --dry-run

      - name: Validate system upgrade script
        run: bash src/system_upgrade.sh --check-only

      - name: Check documentation consistency
        run: ./scripts/check_docs_consistency.sh

      - name: Validate common functions
        run: ./scripts/validate_common_functions.sh

      - name: Security check
        run: ./scripts/security_audit.sh
```

#### **자동화 검증 스크립트 예시**

```bash
#!/bin/bash
# scripts/check_docs_consistency.sh

# 문서 일관성 검증
check_docs_consistency() {
    local errors=0

    # 1. README 파일 존재 확인
    for dir in docs/cleanup docs/upgrade docs/restore; do
        if [[ ! -f "$dir/README.md" ]] || [[ ! -f "$dir/README.kr.md" ]]; then
            echo "❌ ERROR: $dir에 README 파일이 누락되었습니다"
            ((errors++))
        fi
    done

    # 2. CHANGELOG 동기화 확인
    local main_changelog="CHANGELOG.md"
    for dir in docs/cleanup docs/upgrade docs/restore; do
        local script_changelog="$dir/CHANGELOG.md"
        if [[ -f "$script_changelog" ]]; then
            # 최신 버전 정보 비교
            local main_version=$(grep -m1 "## \[v" "$main_changelog" | cut -d'[' -f2 | cut -d']' -f1)
            local script_version=$(grep -m1 "## \[v" "$script_changelog" | cut -d'[' -f2 | cut -d']' -f1)

            if [[ "$main_version" != "$script_version" ]]; then
                echo "⚠️  WARNING: $dir CHANGELOG 버전 불일치 (메인: $main_version, 스크립트: $script_version)"
            fi
        fi
    done

    # 3. 링크 유효성 검증
    find docs/ -name "*.md" -exec grep -l "\[.*\](" {} \; | \
        while read -r file; do
            grep -o "\[.*\]([^)]*)" "$file" | \
                while read -r link; do
                    local url=$(echo "$link" | sed 's/.*(\([^)]*\))/\1/')
                    if [[ "$url" == http* ]] && ! curl -s --head "$url" >/dev/null; then
                        echo "❌ ERROR: $file의 링크가 유효하지 않습니다: $url"
                        ((errors++))
                    fi
                done
        done

    return $errors
}

# 메인 실행
main() {
    echo "🔍 문서 일관성 검증을 시작합니다..."

    if check_docs_consistency; then
        echo "✅ 모든 문서가 일관성을 유지하고 있습니다"
        exit 0
    else
        echo "❌ 문서 일관성 문제가 발견되었습니다"
        exit 1
    fi
}

main "$@"
```

## 📚 **문서화 규칙**

### **CHANGELOG.md 작성 규칙**

#### **메인 CHANGELOG.md (프로젝트 루트)**

```markdown
## [v3.1] - 2024-12-28

### 주요 개선사항

- 간단한 요약 (1-2줄)
- 핵심 변경사항만 나열

> 📖 **상세 내용**: 각 스크립트별 CHANGELOG.md 참조
>
> - [시스템 정리 유틸리티](docs/cleanup/CHANGELOG.md)
> - [시스템 업그레이드 유틸리티](docs/upgrade/CHANGELOG.md)
> - [시스템 복원 유틸리티](docs/restore/CHANGELOG.md)
```

#### **스크립트별 CHANGELOG.md**

```markdown
## [v3.1] - 2024-12-28

### 버그 수정/Fixed

- **구체적인 문제**: 상세한 해결 방법 설명
- **기술적 세부사항**: 코드 변경 내용 포함

### 개선/Improved

- **사용자 경험**: UI/UX 개선 사항
- **성능**: 성능 향상 내용

### 보안 강화/Security

- **보안 기능**: 새로 추가된 보안 기능
- **권한 관리**: 권한 관련 개선사항
```

### **README.md 작성 규칙**

#### **구조**

1. **개요**: 스크립트의 목적과 주요 기능
2. **빠른 시작**: 기본 사용법과 예제
3. **주요 기능**: 상세한 기능 설명
4. **명령줄 옵션**: 모든 CLI 옵션과 설명
5. **요구사항**: 시스템 요구사항과 의존성
6. **문제 해결**: 기본적인 문제 해결 방법
7. **기여하기**: 기여 방법 안내

#### **언어별 관리**

- **영어**: 기술적 용어와 코드 예제 중심
- **한국어**: 사용자 친화적 설명과 한국어 명령어 예제

### **TROUBLESHOOTING.md 작성 규칙**

#### **구조**

1. **일반적인 문제**: 자주 발생하는 문제와 해결방법
2. **복구 절차**: 문제 발생 시 복구 방법
3. **예방 팁**: 문제 예방을 위한 가이드
4. **도움 받기**: 추가 지원 방법

#### **문제 해결 패턴**

````markdown
### 문제 유형

```bash
ERROR: 구체적인 오류 메시지
```
````

**해결 방법**:

1. 첫 번째 단계:
   ```bash
   명령어 예제
   ```
2. 두 번째 단계:
   ```bash
   명령어 예제
   ```

````

## 🔧 **코드 수정 규칙**

### **파일 수정 시 체크리스트**

#### **문서 수정 전**
- [ ] 기존 문서 구조 파악
- [ ] 중복 내용 확인
- [ ] 관련 문서들 식별

#### **문서 수정 중**
- [ ] 메인 CHANGELOG.md와 스크립트별 CHANGELOG.md 동기화
- [ ] 영어/한국어 문서 동시 업데이트
- [ ] 링크 및 참조 경로 확인

#### **문서 수정 후**
- [ ] 문서 구조 일관성 확인
- [ ] 링크 유효성 검증
- [ ] 중복 내용 제거 확인

### **새로운 기능 추가 시**

#### **1단계: 메인 CHANGELOG.md 업데이트**
```markdown
## [v3.2] - 2024-XX-XX

### 추가/Added
- **새로운 기능명**: 간단한 설명
- **관련 기능**: 추가 관련 기능들

> 📖 **상세 내용**: 각 스크립트별 CHANGELOG.md 참조
````

#### **2단계: 스크립트별 CHANGELOG.md 업데이트**

```markdown
## [v3.2] - 2024-XX-XX

### 추가/Added

- **새로운 기능명**: 상세한 기능 설명
- **구현 세부사항**: 기술적 구현 내용
- **사용법**: 사용 방법과 예제
```

#### **3단계: README.md 업데이트**

- 새로운 기능을 주요 기능 섹션에 추가
- 명령줄 옵션 섹션 업데이트
- 사용 예제 추가

#### **4단계: TROUBLESHOOTING.md 업데이트**

- 새로운 기능 관련 문제 해결 방법 추가
- 예방 팁 업데이트

## 📝 **커밋 메시지 규칙**

### **컨벤셔널 커밋 형식**

```
type(scope): description

[optional body]

[optional footer]
```

### **타입 정의**

- **feat**: 새로운 기능
- **fix**: 버그 수정
- **docs**: 문서 수정
- **style**: 코드 포맷팅
- **refactor**: 코드 리팩토링
- **test**: 테스트 추가/수정
- **chore**: 유지보수 작업

### **스코프 정의**

- **cleanup**: 시스템 정리 유틸리티 관련
- **upgrade**: 시스템 업그레이드 유틸리티 관련
- **restore**: 시스템 복원 유틸리티 관련
- **common**: 공통 함수 및 라이브러리 관련
- **docs**: 문서 관련

### **커밋 메시지 예시**

```
docs(cleanup): v3.1 개선사항 CHANGELOG.md에 추가

- zsh 환경 호환성 개선사항 추가
- 안전한 파일 작업 관련 보안 강화 내용 추가
- UI 요소 표준화 내용 추가

Closes #123
```

## 🚫 **금지 사항**

### **문서 관련**

- ❌ 동일한 내용을 여러 문서에 중복 작성
- ❌ 메인 CHANGELOG.md에 상세 기술 내용 포함
- ❌ 스크립트별 문서 없이 메인 문서에만 내용 작성
- ❌ 영어/한국어 문서 동기화 없이 한쪽만 수정

### **코드 관련**

- ❌ 기존 코드 구조 파악 없이 수정
- ❌ 테스트 없이 코드 변경
- ❌ 관련 문서 업데이트 없이 기능 추가

### **커밋 관련**

- ❌ 명확하지 않은 커밋 메시지
- ❌ 여러 변경사항을 하나의 커밋에 포함
- ❌ 문서와 코드 변경을 분리하지 않은 커밋

## ✅ **권장 작업 흐름**

### **1. 문제 파악**

- 사용자 요청 또는 이슈 분석
- 관련 코드 및 문서 파악
- 영향 범위 식별

### **2. 계획 수립**

- 수정할 파일 목록 작성
- 문서 업데이트 계획 수립
- 테스트 계획 수립

### **3. 구현**

- 코드 수정
- 관련 문서 동시 업데이트
- 테스트 실행

### **4. 검증**

- 문서 구조 일관성 확인
- 링크 유효성 검증
- 중복 내용 제거 확인

### **5. 커밋**

- 명확한 커밋 메시지 작성
- 관련 변경사항 그룹화
- 문서와 코드 변경 분리

## 🔍 **품질 검증 체크리스트**

### **문서 품질**

- [ ] 모든 링크가 유효한지 확인
- [ ] 영어/한국어 문서가 동기화되었는지 확인
- [ ] 중복 내용이 제거되었는지 확인
- [ ] 문서 구조가 일관성 있는지 확인

### **코드 품질**

- [ ] 기존 코드 스타일을 따르는지 확인
- [ ] 적절한 주석이 추가되었는지 확인
- [ ] 에러 처리가 포함되었는지 확인
- [ ] 테스트가 통과하는지 확인
  - `shellcheck src/*.sh`
    - 실패 시: 스크립트 문법 오류를 수정하고 `logs/shellcheck.log`를 확인
  - `bash scripts/run_tests.sh`
    - 실패 시: 테스트 코드를 점검하고 `logs/test.log`를 확인
  - Docker, npm 등 추가 테스트 범위가 생기면 동일한 형식으로 위 목록을 확장

### **커밋 품질**

- [ ] 커밋 메시지가 명확한지 확인
- [ ] 관련 변경사항이 그룹화되었는지 확인
- [ ] 문서와 코드 변경이 적절히 분리되었는지 확인

## 📞 **지원 및 문의**

### **문제 발생 시**

1. **문서 구조 문제**: 기존 문서 구조를 참조하여 일관성 유지
2. **중복 내용 발견**: 중복 내용을 제거하고 적절한 위치에 통합
3. **링크 오류**: 상대 경로를 사용하여 링크 유효성 확인

### **참고 자료**

- [기존 문서 구조](docs/)
- [메인 CHANGELOG.md](CHANGELOG.md)
- [기여 가이드라인](CONTRIBUTING.md)
- [보안 정책](SECURITY.md)

---

**⚠️ 중요**: 이 가이드를 따르지 않으면 문서 일관성이 깨지고 유지보수가 어려워집니다. 모든 작업 전에 이 가이드를 참조하세요.
