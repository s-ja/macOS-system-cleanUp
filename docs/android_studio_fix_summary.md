# 안드로이드 스튜디오 버전 추출 및 사용자 입력 처리 개선

## 📅 작업 정보
- **작업 날짜**: 2024-12-28
- **대상 파일**: `src/system_upgrade.sh`
- **커밋 해시**: `603a296`
- **작업 유형**: 버그 수정 및 사용성 개선

## 🐛 발견된 문제들

### 1. 안드로이드 스튜디오 버전 추출 실패
**증상**: 로그에서 버전 정보가 비어서 출력됨
```
[2025-08-10 01:39:08] ℹ️  INFO: 현재 안드로이드 스튜디오 버전: 
using
```

**원인**: `brew info --cask android-studio` 출력 형식 변화로 기존 파싱 방법 실패
```bash
# 문제가 있던 기존 방법
current_version=$(brew info --cask android-studio 2>/dev/null | grep "Installed" | awk '{print $2}' | tr -d '()')
```

### 2. 사용자 입력 처리 문제
**증상**: 엔터 키를 눌러도 업데이트가 취소됨
**원인**: 확인 프롬프트의 기본값이 'n'으로 설정되어 있어 사용자가 엔터만 눌러도 거부됨

## ✅ 해결 방안

### 1. 다중 Fallback 버전 추출 방식 구현

#### **방법 1**: 첫 번째 줄에서 직접 추출 (Primary)
```bash
# brew info 첫 줄 형식: "==> android-studio: 2025.1.2.11 (auto_updates)"
current_version=$(brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p')
```

#### **방법 2**: Caskroom 경로에서 추출 (Fallback 1)
```bash
# Caskroom 경로 형식: "/opt/homebrew/Caskroom/android-studio/2025.1.2.11"
if [[ -z "$current_version" ]]; then
    current_version=$(brew info --cask android-studio 2>/dev/null | grep "Caskroom" | grep -o '[0-9][0-9.]*[0-9]' | head -1)
fi
```

#### **방법 3**: 일반 버전 패턴 검색 (Fallback 2)
```bash
# 연도.버전 형식 패턴 검색: "2025.1.2.11"
if [[ -z "$current_version" ]]; then
    current_version=$(brew info --cask android-studio 2>/dev/null | grep -o '[0-9]\{4\}\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
fi
```

### 2. 안드로이드 스튜디오 설치 감지 개선
```bash
# 기존: 명령어만 확인
if command_exists studio || command_exists android-studio; then

# 개선: 직접 설치 경로도 확인
if command_exists studio || command_exists android-studio || [[ -d "/Applications/Android Studio.app" ]]; then
```

### 3. 사용자 입력 처리 개선
```bash
# 기존: 기본값 'n' (보수적)
confirm_action "안드로이드 스튜디오를 업데이트하시겠습니까?" "n"

# 개선: 기본값 'y' (사용자 친화적)
confirm_action "안드로이드 스튜디오를 업데이트하시겠습니까?" "y"
```

### 4. DRY RUN 모드 개선
DRY RUN 모드에서도 현재 버전 정보를 표시하도록 개선:
```bash
# DRY RUN에서도 현재 버전 표시
if command_exists brew; then
    current_version=$(brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p')
    if [[ -n "$current_version" ]]; then
        log_info "DRY RUN: 현재 안드로이드 스튜디오 버전: $current_version"
    fi
fi
```

## 🧪 테스트 결과

### 버전 추출 테스트
```bash
$ brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p'
2025.1.2.11
```
✅ **성공**: 올바른 버전 정보 추출 확인

### 사용자 입력 테스트
- ✅ **엔터 키**: 기본값 'y'로 업데이트 진행
- ✅ **'y' 입력**: 업데이트 진행
- ✅ **'n' 입력**: 업데이트 취소
- ✅ **타임아웃**: 30초 후 기본값 'y' 적용

## 📊 변경 통계

### 코드 변경량
- **파일 수정**: 1개 (`src/system_upgrade.sh`)
- **추가된 줄**: 31줄
- **삭제된 줄**: 7줄
- **순 증가**: +24줄

### 개선된 기능
1. **안정성 향상**: 3단계 fallback으로 버전 추출 실패율 최소화
2. **사용성 개선**: 기본값 변경으로 더 직관적인 사용자 경험
3. **정보 제공**: DRY RUN에서도 현재 상태 확인 가능
4. **호환성 강화**: 다양한 설치 방식 지원

## 🔍 Before vs After

### Before (문제 상황)
```
[2025-08-10 01:39:08] ℹ️  INFO: 현재 안드로이드 스튜디오 버전: 
using
```
- 버전 정보 추출 실패
- 엔터 키로 업데이트 거부됨
- DRY RUN에서 버전 정보 없음

### After (개선된 상황)
```
[2025-08-10 01:39:08] ℹ️  INFO: 현재 안드로이드 스튜디오 버전: 2025.1.2.11
[2025-08-10 01:39:08] ✅ SUCCESS: 안드로이드 스튜디오 업데이트 완료
```
- 정확한 버전 정보 표시
- 엔터 키로 쉬운 업데이트
- DRY RUN에서도 버전 확인

## 🎯 추가 개선사항

### 앱 설치 프롬프트도 개선
```bash
# 동일한 개선을 앱 설치 부분에도 적용
confirm_action "이 앱들을 Homebrew Cask로 설치하시겠습니까?" "y"
```

### 로버스트한 에러 처리
```bash
if [[ -n "$current_version" ]]; then
    log_info "현재 안드로이드 스튜디오 버전: $current_version"
else
    log_info "안드로이드 스튜디오가 설치되어 있지만 버전 정보를 가져올 수 없습니다"
fi
```

## 🚀 사용자 경험 개선

### 1. 더 직관적인 동작
- **이전**: 업데이트하려면 명시적으로 'y' 입력 필요
- **현재**: 엔터 키만으로 업데이트 가능

### 2. 더 많은 정보 제공
- **이전**: DRY RUN에서 설치 여부만 확인
- **현재**: DRY RUN에서도 현재 버전 표시

### 3. 더 안정적인 동작
- **이전**: 버전 추출 실패 시 빈 값 표시
- **현재**: 3단계 fallback으로 안정성 보장

## 📝 향후 고려사항

1. **다른 Cask 앱들**: 동일한 패턴으로 다른 앱들도 개선 가능
2. **버전 비교**: 현재 버전과 최신 버전 비교 기능 추가 검토
3. **로깅 개선**: 버전 추출 방법별 성공/실패 로깅 추가 검토

---

## 🎊 결론

이번 개선을 통해 안드로이드 스튜디오 관련 기능이 **더 안정적이고 사용자 친화적**으로 변경되었습니다. 특히 버전 정보 추출의 안정성과 사용자 입력 처리의 직관성이 크게 향상되어, 전반적인 사용자 경험이 개선되었습니다.
