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

<<<<<<< HEAD
# 종료 시 임시 파일 정리 설정
trap 'cleanup_temp_files "$TEMP_DIR"' EXIT
=======
# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"
>>>>>>> origin/main

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
trap cleanup EXIT

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
    
    # 설치된 cask 목록 가져오기
    local installed_casks=$(brew list --cask 2>/dev/null || echo "")
    
    if [ -n "$installed_casks" ]; then
        while IFS= read -r cask; do
            if [ -n "$cask" ]; then
                log_message "Cask '$cask' 업데이트 중..."
                if brew upgrade --cask "$cask" 2>/dev/null; then
                    ((updated_count++))
                    log_message "✅ $cask 업데이트 완료"
                else
                    ((failed_count++))
                    log_message "⚠️ $cask 업데이트 실패 (정상적인 상황일 수 있음)"
                fi
            fi
        done <<< "$installed_casks"
        
        log_message "Cask 업데이트 결과: $updated_count개 성공, $failed_count개 실패"
    else
        log_message "업데이트할 Cask가 없습니다."
    fi
}

# homebrew-cask-upgrade 플러그인 확인 및 설치
if ! command -v brew-cu &> /dev/null && ! brew cu --help &> /dev/null; then
    log_message "homebrew-cask-upgrade 플러그인이 설치되지 않았습니다. 설치를 시도합니다..."
    
    # 플러그인 설치 시도
    if brew tap buo/cask-upgrade; then
        log_message "✅ homebrew-cask-upgrade 플러그인 설치 완료"
    else
        log_message "⚠️ homebrew-cask-upgrade 플러그인 설치 실패, 대안 방법 사용"
        update_casks
    fi
fi

# homebrew-cask-upgrade가 사용 가능한 경우 사용 (오류 발생 시 대안 방법으로 fallback)
if command -v brew-cu &> /dev/null || brew cu --help &> /dev/null; then
    log_message "homebrew-cask-upgrade를 사용하여 Cask 업데이트를 진행합니다..."
    
    # brew cu 실행 시도 (오류 발생 시 대안 방법 사용)
    if brew cu -a 2>/dev/null; then
        log_message "✅ homebrew-cask-upgrade를 통한 Cask 업데이트 완료"
    else
        log_message "⚠️ homebrew-cask-upgrade 실행 실패, 대안 방법으로 전환"
        update_casks
    fi
fi

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

# topgrade 실행 전에 brew cu 문제 해결
log_message "topgrade 실행 전에 brew cu 호환성 문제를 해결합니다..."

# homebrew-cask-upgrade 플러그인 제거 (호환성 문제로 인해)
if brew untap buo/cask-upgrade 2>/dev/null; then
    log_message "✅ 호환성 문제가 있는 homebrew-cask-upgrade 플러그인 제거 완료"
fi

# topgrade 실행 (안드로이드 스튜디오 비활성화)
if ! topgrade --disable android_studio --yes; then
    handle_error "topgrade 실행 실패"
fi

# =========================================
# 안드로이드 스튜디오 별도 관리
# =========================================
log_message "안드로이드 스튜디오 업데이트를 확인합니다..."
if command -v studio &> /dev/null; then
    current_version=$(brew info --cask android-studio | grep "Installed" | awk '{print $2}' | tr -d '()')
    log_message "현재 안드로이드 스튜디오 버전: $current_version"
    
    # 안드로이드 스튜디오 업데이트 확인 (선택적)
    log_message "안드로이드 스튜디오를 업데이트하시겠습니까? (y/n)"
    read -r update_android_studio
    if [[ "$update_android_studio" =~ ^[Yy]$ ]]; then
        log_message "안드로이드 스튜디오 업데이트를 시작합니다..."
        if ! brew upgrade --cask android-studio; then
            log_message "⚠️ 안드로이드 스튜디오 업데이트 실패 (정상적인 상황일 수 있음)"
        else
            log_message "✅ 안드로이드 스튜디오 업데이트 완료"
        fi
    else
        log_message "안드로이드 스튜디오 업데이트를 건너뜁니다."
    fi
else
<<<<<<< HEAD
    log_info "안드로이드 스튜디오 업데이트를 확인합니다..."

    if command_exists studio || command_exists android-studio || [[ -d "/Applications/Android Studio.app" ]]; then
        # 현재 버전 확인 (개선된 방법)
        if command_exists brew; then
            # brew info 출력에서 버전 정보 추출 (여러 방법 시도)
            current_version=""
            
            # 방법 1: 첫 번째 줄에서 버전 추출 (예: android-studio: 2025.1.2.11)
            current_version=$(brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p')
            
            # 방법 2: Caskroom 경로에서 버전 추출 (fallback)
            if [[ -z "$current_version" ]]; then
                current_version=$(brew info --cask android-studio 2>/dev/null | grep "Caskroom" | grep -o '[0-9][0-9.]*[0-9]' | head -1)
            fi
            
            # 방법 3: 일반적인 버전 패턴 검색 (fallback)
            if [[ -z "$current_version" ]]; then
                current_version=$(brew info --cask android-studio 2>/dev/null | grep -o '[0-9]\{4\}\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            fi
            
            if [[ -n "$current_version" ]]; then
                log_info "현재 안드로이드 스튜디오 버전: $current_version"
            else
                log_info "안드로이드 스튜디오가 설치되어 있지만 버전 정보를 가져올 수 없습니다"
            fi
        fi
        
        # 안드로이드 스튜디오 업데이트 확인 (AUTO_YES 모드 지원)
        should_update=false
        if [[ "$AUTO_YES" == "true" ]]; then
            should_update=true
            log_info "자동 확인 모드: 안드로이드 스튜디오 업데이트 진행"
        elif confirm_action "안드로이드 스튜디오를 업데이트하시겠습니까?" "y" 30; then
            should_update=true
        fi

        if [[ "$should_update" == "true" ]]; then
            log_info "안드로이드 스튜디오 업데이트를 시작합니다..."
            
            if command_exists brew; then
                if brew upgrade --cask android-studio 2>/dev/null; then
                    log_success "안드로이드 스튜디오 업데이트 완료"
                else
                    log_warning "안드로이드 스튜디오 업데이트 실패 (이미 최신 버전이거나 정상적인 상황일 수 있음)"
                fi
            else
                log_warning "Homebrew가 없어 안드로이드 스튜디오를 업데이트할 수 없습니다"
            fi
        else
            log_info "안드로이드 스튜디오 업데이트를 건너뜁니다."
        fi
    else
        log_info "안드로이드 스튜디오가 설치되어 있지 않습니다."
    fi
=======
    log_message "안드로이드 스튜디오가 설치되어 있지 않습니다."
>>>>>>> origin/main
fi

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
<<<<<<< HEAD
            echo "  - $app"
        done
        echo ""
        
        should_install=false
        if [[ "$AUTO_YES" == "true" ]]; then
            should_install=true
            log_info "자동 확인 모드: 발견된 앱들을 설치합니다"
        elif confirm_action "이 앱들을 Homebrew Cask로 설치하시겠습니까?" "y" 30; then
            should_install=true
        fi

        if [[ "$should_install" == "true" ]]; then
            log_info "설치를 시작합니다..."
            installed_count=0
            total_count=${#found_apps[@]}
            
            for app in "${found_apps[@]}"; do
                ((installed_count++))
                show_progress "$installed_count" "$total_count" "$app 설치 중"
                
                if brew install --cask --force "$app" >/dev/null 2>&1; then
                    log_success "$app 설치 완료"
                else
                    log_warning "$app 설치 실패"
                fi
            done
            
            log_success "앱 설치 과정이 완료되었습니다."
        else
            log_info "설치가 취소되었습니다."
        fi
    else
        log_info "Homebrew Cask로 설치 가능한 새로운 앱이 없습니다."
    fi
else
    log_warning "Homebrew가 설치되어 있지 않아 앱 검색을 건너뜁니다."
fi

# 최종 요약 및 권장사항
print_section_header "시스템 상태 점검 및 권장사항" "5"

# Ruby 버전 확인 및 권장사항
print_subsection_header "Ruby 환경 점검" "5.1"
if command_exists ruby; then
    RUBY_VERSION=$(ruby -v 2>/dev/null | awk '{print $2}' || echo "unknown")
    if [[ "$RUBY_VERSION" != "unknown" ]]; then
        log_info "현재 Ruby 버전: $RUBY_VERSION"
        
        # 버전 비교 (3.2.0과 비교)
        if command_exists printf && command_exists sort; then
            min_version="3.2.0"
            if [[ "$(printf '%s\n' "$min_version" "$RUBY_VERSION" | sort -V | head -n1)" != "$min_version" ]]; then
                log_warning "현재 Ruby 버전 ($RUBY_VERSION)이 일부 gem 요구사항(3.2.0+)을 충족하지 않을 수 있습니다."
                log_info "권장 조치:"
                log_info "  1. Ruby 업그레이드: brew upgrade ruby"
                log_info "  2. 또는 호환 gem 설치: gem install erb -v 4.0.0 && gem install typeprof -v 0.20.0"
            else
                log_success "Ruby 버전이 요구사항을 충족합니다"
=======
            log_message "Installing $app..."
            if ! brew install --cask --force "$app"; then
                log_message "경고: $app 설치 실패"
>>>>>>> origin/main
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