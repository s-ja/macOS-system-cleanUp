#!/bin/bash

# 에러 발생 시 스크립트 중단
set -e

# 스크립트 디렉토리 및 로깅 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
TEMP_DIR="/tmp/brew_replace"
INSTALLED_APPS="$TEMP_DIR/apps_installed.txt"
AVAILABLE_CASKS="$TEMP_DIR/casks_available.txt"
LOG_FILE="$LOG_DIR/upgrade_$(date +"%Y%m%d_%H%M%S").log"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 종료 시 임시 파일 정리 설정
trap 'cleanup' EXIT

# 로깅 함수
log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# 에러 처리 함수
handle_error() {
    local error_message="$1"
    log_message "에러 발생: $error_message"
    echo "Continuing with next task..."
    # 종료 코드 1 대신 계속 진행
}

# 시스템 상태 확인 함수
verify_system_state() {
    log_message "시스템 상태 확인 중..."
    
    # Homebrew 상태 확인
    if ! brew doctor &>/dev/null; then
        log_message "⚠️ Homebrew 상태 이상 감지"
        log_message "Homebrew 캐시 재구성 및 강제 업데이트 시도..."
        if ! brew cleanup --prune=all && brew update --force; then
            handle_error "Homebrew 복구 실패"
            return 1
        fi
        log_message "✅ Homebrew 복구 완료"
    fi

    # 시스템 캐시 상태 확인
    if [ ! -d "/Library/Caches" ] || [ ! -w "/Library/Caches" ]; then
        log_message "⚠️ 시스템 캐시 디렉토리 접근 불가"
        if ! sudo mkdir -p /Library/Caches && sudo chmod 755 /Library/Caches; then
            handle_error "시스템 캐시 디렉토리 생성/권한 설정 실패"
            return 1
        fi
        log_message "✅ 시스템 캐시 디렉토리 복구 완료"
    fi

    # brew 관련 디렉토리 권한 확인
    local brew_dirs=("/usr/local/Homebrew" "/usr/local/Cellar" "/usr/local/Caskroom")
    for dir in "${brew_dirs[@]}"; do
        if [ -d "$dir" ] && [ ! -w "$dir" ]; then
            log_message "⚠️ $dir 디렉토리 권한 문제 감지"
            if ! sudo chown -R $(whoami) "$dir"; then
                handle_error "$dir 권한 복구 실패"
                return 1
            fi
            log_message "✅ $dir 권한 복구 완료"
        fi
    done
    
    return 0
}

# 캐시 상태 확인 함수
check_cache_state() {
    log_message "캐시 상태 확인 중..."
    
    # Homebrew 캐시 확인
    if ! brew doctor &>/dev/null; then
        log_message "⚠️ Homebrew 캐시 재구성 필요"
        if ! brew cleanup --prune=all && brew update --force; then
            handle_error "Homebrew 캐시 재구성 실패"
            return 1
        fi
        log_message "✅ Homebrew 캐시 재구성 완료"
        
        # 캐시 재구성 후 안정화를 위한 대기
        log_message "시스템 안정화를 위해 10초 대기..."
        sleep 10
    fi
    
    return 0
}

# 임시 파일 정리 함수
cleanup() {
    log_message "임시 파일 정리 중..."
    
    if [ -d "$TEMP_DIR" ]; then
        # 각 임시 파일 확인 및 삭제
        if [ -f "$INSTALLED_APPS" ]; then
            rm -f "$INSTALLED_APPS" && log_message "설치된 앱 목록 파일 제거 완료"
        fi
        
        if [ -f "$AVAILABLE_CASKS" ]; then
            rm -f "$AVAILABLE_CASKS" && log_message "사용 가능한 Cask 목록 파일 제거 완료"
        fi
        
        # 전체 임시 디렉토리 제거
        if rm -rf "$TEMP_DIR"; then
            log_message "✅ 임시 파일 정리 완료"
        else
            handle_error "임시 파일 정리 실패"
        fi
    else
        log_message "정리할 임시 파일이 없습니다"
    fi
}

# 종료 시 정리 함수 등록 (스크립트 종료 시에만 실행)
# trap cleanup EXIT  # 이미 위에서 설정됨

# 임시 디렉토리 생성 및 권한 설정
log_message "임시 디렉토리 설정 중..."
if ! mkdir -p "$TEMP_DIR"; then
    log_message "🛑 FATAL: 임시 디렉토리 생성 실패. 수동 조치 필요:"
    log_message "1. sudo mkdir -p $TEMP_DIR"
    log_message "2. sudo chown $(whoami) $TEMP_DIR"
    exit 1
fi

# 임시 디렉토리 권한 확인 및 설정
if [ ! -w "$TEMP_DIR" ]; then
    if ! chmod 755 "$TEMP_DIR"; then
        log_message "🛑 FATAL: 임시 디렉토리 권한 설정 실패"
        exit 1
    fi
fi

# 로그 파일 초기화
touch "$LOG_FILE" || {
    log_message "🛑 FATAL: 로그 파일 생성 실패. 권한 확인 필요:"
    log_message "chmod 755 $TEMP_DIR"
    exit 1
}

# 스크립트 시작 로깅
log_message "========================================="
log_message "시스템 업그레이드 프로세스 시작"
log_message "========================================="

# 시스템 상태 확인
verify_system_state || exit 1

# 캐시 상태 확인
check_cache_state || exit 1

# =========================================
# Homebrew 업데이트
# =========================================
log_message "Homebrew 업데이트를 시작합니다..."
if ! brew update; then
    handle_error "Homebrew 업데이트 실패"
fi

# =========================================
# Homebrew Cask 업데이트
# =========================================
log_message "Homebrew Cask 업데이트를 시작합니다..."

# Cask 업데이트 함수 정의
update_casks() {
    local updated_count=0
    local failed_count=0
    
    log_message "업데이트가 필요한 Cask를 확인 중..."
    
    # brew outdated 명령으로 업데이트가 필요한 Cask만 가져오기
    local outdated_casks=$(brew outdated --cask 2>/dev/null || echo "")
    
    if [ -n "$outdated_casks" ]; then
        local total_outdated=$(echo "$outdated_casks" | wc -l | tr -d ' ')
        log_message "총 $total_outdated개의 Cask가 업데이트가 필요합니다."
        
        # 각 outdated Cask를 순차적으로 처리
        while IFS= read -r cask; do
            if [ -n "$cask" ]; then
                log_message "🔄 $cask 업데이트 실행 중..."
                
                # 실제 업데이트 실행
                if brew upgrade --cask "$cask" 2>/dev/null; then
                    updated_count=$((updated_count + 1))
                    log_message "✅ $cask 업데이트 완료"
                else
                    failed_count=$((failed_count + 1))
                    log_message "⚠️ $cask 업데이트 실패 (정상적인 상황일 수 있음)"
                fi
                
                # 안정성을 위한 짧은 대기
                sleep 1
            fi
        done <<< "$outdated_casks"
        
        log_message "========================================="
        log_message "Cask 업데이트 결과 요약:"
        log_message "   성공: $updated_count개"
        log_message "   실패: $failed_count개"
        log_message "========================================="
    else
        log_message "✅ 모든 Cask가 최신 버전입니다. 업데이트가 필요하지 않습니다."
    fi
    
    # 간단한 상태 메시지
    log_message "Cask 업데이트 프로세스 완료"
}

# 안정적인 Cask 업데이트 실행
log_message "안정적인 개별 Cask 업데이트를 진행합니다..."
update_casks

# =========================================
# 시스템 전체 업데이트 (topgrade)
# =========================================
log_message "topgrade를 실행하여 모든 패키지와 앱을 업데이트합니다..."
if ! command -v topgrade &> /dev/null; then
    log_message "topgrade가 설치되어 있지 않습니다. 설치를 시작합니다..."
    if ! brew install topgrade; then
        handle_error "topgrade 설치 실패"
    fi
fi

# topgrade 실행 준비 완료
log_message "topgrade 실행을 준비합니다..."

# topgrade 실행 (안드로이드 스튜디오 비활성화)
if ! topgrade --disable android_studio --yes; then
    handle_error "topgrade 실행 실패"
fi

# =========================================
# 안드로이드 스튜디오 별도 관리 (주석 처리됨)
# =========================================
# log_message "안드로이드 스튜디오 업데이트를 확인합니다..."

# if command -v studio &> /dev/null || command -v android-studio &> /dev/null || [[ -d "/Applications/Android Studio.app" ]]; then
#     # 현재 버전 확인 (개선된 방법)
#     if command -v brew &> /dev/null; then
#         # brew info 출력에서 버전 정보 추출 (여러 방법 시도)
#         current_version=""
#         
#         # 방법 1: 첫 번째 줄에서 버전 추출 (예: android-studio: 2025.1.2.11)
#         current_version=$(brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p')
#         
#         # 방법 2: Caskroom 경로에서 버전 추출 (fallback)
#         if [[ -z "$current_version" ]]; then
#             current_version=$(brew info --cask android-studio 2>/dev/null | grep "Caskroom" | grep -o '[0-9][0-9.]*[0-9]' | head -1)
#         fi
#         
#         # 방법 3: 일반적인 버전 패턴 검색 (fallback)
#         if [[ -z "$current_version" ]]; then
#             current_version=$(brew info --cask android-studio 2>/dev/null | grep -o '[0-9]\{4\}\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
#         fi
#         
#         if [[ -n "$current_version" ]]; then
#             log_message "현재 안드로이드 스튜디오 버전: $current_version"
#         else
#             log_message "안드로이드 스튜디오가 설치되어 있지만 버전 정보를 가져올 수 없습니다"
#         fi
#     fi
#     
#     # 안드로이드 스튜디오 업데이트 확인
#     log_message "안드로이드 스튜디오를 업데이트하시겠습니까? (y/n)"
#     read -r update_android_studio
#     if [[ "$update_android_studio" =~ ^[Yy]$ ]]; then
#         log_message "안드로이드 스튜디오 업데이트를 시작합니다..."
#         
#         if command -v brew &> /dev/null; then
#             if brew upgrade --cask android-studio 2>/dev/null; then
#                 log_message "✅ 안드로이드 스튜디오 업데이트 완료"
#             else
#                 log_message "⚠️ 안드로이드 스튜디오 업데이트 실패 (이미 최신 버전이거나 정상적인 상황일 수 있음)"
#             fi
#         else
#             log_message "⚠️ Homebrew가 없어 안드로이드 스튜디오를 업데이트할 수 없습니다"
#         fi
#     else
#         log_message "안드로이드 스튜디오 업데이트를 건너뜁니다."
#     fi
# else
#     log_message "안드로이드 스튜디오가 설치되어 있지 않습니다."
# fi

log_message "안드로이드 스튜디오 업데이트 기능이 비활성화되었습니다."

# =========================================
# 새로운 앱 검색 및 설치
# =========================================

log_message "Homebrew Cask로 설치 가능한 앱을 검색합니다..."

# 임시 디렉토리가 존재하는지 다시 확인
if [ ! -d "$TEMP_DIR" ]; then
    log_message "임시 디렉토리를 다시 생성합니다..."
    mkdir -p "$TEMP_DIR" || {
        handle_error "임시 디렉토리 재생성 실패"
        return 1
    }
fi

# 현재 설치된 Cask 목록 저장
log_message "설치된 Cask 목록을 저장합니다..."
if ! brew list --cask > "$INSTALLED_APPS" 2>/dev/null; then
    handle_error "설치된 Cask 목록 저장 실패"
    return 1
fi

# 설치 가능한 Cask 목록 저장 (최적화된 검색)
log_message "사용 가능한 Cask 목록을 저장합니다..."
if ! brew search --casks "" 2>/dev/null | grep -v "No Cask found" > "$AVAILABLE_CASKS"; then
    handle_error "사용 가능한 Cask 목록 저장 실패"
    return 1
fi

# 발견된 앱을 저장할 배열
declare -a found_apps

# /Applications 디렉토리에서 앱 검색
log_message "Applications 디렉토리에서 앱을 검색합니다..."
if [ -d "/Applications" ]; then
    cd /Applications || {
        handle_error "Applications 디렉토리 접근 실패"
        return 1
    }
    
    # 각 .app 파일에 대해 확인 (성능 최적화)
    while IFS= read -r -d '' app; do
        app_name="${app#./}"
        app_name="${app_name%.app}"
        cask_name="${app_name// /-}"
        
        # 설치 가능한 Cask 목록에 있는지 확인
        if [ -f "$AVAILABLE_CASKS" ] && grep -Fxq "$cask_name" "$AVAILABLE_CASKS" 2>/dev/null; then
            # 이미 설치된 Cask 목록에 없는 경우
            if [ -f "$INSTALLED_APPS" ] && ! grep -Fxq "$cask_name" "$INSTALLED_APPS" 2>/dev/null; then
                # 앱 버전 확인
                app_version=$(mdls -name kMDItemVersion "$app" 2>/dev/null | awk -F'"' '{print $2}' || echo "unknown")
                log_message "Homebrew Cask로 설치 가능한 앱 발견: $app_name (현재 버전: $app_version)"
                found_apps+=("$cask_name")
            fi
        fi
    done < <(find . -maxdepth 1 -name "*.app" -print0 2>/dev/null)
    
    # 원래 디렉토리로 복귀
    cd - > /dev/null || true
else
    log_message "Applications 디렉토리를 찾을 수 없습니다."
fi

# 발견된 앱이 있는 경우
if [ ${#found_apps[@]} -gt 0 ]; then
    log_message "다음 앱들을 Homebrew Cask로 설치하시겠습니까? (y/n)"
    for app in "${found_apps[@]}"; do
        echo "- $app"
    done
    
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_message "설치를 시작합니다..."
        for app in "${found_apps[@]}"; do
            log_message "Installing $app..."
            if ! brew install --cask --force "$app"; then
                log_message "경고: $app 설치 실패"
            fi
        done
        log_message "설치가 완료되었습니다."
    else
        log_message "설치가 취소되었습니다."
    fi
else
    log_message "Homebrew Cask로 설치 가능한 새로운 앱이 없습니다."
fi

log_message "모든 업데이트가 완료되었습니다."
log_message "========================================="

RUBY_VERSION=$(ruby -v | awk '{print $2}')
if [[ "$(printf '%s\n' "3.2.0" "$RUBY_VERSION" | sort -V | head -n1)" != "3.2.0" ]]; then
    log_message "⚠️ 경고: 현재 Ruby 버전 ($RUBY_VERSION)이 일부 gem 요구사항(3.2.0+)을 충족하지 않습니다."
    log_message "  1. Ruby 업그레이드: brew upgrade ruby"
    log_message "  2. 이전 버전 설치: gem install erb -v 4.0.0 && gem install typeprof -v 0.20.0"
fi