#!/bin/zsh

# system_upgrade.sh - Automated System Upgrade Script for macOS
# v3.0 - Enhanced with improved common library integration
#
# This script performs various system upgrade tasks to keep packages,
# applications, and development tools up to date with enhanced stability
# and comprehensive logging.

# 에러 발생 시 스크립트 중단
set -Eeuo pipefail
IFS=$'\n\t'

# 공통 함수 라이브러리 로드
# zsh와 bash 모두 호환되는 스크립트 경로 얻기
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$SCRIPT_DIR/common.sh" || {
    echo "🛑 FATAL: common.sh를 로드할 수 없습니다"
    exit 1
}

# ==============================================
# 도움말 및 설정
# ==============================================

# 도움말 메시지 표시
show_help() {
    echo "macos-system-upgrade v3.0 - 시스템 업그레이드 도구"
    echo "사용법: $0 [옵션]"
    echo
    echo "옵션:"
    echo "  --help          이 도움말 메시지 표시"
    echo "  --dry-run       실제 업그레이드 없이 업그레이드할 내용 보기"
    echo "  --auto-yes      모든 확인 프롬프트에 자동으로 'yes' 응답"
    echo
    echo "선택적 업그레이드 옵션:"
    echo "  --no-brew       Homebrew 업그레이드 건너뛰기"
    echo "  --no-cask       Homebrew Cask 업그레이드 건너뛰기"
    echo "  --no-topgrade   topgrade 실행 건너뛰기"
    echo "  --no-android    Android Studio 업그레이드 건너뛰기"
    echo "  --no-apps       새로운 앱 검색/설치 건너뛰기"
    echo
    echo "예시:"
    echo "  $0                          # 모든 업그레이드 작업 대화형 실행"
    echo "  $0 --auto-yes               # 모든 확인에 자동 응답"
    echo "  $0 --dry-run                # 업그레이드할 내용만 미리보기"
    echo "  $0 --no-android --no-apps   # Android Studio와 앱 검색 제외"
    echo
    echo "참고: 일부 작업은 sudo 권한이 필요할 수 있습니다."
    echo
    show_common_version
    exit 0
}

# ==============================================
# 설정 변수
# ==============================================

# 명령줄 옵션 변수
DRY_RUN=false
AUTO_YES=false
SKIP_BREW=false
SKIP_CASK=false
SKIP_TOPGRADE=false
SKIP_ANDROID=false
SKIP_APPS=false

# ==============================================
# 명령줄 인수 처리
# ==============================================

for arg in "$@"; do
    case $arg in
        --help)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --auto-yes)
            AUTO_YES=true
            ;;
        --no-brew)
            SKIP_BREW=true
            ;;
        --no-cask)
            SKIP_CASK=true
            ;;
        --no-topgrade)
            SKIP_TOPGRADE=true
            ;;
        --no-android)
            SKIP_ANDROID=true
            ;;
        --no-apps)
            SKIP_APPS=true
            ;;
        *)
            echo "❌ 알 수 없는 옵션: $arg"
            echo "도움말을 보려면 $0 --help를 실행하세요."
            exit 1
            ;;
    esac
done

# ==============================================
# 시스템 초기화
# ==============================================

# 공통 시스템 초기화
init_common "system_upgrade"

# 업그레이드 관련 변수 설정
TEMP_DIR=$(create_temp_dir "brew_replace")
INSTALLED_APPS="$TEMP_DIR/apps_installed.txt"
AVAILABLE_CASKS="$TEMP_DIR/casks_available.txt"

# 종료 시 임시 파일 정리 설정
trap "cleanup_temp_files '$TEMP_DIR'" EXIT

# 시스템 상태 확인 함수 (개선된 버전)
verify_system_state() {
    log_info "시스템 상태 확인 중..."
    
    # Homebrew 상태 확인
    if ! check_homebrew_health; then
        log_warning "Homebrew 상태 이상 감지"
        log_info "Homebrew 복구를 시도합니다..."
        
        if command_exists brew; then
            if brew cleanup --prune=all 2>/dev/null && brew update --force 2>/dev/null; then
                log_success "Homebrew 복구 완료"
            else
                handle_error "Homebrew 복구 실패"
                return 1
            fi
        else
            handle_error "Homebrew가 설치되어 있지 않습니다"
            return 1
        fi
    fi

    # 시스템 캐시 디렉토리 확인
    if ! check_directory_writable "/Library/Caches"; then
        log_warning "시스템 캐시 디렉토리 접근 불가"
        
        if check_sudo; then
            if sudo mkdir -p /Library/Caches && sudo chmod 755 /Library/Caches; then
                log_success "시스템 캐시 디렉토리 복구 완료"
            else
                handle_error "시스템 캐시 디렉토리 생성/권한 설정 실패"
                return 1
            fi
        else
            log_warning "sudo 권한이 없어 시스템 캐시 디렉토리를 복구할 수 없습니다"
        fi
    fi

    # brew 관련 디렉토리 권한 확인 (개선된 버전)
    local brew_dirs=()
    
    # Intel Mac과 Apple Silicon Mac 모두 지원
    if [[ -d "/usr/local/Homebrew" ]]; then
        brew_dirs+=("/usr/local/Homebrew" "/usr/local/Cellar" "/usr/local/Caskroom")
    fi
    
    if [[ -d "/opt/homebrew" ]]; then
        brew_dirs+=("/opt/homebrew" "/opt/homebrew/Cellar" "/opt/homebrew/Caskroom")
    fi
    
    for dir in "${brew_dirs[@]}"; do
        if [[ -d "$dir" ]] && ! check_directory_writable "$dir"; then
            log_warning "$dir 디렉토리 권한 문제 감지"
            
            if check_sudo; then
                if sudo chown -R "$(whoami)" "$dir"; then
                    log_success "$dir 권한 복구 완료"
                else
                    handle_error "$dir 권한 복구 실패"
                    return 1
                fi
            else
                log_warning "sudo 권한이 없어 $dir 권한을 복구할 수 없습니다"
            fi
        fi
    done
    
    log_success "시스템 상태 확인 완료"
    return 0
}

# 캐시 상태 확인 함수 (개선된 버전)
check_cache_state() {
    log_info "캐시 상태 확인 중..."
    
    # Homebrew 캐시 확인
    if ! check_homebrew_health; then
        log_warning "Homebrew 캐시 재구성 필요"
        
        if command_exists brew; then
            if brew cleanup --prune=all 2>/dev/null && brew update --force 2>/dev/null; then
                log_success "Homebrew 캐시 재구성 완료"
                
                # 캐시 재구성 후 안정화를 위한 대기
                log_info "시스템 안정화를 위해 5초 대기..."
                sleep 5
            else
                handle_error "Homebrew 캐시 재구성 실패"
                return 1
            fi
        else
            handle_error "Homebrew를 찾을 수 없습니다"
            return 1
        fi
    fi
    
    log_success "캐시 상태 확인 완료"
    return 0
}

# ==============================================
# 메인 실행 부분
# ==============================================

# 스크립트 시작 메시지
print_script_start "시스템 업그레이드 프로세스"

# DRY RUN 모드 경고
if [[ "$DRY_RUN" == "true" ]]; then
    print_dry_run_warning
fi

# AUTO YES 모드 알림
if [[ "$AUTO_YES" == "true" ]]; then
    log_info "자동 확인 모드 활성화 - 모든 프롬프트에 자동으로 'yes' 응답합니다"
fi

# 시스템 상태 확인
print_section_header "시스템 상태 확인" "1"
if ! verify_system_state; then
    handle_error "시스템 상태 확인 실패" "true"
fi

# 캐시 상태 확인
if ! check_cache_state; then
    handle_error "캐시 상태 확인 실패" "true"
fi

print_section_divider

# Homebrew 업데이트
print_section_header "패키지 관리자 업데이트" "2"

print_subsection_header "Homebrew 업데이트" "2.1"
if [[ "$SKIP_BREW" == "true" ]]; then
    log_info "Homebrew 업데이트를 건너뜁니다 (--no-brew 옵션)"
elif [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: Homebrew 업데이트 예정"
    if command_exists brew; then
        log_info "DRY RUN: brew update 실행 예정"
        log_info "DRY RUN: brew upgrade 실행 예정"
    else
        log_warning "DRY RUN: Homebrew가 설치되어 있지 않습니다"
    fi
else
    log_info "Homebrew 업데이트를 시작합니다..."
    if command_exists brew; then
        if brew update 2>/dev/null; then
            log_success "Homebrew 업데이트 완료"
        else
            handle_error "Homebrew 업데이트 실패"
        fi
    else
        log_warning "Homebrew가 설치되어 있지 않습니다"
    fi
fi

print_subsection_header "Homebrew Cask 업데이트" "2.2"
if [[ "$SKIP_CASK" == "true" ]]; then
    log_info "Homebrew Cask 업데이트를 건너뜁니다 (--no-cask 옵션)"
elif [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: Homebrew Cask 업데이트 예정"
    if command_exists brew && command_exists cu; then
        log_info "DRY RUN: brew cu -a 실행 예정"
    elif command_exists brew; then
        log_warning "DRY RUN: brew-cask-upgrade가 설치되어 있지 않습니다"
    else
        log_warning "DRY RUN: Homebrew가 설치되어 있지 않습니다"
    fi
else
    log_info "Homebrew Cask 업데이트를 시작합니다..."
    if command_exists brew && command_exists cu; then
        if brew cu -a 2>/dev/null; then
            log_success "Homebrew Cask 업데이트 완료"
        else
            handle_error "Homebrew Cask 업데이트 실패"
        fi
    elif command_exists brew; then
        log_warning "brew-cask-upgrade가 설치되어 있지 않습니다"
        log_info "다음 명령으로 설치할 수 있습니다: brew tap buo/cask-upgrade"
    else
        log_warning "Homebrew가 설치되어 있지 않습니다"
    fi
fi

print_subsection_header "시스템 전체 업데이트 (topgrade)" "2.3"
if [[ "$SKIP_TOPGRADE" == "true" ]]; then
    log_info "topgrade 실행을 건너뜁니다 (--no-topgrade 옵션)"
elif [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: topgrade 실행 예정"
    if command_exists topgrade; then
        log_info "DRY RUN: topgrade --disable android_studio --yes 실행 예정"
    else
        log_info "DRY RUN: topgrade가 설치되어 있지 않음 - 설치 후 실행 예정"
    fi
else
    log_info "topgrade를 실행하여 모든 패키지와 앱을 업데이트합니다..."
    if ! command_exists topgrade; then
        log_info "topgrade가 설치되어 있지 않습니다. 설치를 시도합니다..."
        if command_exists brew; then
            if brew install topgrade 2>/dev/null; then
                log_success "topgrade 설치 완료"
            else
                handle_error "topgrade 설치 실패"
                log_warning "topgrade 없이 계속 진행합니다"
            fi
        else
            handle_error "Homebrew가 없어 topgrade를 설치할 수 없습니다"
        fi
    fi

    # topgrade 실행 (안드로이드 스튜디오 비활성화)
    if command_exists topgrade; then
        log_info "topgrade 실행 중..."
        if topgrade --disable android_studio --yes 2>/dev/null; then
            log_success "topgrade 실행 완료"
        else
            handle_error "topgrade 실행 실패"
        fi
    else
        log_warning "topgrade를 사용할 수 없습니다"
    fi
fi

print_section_divider

# 안드로이드 스튜디오 별도 관리
print_section_header "개별 애플리케이션 업데이트" "3"

print_subsection_header "안드로이드 스튜디오 업데이트" "3.1"
if [[ "$SKIP_ANDROID" == "true" ]]; then
    log_info "안드로이드 스튜디오 업데이트를 건너뜁니다 (--no-android 옵션)"
elif [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: 안드로이드 스튜디오 업데이트 확인 예정"
    if command_exists studio || command_exists android-studio || [[ -d "/Applications/Android Studio.app" ]]; then
        # DRY RUN에서도 현재 버전 표시
        if command_exists brew; then
            current_version=$(brew info --cask android-studio 2>/dev/null | head -1 | sed -n 's/.*android-studio: \([0-9][0-9.]*\).*/\1/p')
            if [[ -n "$current_version" ]]; then
                log_info "DRY RUN: 현재 안드로이드 스튜디오 버전: $current_version"
            fi
        fi
        log_info "DRY RUN: 안드로이드 스튜디오가 설치되어 있음"
        log_info "DRY RUN: brew upgrade --cask android-studio 실행 예정"
    else
        log_info "DRY RUN: 안드로이드 스튜디오가 설치되어 있지 않음"
    fi
else
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
        local should_update=false
        if [[ "$AUTO_YES" == "true" ]]; then
            should_update=true
            log_info "자동 확인 모드: 안드로이드 스튜디오 업데이트 진행"
        elif confirm_action "안드로이드 스튜디오를 업데이트하시겠습니까?" "y"; then
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
fi

print_section_divider

# 새로운 앱 검색 및 설치
print_section_header "새로운 애플리케이션 검색 및 설치" "4"

if [[ "$SKIP_APPS" == "true" ]]; then
    log_info "새로운 앱 검색 및 설치를 건너뜁니다 (--no-apps 옵션)"
elif [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: 새로운 앱 검색 및 설치 시뮬레이션"
    if command_exists brew; then
        log_info "DRY RUN: Applications 디렉토리에서 Homebrew Cask로 설치 가능한 앱 검색 예정"
        log_info "DRY RUN: 발견된 앱들의 설치 여부 확인 예정"
    else
        log_warning "DRY RUN: Homebrew가 설치되어 있지 않아 앱 검색 불가"
    fi
elif command_exists brew; then
    log_info "Homebrew Cask로 설치 가능한 앱을 검색합니다..."

    # 현재 설치된 Cask 목록 저장
    log_info "설치된 Cask 목록을 저장합니다..."
    if brew list --cask > "$INSTALLED_APPS" 2>/dev/null; then
        log_success "설치된 Cask 목록 저장 완료"
    else
        handle_error "설치된 Cask 목록 저장 실패"
    fi

    # 설치 가능한 Cask 목록 저장 (최적화된 검색)
    log_info "사용 가능한 Cask 목록을 저장합니다..."
    if brew search --casks "" 2>/dev/null | grep -v "No Cask found" > "$AVAILABLE_CASKS"; then
        log_success "사용 가능한 Cask 목록 저장 완료"
    else
        handle_error "사용 가능한 Cask 목록 저장 실패"
    fi

    # 발견된 앱을 저장할 배열
    declare -a found_apps

    # /Applications 디렉토리에서 앱 검색
    log_info "Applications 디렉토리에서 앱을 검색합니다..."
    if [[ -d "/Applications" ]]; then
        # 안전한 디렉토리 변경
        pushd "/Applications" >/dev/null 2>&1 || {
            handle_error "Applications 디렉토리 접근 실패"
        }
        
        # 각 .app 파일에 대해 확인 (성능 최적화)
        while IFS= read -r -d '' app; do
            app_name="${app#./}"
            app_name="${app_name%.app}"
            cask_name="${app_name// /-}"
            # zsh와 bash 모두 호환되는 소문자 변환
            if [[ -n "${ZSH_VERSION:-}" ]]; then
                cask_name="${(L)cask_name}"
            else
                cask_name="${cask_name,,}"
            fi
            
            # 설치 가능한 Cask 목록에 있는지 확인
            if [[ -f "$AVAILABLE_CASKS" ]] && grep -Fxq "$cask_name" "$AVAILABLE_CASKS" 2>/dev/null; then
                # 이미 설치된 Cask 목록에 없는 경우
                if [[ -f "$INSTALLED_APPS" ]] && ! grep -Fxq "$cask_name" "$INSTALLED_APPS" 2>/dev/null; then
                    # 앱 버전 확인
                    app_version=$(mdls -name kMDItemVersion "$app" 2>/dev/null | awk -F'"' '{print $2}' || echo "unknown")
                    log_info "Homebrew Cask로 설치 가능한 앱 발견: $app_name (현재 버전: $app_version)"
                    found_apps+=("$cask_name")
                fi
            fi
        done < <(find . -maxdepth 1 -name "*.app" -print0 2>/dev/null)
        
        # 원래 디렉토리로 복귀
        popd >/dev/null 2>&1 || true
    else
        log_warning "Applications 디렉토리를 찾을 수 없습니다."
    fi

    # 발견된 앱이 있는 경우
    if [[ ${#found_apps[@]} -gt 0 ]]; then
        echo ""
        log_info "다음 앱들을 Homebrew Cask로 설치할 수 있습니다:"
        for app in "${found_apps[@]}"; do
            echo "  - $app"
        done
        echo ""
        
        local should_install=false
        if [[ "$AUTO_YES" == "true" ]]; then
            should_install=true
            log_info "자동 확인 모드: 발견된 앱들을 설치합니다"
        elif confirm_action "이 앱들을 Homebrew Cask로 설치하시겠습니까?" "y"; then
            should_install=true
        fi
        
        if [[ "$should_install" == "true" ]]; then
            log_info "설치를 시작합니다..."
            local installed_count=0
            local total_count=${#found_apps[@]}
            
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
            fi
        fi
    fi
else
    log_info "Ruby가 설치되어 있지 않습니다."
fi

# 스크립트 완료 메시지
print_script_end "시스템 업그레이드 프로세스" "true"

# 추가 권장사항
echo ""
log_info "추가 권장사항:"
log_info "1. 시스템을 재시작하여 모든 업데이트를 완전히 적용하는 것을 권장합니다"
log_info "2. 정기적으로 이 스크립트를 실행하여 시스템을 최신 상태로 유지하세요"
log_info "3. 중요한 작업 전에는 Time Machine 백업을 확인하세요"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "🔍 DRY RUN 모드로 실행되었습니다"
    echo "   실제 변경사항은 적용되지 않았습니다."
    echo "   실제 업그레이드를 수행하려면 --dry-run 옵션 없이 다시 실행하세요."
fi