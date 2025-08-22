#!/bin/zsh

# system_cleanup.sh - Automated System Cleanup Script for macOS
# v3.0 - Enhanced with improved common library integration
#
# This script performs various system cleanup tasks to free up disk space
# and maintain system health. It includes comprehensive cleanup options
# for development tools, application caches, and system files with
# built-in error recovery and stability mechanisms.

# 에러 발생 시 스크립트 중단
set -Eeuo pipefail
IFS=$'\n\t'

# 안전한 PATH 설정 (시스템 명령어 접근 보장)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 명령어 alias 설정 (확실한 접근 보장)
alias awk='/usr/bin/awk'

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

# Print help message
show_help() {
    echo "macos-system-cleanup v3.0 - 시스템 정리 도구"
    echo "사용법: $0 [옵션]"
    echo
    echo "옵션:"
    echo "  --help          이 도움말 메시지 표시"
    echo "  --auto-clean    프롬프트 없이 모든 정리 작업 자동 실행"
    echo "  --dry-run       실제 정리 없이 정리할 내용 보기"
    echo
    echo "선택적 정리 옵션:"
    echo "  --no-brew       Homebrew 정리 건너뛰기"
    echo "  --no-npm        npm 캐시 정리 건너뛰기"
    echo "  --no-docker     Docker 정리 건너뛰기 (OpenWebUI 포함)"
    echo "  --no-android    Android Studio 정리 건너뛰기"
    echo
    echo "예시:"
    echo "  $0 --auto-clean               # 모든 정리 작업 자동 실행"
    echo "  $0 --auto-clean --no-docker   # Docker 제외하고 정리"
    echo "  $0 --dry-run                  # 정리할 내용만 미리보기"
    echo
    echo "참고: 시스템 캐시 정리를 위해서는 sudo 권한이 필요합니다."
    echo "      sudo $0 명령으로 실행하면 더 많은 항목을 정리할 수 있습니다."
    echo
    show_common_version
    exit 0
}

# ==============================================
# 설정 변수
# ==============================================

# 명령줄 옵션 변수
DRY_RUN=false
SKIP_BREW=false
SKIP_NPM=false
SKIP_DOCKER=false
SKIP_ANDROID=false
AUTO_CLEAN=false

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
        --no-brew)
            SKIP_BREW=true
            ;;
        --no-npm)
            SKIP_NPM=true
            ;;
        --no-docker)
            SKIP_DOCKER=true
            ;;
        --no-android)
            SKIP_ANDROID=true
            ;;
        --auto-clean)
            AUTO_CLEAN=true
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
init_common "system_cleanup"

# 사용자 레벨 캐시 정리 함수 (개선된 버전)
clean_user_caches() {
    local space_before
    space_before=$(get_free_space)
    
    log_info "사용자 레벨 캐시 정리 중..."
    
    # 브라우저 캐시 정리
    local cleaned_count=0
    
    # Chrome 캐시
    if [[ -d "$HOME/Library/Caches/Google/Chrome" ]]; then
        log_info "Chrome 캐시 정리 중..."
        local chrome_cleaned=0
        
        if safe_clear_cache "$HOME/Library/Caches/Google/Chrome/Default/Cache" "$DRY_RUN" 0; then
            ((chrome_cleaned++))
        fi
        
        if safe_clear_cache "$HOME/Library/Caches/Google/Chrome/Default/Code Cache" "$DRY_RUN" 0; then
            ((chrome_cleaned++))
        fi
        
        if [[ $chrome_cleaned -gt 0 ]]; then
            log_success "Chrome 캐시 정리 완료"
            ((cleaned_count++))
        else
            log_warning "Chrome 캐시 정리 일부 실패"
        fi
    fi
    
    # Firefox 캐시
    if [[ -d "$HOME/Library/Caches/Firefox" ]]; then
        log_info "Firefox 캐시 정리 중..."
        if safe_clear_cache "$HOME/Library/Caches/Firefox" "$DRY_RUN" 0; then
            log_success "Firefox 캐시 정리 완료"
            ((cleaned_count++))
        else
            log_warning "Firefox 캐시 정리 일부 실패"
        fi
    fi
    
    # Safari 캐시
    if [[ -d "$HOME/Library/Caches/com.apple.Safari" ]]; then
        log_info "Safari 캐시 정리 중..."
        if safe_clear_cache "$HOME/Library/Caches/com.apple.Safari" "$DRY_RUN" 0; then
            log_success "Safari 캐시 정리 완료"
            ((cleaned_count++))
        else
            log_warning "Safari 캐시 정리 일부 실패"
        fi
    fi
    
    # 개발 도구 캐시
    if check_xcode_installed && [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        log_info "Xcode DerivedData 정리 중..."
        if safe_clear_cache "$HOME/Library/Developer/Xcode/DerivedData" "$DRY_RUN" 0; then
            log_success "Xcode DerivedData 정리 완료"
            ((cleaned_count++))
        else
            log_warning "Xcode DerivedData 정리 일부 실패"
        fi
    fi
    
    if [[ -d "$HOME/Library/Developer/CoreSimulator/Caches" ]]; then
        log_info "iOS Simulator 캐시 정리 중..."
        if safe_clear_cache "$HOME/Library/Developer/CoreSimulator/Caches" "$DRY_RUN" 0; then
            log_success "iOS Simulator 캐시 정리 완료"
            ((cleaned_count++))
        else
            log_warning "iOS Simulator 캐시 정리 일부 실패"
        fi
    fi
    
    # 오래된 캐시 파일 정리 (30일 이상)
    log_info "오래된 캐시 파일 정리 중..."
    local old_cache_count=0
    old_cache_count=$(find "$HOME/Library/Caches" -type f -atime +30 2>/dev/null | wc -l)
    
    if [[ $old_cache_count -gt 0 ]]; then
        find "$HOME/Library/Caches" -type f -atime +30 -delete 2>/dev/null
        log_success "오래된 캐시 파일 ${old_cache_count}개 정리 완료"
    fi
    
    # 오래된 로그 파일 정리
    log_info "오래된 로그 파일 정리 중..."
    local old_log_count=0
    old_log_count=$(find "$HOME/Library/Application Support" -name "*.log" -type f -mtime +30 2>/dev/null | wc -l)
    
    if [[ $old_log_count -gt 0 ]]; then
        find "$HOME/Library/Application Support" -name "*.log" -type f -mtime +30 -delete 2>/dev/null
        log_success "오래된 로그 파일 ${old_log_count}개 정리 완료"
    fi
    
    # 결과 계산
    local space_after
    space_after=$(get_free_space)
    local space_saved_formatted
    space_saved_formatted=$(calculate_space_saved "$space_before" "$space_after")
    
    if [[ $cleaned_count -gt 0 ]]; then
        log_success "사용자 캐시 정리 완료 (${cleaned_count}개 카테고리). 절약된 공간: $space_saved_formatted"
    else
        log_info "정리할 사용자 캐시가 없습니다"
    fi
    
    return 0
}

# 시스템 레벨 캐시 정리 함수 (개선된 버전)
clean_system_caches() {
    if check_sudo; then
        local space_before
        space_before=$(get_free_space)
        
        log_info "시스템 레벨 캐시 정리 중..."
        
        # 시스템 캐시 정리 (안전한 방법 사용)
        log_info "시스템 캐시 정리 중..."
        local cache_cleaned=false
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN: /Library/Caches 디렉토리 정리 예정"
            cache_cleaned=true
        else
            # 개별 캐시 디렉토리를 안전하게 정리
            if [[ -d "/Library/Caches" ]]; then
                local cache_items=0
                while IFS= read -r -d '' item; do
                    if [[ -d "$item" ]]; then
                        if sudo rm -rf "$item" 2>/dev/null; then
                            ((cache_items++))
                        fi
                    elif [[ -f "$item" ]]; then
                        if sudo rm -f "$item" 2>/dev/null; then
                            ((cache_items++))
                        fi
                    fi
                done < <(sudo find /Library/Caches -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
                
                if [[ $cache_items -gt 0 ]]; then
                    log_success "시스템 캐시 정리 완료 (${cache_items}개 항목)"
                    cache_cleaned=true
                else
                    log_info "정리할 시스템 캐시가 없습니다"
                    cache_cleaned=true
                fi
            else
                log_info "시스템 캐시 디렉토리가 존재하지 않습니다"
                cache_cleaned=true
            fi
        fi
        
        if [[ "$cache_cleaned" != "true" ]]; then
            log_warning "일부 시스템 캐시를 정리할 수 없습니다"
        fi
        
        # 시스템 로그 정리 (중요 로그 보존)
        log_info "오래된 시스템 로그 정리 중..."
        local critical_logs=(
            "system.log"
            "kernel.log" 
            "secure.log"
            "auth.log"
            "install.log"
            "fsck_hfs.log"
        )
        
        # find 명령어에 사용할 -not -name 조건 생성
        local find_conditions=""
        for log_file in "${critical_logs[@]}"; do
            find_conditions="$find_conditions -not -name '$log_file'"
        done
        
        # 30일 이상 된 비중요 로그 파일 삭제
        local log_count=0
        log_count=$(eval "sudo find /var/log -type f $find_conditions -mtime +30 2>/dev/null | wc -l")
        
        if [[ $log_count -gt 0 ]]; then
            eval "sudo find /var/log -type f $find_conditions -mtime +30 -delete 2>/dev/null"
            log_success "오래된 시스템 로그 ${log_count}개 정리 완료"
        else
            log_info "정리할 오래된 시스템 로그가 없습니다"
        fi
        
        # 결과 계산
        local space_after
        space_after=$(get_free_space)
        local space_saved_formatted
        space_saved_formatted=$(calculate_space_saved "$space_before" "$space_after")
        
        log_success "시스템 캐시 정리 완료. 절약된 공간: $space_saved_formatted"
    else
        log_warning "시스템 레벨 캐시 정리를 건너뜁니다 - sudo 권한이 필요합니다"
        log_info "시스템 캐시를 정리하려면 sudo로 스크립트를 실행하세요"
    fi
    
    return 0
}

# ==============================================
# 메인 실행 부분
# ==============================================

# 스크립트 시작 메시지
print_script_start "시스템 정리 프로세스"

# DRY RUN 모드 경고
if [[ "$DRY_RUN" == "true" ]]; then
    print_dry_run_warning
fi

# AUTO CLEAN 모드 알림
if [[ "$AUTO_CLEAN" == "true" ]]; then
    log_info "자동 정리 모드 활성화 - 모든 프롬프트에 자동으로 정리를 진행합니다"
fi

# 초기 시스템 상태 기록
INITIAL_FREE_SPACE=$(get_free_space)
INITIAL_FREE_SPACE_READABLE=$(df -h / | sed -n '2p' | awk '{print $4}')
log_info "초기 여유 공간: $INITIAL_FREE_SPACE_READABLE"

# 섹션 1: 시스템 개요
print_section_header "시스템 개요" "1"
df -h / | tee -a "$LOG_FILE"

print_section_divider

# 섹션 2: 시스템 라이브러리 및 캐시 정리
print_section_header "시스템 라이브러리 및 캐시 정리" "2"

if [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: 시스템 및 사용자 캐시 정리 시뮬레이션"
    log_info "DRY RUN: 실제 정리 없이 정리 대상만 확인합니다"
else
    if [[ "$AUTO_CLEAN" == "true" ]] || confirm_action "사용자 캐시를 정리하시겠습니까?" "y"; then
        if ! clean_user_caches; then
            log_warning "사용자 캐시 정리에 문제가 있었지만 계속 진행합니다..."
        fi
    else
        log_info "사용자 캐시 정리를 건너뜁니다"
    fi

    if [[ "$AUTO_CLEAN" == "true" ]] || confirm_action "시스템 캐시를 정리하시겠습니까?" "y"; then
        if ! clean_system_caches; then
            log_warning "시스템 캐시 정리에 문제가 있었지만 계속 진행합니다..."
        fi
    else
        log_info "시스템 캐시 정리를 건너뜁니다"
    fi
fi

print_section_divider

# 섹션 3: Time Machine 로컬 스냅샷
print_section_header "Time Machine 로컬 스냅샷" "3"

# Time Machine 스냅샷 제거 함수 (개선된 버전)
clean_time_machine_snapshots() {
    log_info "로컬 스냅샷 제거 중..."
    
    if check_sudo; then
        if sudo tmutil thinlocalsnapshots / 9999999999999999 1 2>&1 | tee -a "$LOG_FILE"; then
            log_success "로컬 스냅샷 제거 완료"
            return 0
        else
            handle_error "로컬 스냅샷 제거 실패"
            return 1
        fi
    else
        log_warning "sudo 권한이 없어 로컬 스냅샷을 제거할 수 없습니다"
        return 1
    fi
}

if [[ "$DRY_RUN" == true ]]; then
    log_info "DRY RUN: Time Machine 로컬 스냅샷 확인 및 관리 시뮬레이션"
else
    if command_exists tmutil; then
        log_info "Time Machine 로컬 스냅샷 확인 중..."
        local_snapshots=$(tmutil listlocalsnapshots / 2>/dev/null)
        
        if [[ -n "$local_snapshots" ]]; then
            log_info "다음 로컬 스냅샷을 발견했습니다:"
            echo "$local_snapshots" | tee -a "$LOG_FILE"
            
            # 스냅샷 개수 계산
            snapshot_count=$(echo "$local_snapshots" | wc -l)
            log_info "총 ${snapshot_count}개의 로컬 스냅샷이 있습니다"
            
            if [[ "$AUTO_CLEAN" == true ]]; then
                log_info "자동 정리 모드: 로컬 스냅샷 정리 중..."
                if ! clean_time_machine_snapshots; then
                    log_warning "Time Machine 스냅샷 정리에 실패했지만 계속 진행합니다..."
                fi
            else
                if confirm_action "로컬 스냅샷을 제거하시겠습니까?" "n"; then
                    if ! clean_time_machine_snapshots; then
                        log_warning "Time Machine 스냅샷 정리에 실패했지만 계속 진행합니다..."
                    fi
                else
                    log_info "로컬 스냅샷 정리를 건너뜁니다"
                fi
            fi
        else
            log_info "로컬 스냅샷을 찾을 수 없습니다"
        fi
    else
        log_warning "tmutil 명령어를 찾을 수 없어 Time Machine 정리를 건너뜁니다"
    fi
fi

print_section_divider

# 섹션 4: 개발 도구 정리
print_section_header "개발 도구 정리" "4"

# 서브섹션 4.1: Homebrew 정리 (개선된 버전)
clean_homebrew() {
    local auto_clean_mode="${1:-false}"
    
    # root 사용자 확인
    if [[ "$(id -u)" == "0" ]]; then
        log_warning "Homebrew는 root 사용자로 실행할 수 없습니다. Homebrew 정리를 건너뜁니다."
        return 1
    fi
    
    # Homebrew 상태 확인
    if ! check_homebrew_health; then
        log_warning "Homebrew 상태에 문제가 있습니다. 복구를 시도합니다..."
        
        # 기본적인 복구 시도
        if brew update --force 2>/dev/null && brew cleanup --prune=all 2>/dev/null; then
            log_success "Homebrew 복구 완료"
        else
            log_warning "Homebrew 복구에 실패했지만 계속 진행합니다"
        fi
    fi
    
    local space_before
    space_before=$(get_free_space)
    
    if confirm_action "Homebrew 및 설치된 패키지를 업데이트하시겠습니까?" "y"; then
        log_info "Homebrew 및 설치된 패키지 업데이트 중..."
        if HOMEBREW_NO_AUTO_UPDATE=1 brew update 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Homebrew 업데이트 완료"
        else
            handle_error "Homebrew 업데이트 실패"
            return 1
        fi

        if HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade 2>&1 | tee -a "$LOG_FILE"; then
            log_success "패키지 업그레이드 완료"
        else
            handle_error "패키지 업그레이드 실패"
            return 1
        fi
    else
        log_info "Homebrew 업데이트를 건너뜁니다"
    fi
    
    if confirm_action "brew doctor를 실행하여 잠재적 문제를 확인하시겠습니까?" "y"; then
        log_info "brew doctor를 실행하여 잠재적 문제를 확인합니다..."
        if brew doctor 2>&1 | tee -a "$LOG_FILE"; then
            log_success "brew doctor 검사 통과"
        else
            log_warning "brew doctor 검사에서 문제를 발견했지만 계속 진행합니다"
        fi
    else
        log_info "brew doctor 실행을 건너뜁니다"
    fi
    
    # 오래된 패키지 확인
    log_info "오래된 패키지 확인 중..."
    local outdated_packages
    outdated_packages=$(brew outdated 2>/dev/null)
    if [[ -n "$outdated_packages" ]]; then
        log_info "오래된 패키지 목록:"
        echo "$outdated_packages" | tee -a "$LOG_FILE"
    else
        log_success "모든 패키지가 최신 상태입니다"
    fi
    
    # 사용하지 않는 의존성 확인
    log_info "사용하지 않는 의존성 확인 중..."
    local unused_deps
    unused_deps=$(brew autoremove -n 2>/dev/null)
    if [[ -n "$unused_deps" ]]; then
        log_info "사용하지 않는 의존성:"
        echo "$unused_deps" | tee -a "$LOG_FILE"
        
        if [[ "$auto_clean_mode" == "true" ]] || confirm_action "사용하지 않는 의존성을 제거하시겠습니까?" "n"; then
            log_info "사용하지 않는 의존성 제거 중..."
            if brew autoremove 2>&1 | tee -a "$LOG_FILE"; then
                log_success "사용하지 않는 의존성 제거 완료"
            else
                handle_error "사용하지 않는 의존성 제거 실패"
            fi
        fi
    else
        log_success "사용하지 않는 의존성이 없습니다"
    fi
    
    if confirm_action "Homebrew 캐시 및 오래된 버전을 정리하시겠습니까?" "y"; then
        log_info "Homebrew 캐시 및 오래된 버전 정리 중..."
        if brew cleanup --prune=all 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Homebrew 정리 완료"
        else
            handle_error "Homebrew 정리 실패"
            return 1
        fi
    else
        log_info "Homebrew 캐시 정리를 건너뜁니다"
    fi
    
    # 결과 계산
    local space_after
    space_after=$(get_free_space)
    local space_saved_formatted
    space_saved_formatted=$(calculate_space_saved "$space_before" "$space_after")
    
    log_success "Homebrew 정리 완료. 절약된 공간: $space_saved_formatted"
    return 0
}

if [ "$SKIP_BREW" = true ]; then
    log_message "Skipping Homebrew cleanup (--no-brew flag detected)"
else
    if command -v brew &>/dev/null; then
        # Get initial size of Homebrew cache
        brew_cache_dir=$(brew --cache)
        brew_cache_size_before=$(du -sh "$brew_cache_dir" 2>/dev/null | awk '{print $1}')
        log_message "Homebrew cache size before cleaning: $brew_cache_size_before"
        
        if [ "$DRY_RUN" = true ]; then
            log_message "DRY RUN: Would update Homebrew and installed packages"
            log_message "DRY RUN: Would run brew doctor"
            log_message "DRY RUN: Would check for outdated packages"
            log_message "DRY RUN: Would remove unused dependencies"
            log_message "DRY RUN: Would clean up Homebrew cache and old versions"
        else
            if [[ "$AUTO_CLEAN" == "true" ]] || confirm_action "Homebrew를 정리하시겠습니까?" "y"; then
                if ! clean_homebrew "$1"; then
                    log_message "⚠️ Warning: Some Homebrew cleanup operations failed, but continuing..."
                fi
                brew_cache_size_after=$(du -sh "$brew_cache_dir" 2>/dev/null | awk '{print $1}')
                log_message "Homebrew cache size after cleaning: $brew_cache_size_after"
            else
                log_message "Skipping Homebrew cleanup"
            fi
        fi
    else
        log_message "Homebrew is not installed on this system"
    fi
fi

# Subsection 4.2: npm Cleanup
if [ "$SKIP_NPM" = true ]; then
    log_message "Skipping npm cache cleanup (--no-npm flag detected)"
else
    if command -v npm &>/dev/null; then
        # Get npm cache size before cleaning
        npm_cache_dir=$(npm config get cache)
        if [ -d "$npm_cache_dir" ]; then
            npm_cache_size_before=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "npm cache size before cleaning: $npm_cache_size_before"
            
            if [ "$DRY_RUN" = true ]; then
                log_message "DRY RUN: Would clean npm cache"
                log_message "DRY RUN: Would free approximately $npm_cache_size_before"
            else
                # Clean npm cache with verification
                log_message "Cleaning npm cache..."
                if npm cache clean --force 2>&1 | tee -a "$LOG_FILE"; then
                    # Verify cache was actually cleaned
                    npm_cache_size_after=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
                    log_message "npm cache size after cleaning: $npm_cache_size_after"
                    
                    if [ "$npm_cache_size_after" = "$npm_cache_size_before" ]; then
                        log_message "WARNING: npm cache size did not change. This might indicate a permission issue."
                    fi
                else
                    handle_error "Failed to clean npm cache"
                fi
                
                # Check for global packages and prune if auto-clean is enabled
                if [[ "$AUTO_CLEAN" == "true" ]]; then
                    log_message "Checking for outdated and unused global npm packages..."
                    
                    # Get list of global packages
                    log_message "Checking for outdated global packages..."
                    npm_outdated=$(npm outdated -g 2>/dev/null)
                    if [ -n "$npm_outdated" ]; then
                        log_message "Found outdated global packages:"
                        echo "$npm_outdated" | tee -a "$LOG_FILE"
                        log_message "Auto-updating outdated global packages..."
                        npm update -g 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Failed to update some global packages"
                    else
                        log_message "No outdated global packages found"
                    fi
                    
                    # 'npm prune -g' 명령어는 오류를 발생시키므로 다른 방법으로 대체
                    # 실제로는 사용하지 않는 패키지를 판단하기 어려우므로 자동 정리는 생략
                    log_message "NOTE: Automatic removal of unused global packages is skipped"
                    log_message "To manage global packages manually, use 'npm list -g --depth=0' to view installed packages"
                fi
            fi
        else
            log_message "npm cache directory not found"
        fi
    else
        log_message "npm is not installed on this system"
    fi
fi

# Subsection 4.3: Yarn Cache Cleanup
if command -v yarn &>/dev/null; then
    log_message "Yarn is installed. Checking cache..."
    
    # Get yarn cache directory
    yarn_cache_dir=$(yarn cache dir 2>/dev/null)
    
    if [ -d "$yarn_cache_dir" ]; then
        yarn_cache_size=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
        log_message "Yarn cache size: $yarn_cache_size"
        
        if [ "$DRY_RUN" = true ]; then
            log_message "DRY RUN: Would clean Yarn cache"
        elif [[ "$AUTO_CLEAN" == "true" ]]; then
            log_message "Auto-cleaning Yarn cache..."
            yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
            
            # Verify cleaning was successful
            yarn_cache_size_after=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "Yarn cache size after cleaning: $yarn_cache_size_after"
        else
            if confirm_action "Would you like to clean the Yarn cache?" "n"; then
                log_message "Cleaning Yarn cache..."
                yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
                yarn_cache_size_after=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
                log_message "Yarn cache size after cleaning: $yarn_cache_size_after"
            else
                log_message "Skipping Yarn cache cleanup"
            fi
        fi
    else
        log_message "Yarn cache directory not found"
    fi
else
    log_message "Yarn is not installed on this system"
fi

# Subsection 4.4: node_modules Cleanup
log_message "Checking for large node_modules directories..."

# Find large node_modules directories
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for large node_modules directories"
else
    # Find top 10 largest node_modules directories
    log_message "Searching for large node_modules directories..."
    large_dirs=$(find "$HOME" -type d -name "node_modules" -not -path "*/\.*" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_dirs" ]; then
        log_message "Found the following large node_modules directories:"
        echo "$large_dirs" | tee -a "$LOG_FILE"
        
        if [[ "$AUTO_CLEAN" == "true" ]]; then
            log_message "Checking for unused node_modules (projects not modified in last 90 days)..."
            
            # 검색 범위를 일반적인 프로젝트 디렉토리로 제한
            log_message "Searching in common project directories only..."
            
            # 특정 디렉토리만 검색 (일반적인 프로젝트 위치)
            project_dirs=("$HOME/Documents" "$HOME/Projects" "$HOME/Development" "$HOME/Dev")
            
            old_projects=""
            for dir in "${project_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    log_message "Scanning $dir for unused node_modules..."
                    result=$(find "$dir" -type d -name "node_modules" -not -path "*/\.*" -mtime +90 -exec dirname {} \; 2>/dev/null || echo "")
                    if [ -n "$result" ]; then
                        old_projects="${old_projects}${result}\n"
                    fi
                fi
            done
            
            if [ -n "$old_projects" ]; then
                log_message "Found the following potentially unused projects (not modified in 90+ days):"
                echo -e "$old_projects" | tee -a "$LOG_FILE"
                log_message "You may want to consider removing these manually."
            else
                log_message "No potentially unused node_modules directories found."
            fi
        fi
    else
        log_message "No large node_modules directories found."
    fi
fi

log_message "node_modules cleanup section completed."

# Subsection 4.5: Docker Cleanup
if [ "$SKIP_DOCKER" = true ]; then
    log_message "Skipping Docker cleanup (--no-docker flag detected)"
else
    if check_docker_daemon; then
        log_message "Docker is running. Proceeding with cleanup..."
        docker system df 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Could not get Docker disk usage info"
        
        if [ "$DRY_RUN" = true ]; then
            # Dry run mode - show what would be cleaned
            log_message "DRY RUN: Would clean the following Docker resources:"
            docker images --filter "dangling=true" --format "{{.Repository}}:{{.Tag}} ({{.Size}})" 2>/dev/null | tee -a "$LOG_FILE" || log_message "No dangling images found"
            docker ps -a --filter "status=exited" --format "{{.Names}} ({{.Image}})" 2>/dev/null | tee -a "$LOG_FILE" || log_message "No exited containers found"
            docker volume ls --filter "dangling=true" --format "{{.Name}}" 2>/dev/null | tee -a "$LOG_FILE" || log_message "No dangling volumes found"
        elif [[ "$AUTO_CLEAN" == "true" ]]; then
            log_message "Auto-cleaning Docker resources (--auto-clean flag detected)..."
            
            # 안전하게 실행 (각 명령마다 오류 처리)
            log_message "Pruning Docker system (images, containers, networks)..."
            if docker system prune -f 2>&1 | tee -a "$LOG_FILE"; then
                log_message "Successfully pruned Docker system"
            else
                log_message "WARNING: Docker system prune failed. Continuing..."
            fi

            log_message "Pruning Docker volumes..."
            if docker volume prune -f 2>&1 | tee -a "$LOG_FILE"; then
                log_message "Successfully pruned Docker volumes"
            else
                log_message "WARNING: Docker volume prune failed. Continuing..."
            fi
            
            log_message "Docker cleanup completed"
        else
            if confirm_action "Clean unused Docker resources?" "n"; then
                log_message "Cleaning Docker resources..."
                docker system prune -f 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Docker system prune failed"
                if confirm_action "Also clean unused Docker volumes? This will delete ALL volumes not used by at least one container" "n"; then
                    log_message "Cleaning Docker volumes..."
                    docker volume prune -f 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Docker volume prune failed"
                else
                    log_message "Skipping Docker volumes cleanup"
                fi
            else
                log_message "Skipping Docker cleanup"
            fi
        fi
    else
        log_message "Skipping Docker cleanup - daemon is not running"
    fi
fi

log_message "Docker cleanup section completed, moving to OpenWebUI cleanup..."

# Subsection 4.6: OpenWebUI Cleanup
log_message "SUBSECTION 4.6: OpenWebUI Cleanup"

if [ "$SKIP_DOCKER" = true ]; then
    log_message "Skipping OpenWebUI cleanup (--no-docker flag detected, OpenWebUI uses Docker)"
else
    # Docker 먼저 확인
    docker_running=false
    if docker info &>/dev/null; then
        docker_running=true
    else
        log_message "WARNING: Docker daemon is not running. Skipping OpenWebUI checks."
    fi
    
    if [ "$docker_running" = true ]; then
        # Check if OpenWebUI is installed/running
        if docker ps | grep -q "open-webui"; then
            log_message "OpenWebUI detected. Checking data volume..."
            
            # Get data volume size before cleaning safely
            openwebui_volume_size_before=$(docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -sh /vol" 2>/dev/null | awk '{print $1}' || echo "unknown")
            # Get numeric size in bytes for comparison
            openwebui_bytes_before=$(docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -b /vol | cut -f1" 2>/dev/null || echo "0")
            log_message "OpenWebUI data volume size before cleaning: $openwebui_volume_size_before"
            
            if [ "$DRY_RUN" = true ]; then
                # Dry run mode - show what would be cleaned
                log_message "DRY RUN: Would clean OpenWebUI cache files and temporary data"
                log_message "DRY RUN: Would preserve conversation history and important settings"
            elif [[ "$AUTO_CLEAN" == "true" ]]; then
                # Auto-clean mode
                log_message "Auto-cleaning OpenWebUI data (--auto-clean flag detected)..."
                
                # Clean cache files and temporary data - 안전한 명령어 실행
                log_message "Removing cache and temporary files..."
                if docker run --rm -v open-webui_open-webui:/data alpine sh -c "
                    # Remove cache directory
                    find /data -name '*cache*' -type d -exec rm -rf {} \; 2>/dev/null || true
                    
                    # Remove temporary files
                    find /data -name '*.temp' -o -name '*.tmp' -o -name '*.downloading' -o -name '*.part' -delete 2>/dev/null || true
                    
                    # Remove old log files
                    find /data -name '*.log' -type f -mtime +30 -delete 2>/dev/null || true
                    
                    # Check for and remove DeepSeek model files (if any left)
                    find /data -name '*deepseek*' -exec rm -rf {} \; 2>/dev/null || true
                    
                    echo 'OpenWebUI data cleanup completed'
                " 2>&1 | tee -a "$LOG_FILE"; then
                    log_message "Successfully cleaned OpenWebUI files"
                else
                    log_message "WARNING: OpenWebUI cleanup may have failed. Continuing..."
                fi
                
                # Restart OpenWebUI to apply changes
                log_message "Restarting OpenWebUI container to apply changes..."
                if docker restart open-webui 2>&1 | tee -a "$LOG_FILE"; then
                    log_message "Successfully restarted OpenWebUI container"
                else
                    log_message "WARNING: Failed to restart OpenWebUI container. It may be in an inconsistent state."
                fi
            else
                # 이 부분은 입력을 받으므로 복잡합니다 - 단순화하여 안전하게 실행
                log_message "OpenWebUI cleanup requires interactive input."
                
                if confirm_action "Clean cache files?" "n"; then
                    log_message "Cleaning OpenWebUI cache files..."
                    if docker run --rm -v open-webui_open-webui:/data alpine sh -c "
                        find /data -name '*cache*' -type d -exec rm -rf {} \; 2>/dev/null || echo 'No cache directories found or already cleaned'
                        find /data -name '*.temp' -o -name '*.tmp' -o -name '*.downloading' -o -name '*.part' -delete 2>/dev/null || echo 'No temporary files found or already cleaned'
                        echo 'OpenWebUI cache cleanup completed'
                    " 2>&1 | tee -a "$LOG_FILE"; then
                        log_message "OpenWebUI cache cleanup completed successfully"
                    else
                        log_message "WARNING: OpenWebUI cache cleanup failed"
                    fi
                    if confirm_action "Would you like to restart the OpenWebUI container to apply changes?" "n"; then
                        log_message "Restarting OpenWebUI container..."
                        if docker restart open-webui 2>&1 | tee -a "$LOG_FILE"; then
                            log_message "Successfully restarted OpenWebUI container"
                        else
                            log_message "WARNING: Failed to restart OpenWebUI container"
                        fi
                    else
                        log_message "Skipping OpenWebUI container restart"
                    fi
                else
                    log_message "Skipping all OpenWebUI cleanup options"
                fi
            fi
            
            # Get data volume size after cleaning - 안전한 체크
            openwebui_volume_size_after=$(docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -sh /vol" 2>/dev/null | awk '{print $1}' || echo "unknown")
            # Get numeric size in bytes for comparison
            openwebui_bytes_after=$(docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -b /vol | cut -f1" 2>/dev/null || echo "0")
            log_message "OpenWebUI data volume size after cleaning: $openwebui_volume_size_after"
            
            # Calculate and display space saved - 에러 처리
            if [[ $openwebui_bytes_before =~ ^[0-9]+$ ]] && [[ $openwebui_bytes_after =~ ^[0-9]+$ ]] && [ "$openwebui_bytes_before" -gt 0 ] && [ "$openwebui_bytes_after" -gt 0 ]; then
                bytes_saved=$((openwebui_bytes_before - openwebui_bytes_after))
                if [ "$bytes_saved" -gt 0 ]; then
                    log_message "Space saved: $(format_disk_space "$bytes_saved")"
                elif [ "$bytes_saved" -lt 0 ]; then
                    log_message "Volume size increased by: $(format_disk_space "$((bytes_saved * -1))")"
                else
                    log_message "No change in volume size"
                fi
            else
                log_message "Could not accurately calculate space saved (error getting volume sizes)"
            fi
        else
            log_message "OpenWebUI not detected on this system (containers not running)"
            
            # Check if volume exists even if container is not running
            if docker volume ls | grep -q "open-webui_open-webui"; then
                log_message "OpenWebUI data volume found but container not running"
                
                check_volume=""
                if [[ "$AUTO_CLEAN" == "true" ]]; then
                    check_volume="y"
                    log_message "Auto-cleaning OpenWebUI volume..."
                else
                    if confirm_action "Would you like to check OpenWebUI data volume for cleanup?" "n"; then
                        check_volume="y"
                    else
                        check_volume="n"
                    fi
                fi
                
                if [[ "$check_volume" == "y" ]]; then
                    log_message "Cleaning OpenWebUI data volume even though container is not running..."
                    if docker run --rm -v open-webui_open-webui:/data alpine sh -c "
                        # Remove cache directory
                        find /data -name '*cache*' -type d -exec rm -rf {} \; 2>/dev/null || echo 'No cache directories found'
                        
                        # Remove temporary files
                        find /data -name '*.temp' -o -name '*.tmp' -o -name '*.downloading' -o -name '*.part' -delete 2>/dev/null || echo 'No temporary files found'
                        
                        # Report volume size after cleaning
                        echo 'Current volume size:'
                        du -sh /data
                    " 2>&1 | tee -a "$LOG_FILE"; then
                        log_message "OpenWebUI volume cleanup completed successfully"
                    else
                        log_message "WARNING: OpenWebUI volume cleanup failed"
                    fi
                else
                    log_message "Skipping OpenWebUI volume cleanup"
                fi
            else
                log_message "No OpenWebUI data volumes found"
            fi
        fi
    else
        log_message "Docker is not running. Skipping OpenWebUI cleanup."
    fi
fi

log_message "OpenWebUI cleanup section completed, moving to Android Studio cleanup..."

# Subsection 4.7: Android Studio Cleanup
if [ "$SKIP_ANDROID" = true ]; then
    log_message "Skipping Android Studio cleanup (--no-android flag detected)"
elif [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would clean Android Studio caches and temporary files"
    log_message "DRY RUN: Would check for old Android Studio versions and clean invalid data"
else
    log_message "Starting Android Studio cleanup..."
    
    # Check for multiple Android Studio versions
    android_studio_dirs=$(ls -d "$HOME/Library/Application Support/Google/AndroidStudio"* 2>/dev/null || echo "")
    if [ -n "$android_studio_dirs" ]; then
        log_message "Found Android Studio installations:"
        echo "$android_studio_dirs" | while read -r dir; do
            version=$(basename "$dir")
            size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            log_message "  $version: $size"
        done | tee -a "$LOG_FILE"
        
        # Count number of versions
        version_count=$(echo "$android_studio_dirs" | wc -l)
        if [ "$version_count" -gt 1 ]; then
            log_message "Multiple Android Studio versions detected ($version_count versions)"
            
            if [[ "$AUTO_CLEAN" == "true" ]]; then
                log_message "Auto-cleaning old Android Studio data..."
                # Keep only the latest version (remove all but the newest)
                latest_version=$(echo "$android_studio_dirs" | sort | tail -n 1)
                old_versions=$(echo "$android_studio_dirs" | grep -v "$latest_version")
                if [ -n "$old_versions" ]; then
                    echo "$old_versions" | while read -r old_dir; do
                        if [ -d "$old_dir" ]; then
                            version_name=$(basename "$old_dir")
                            log_message "Removing old Android Studio data: $version_name"
                            rm -rf "$old_dir" 2>/dev/null || log_message "Warning: Could not remove $old_dir"
                        fi
                    done
                else
                    log_message "No old versions to clean"
                fi
            else
                if confirm_action "Clean old Android Studio versions (keep latest only)?" "n"; then
                    latest_version=$(echo "$android_studio_dirs" | sort | tail -n 1)
                    old_versions=$(echo "$android_studio_dirs" | grep -v "$latest_version")
                    if [ -n "$old_versions" ]; then
                        echo "$old_versions" | while read -r old_dir; do
                            if [ -d "$old_dir" ]; then
                                version_name=$(basename "$old_dir")
                                log_message "Removing old Android Studio data: $version_name"
                                rm -rf "$old_dir" 2>/dev/null || log_message "Warning: Could not remove $old_dir"
                            fi
                        done
                    else
                        log_message "No old versions to clean"
                    fi
                else
                    log_message "Skipping Android Studio version cleanup"
                fi
            fi
        else
            log_message "No Android Studio installations found"
        fi
    
    # Clean Android Studio preferences
    as_prefs="$HOME/Library/Preferences/com.google.android.studio.plist"
    if [ -f "$as_prefs" ]; then
        log_message "Found Android Studio preferences file"
        # Check file modification time (cleanup if older than 90 days and auto-clean is enabled)
        if [[ "$AUTO_CLEAN" == "true" ]] && find "$as_prefs" -mtime +90 -print 2>/dev/null | grep -q .; then
            log_message "Removing old Android Studio preferences (older than 90 days)"
            rm -f "$as_prefs" 2>/dev/null || log_message "Warning: Could not remove preferences file"
        fi
    fi
    
    # Clean Android Emulator preferences
    emulator_prefs="$HOME/Library/Preferences/com.android.Emulator.plist"
    if [ -f "$emulator_prefs" ]; then
        log_message "Found Android Emulator preferences file"
        if [[ "$AUTO_CLEAN" == "true" ]] && find "$emulator_prefs" -mtime +90 -print 2>/dev/null | grep -q .; then
            log_message "Removing old Android Emulator preferences (older than 90 days)"
            rm -f "$emulator_prefs" 2>/dev/null || log_message "Warning: Could not remove emulator preferences"
        fi
    fi
    
    # Gradle 캐시 정리 (개선된 버전)
    if [ -d "$HOME/.gradle/caches" ]; then
        gradle_cache_size_before=$(du -sh "$HOME/.gradle/caches" 2>/dev/null | awk '{print $1}')
        log_message "Gradle cache size before cleaning: $gradle_cache_size_before"
        
        log_message "Cleaning Gradle cache files older than 30 days..."
        find "$HOME/.gradle/caches" -type f -mtime +30 -delete 2>/dev/null || true
        
        # Clean gradle daemon logs
        if [ -d "$HOME/.gradle/daemon" ]; then
            find "$HOME/.gradle/daemon" -name "*.log" -mtime +7 -delete 2>/dev/null || true
        fi
        
        gradle_cache_size_after=$(du -sh "$HOME/.gradle/caches" 2>/dev/null | awk '{print $1}')
        log_message "Gradle cache size after cleaning: $gradle_cache_size_after"
    else
        log_message "Gradle cache directory not found, skipping..."
    fi
    
    # Android SDK 정리 (개선된 버전)
    if [ -d "$HOME/Library/Android/sdk" ]; then
        log_message "Found Android SDK directory"
        
        # Clean temp files
        if [ -d "$HOME/Library/Android/sdk/temp" ]; then
            log_message "Cleaning Android SDK temp files..."
            rm -rf "$HOME/Library/Android/sdk/temp"/* 2>/dev/null || true
        fi
        
        # Clean build-tools cache
        if [ -d "$HOME/Library/Android/sdk/build-tools" ]; then
            find "$HOME/Library/Android/sdk/build-tools" -name "*.tmp" -delete 2>/dev/null || true
        fi
        
        # Clean platform-tools logs
        if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
            find "$HOME/Library/Android/sdk/platform-tools" -name "*.log" -mtime +30 -delete 2>/dev/null || true
        fi
        
        log_message "Android SDK cleanup completed"
    else
        log_message "Android SDK directory not found, skipping..."
    fi
    
    # Android 디렉토리 정리
    if [ -d "$HOME/.android" ]; then
        log_message "Cleaning Android user directory..."
        
        # Clean cache but preserve AVD and other important files
        if [ -d "$HOME/.android/cache" ]; then
            rm -rf "$HOME/.android/cache"/* 2>/dev/null || true
            log_message "Android cache directory cleaned"
        fi
        
        # Clean debug logs
        find "$HOME/.android" -name "*.log" -mtime +30 -delete 2>/dev/null || true
        
        # AVD 파일은 중요하므로 보존함을 안내
        if [ -d "$HOME/.android/avd" ]; then
            log_message "Preserving Android Virtual Device (AVD) files to maintain settings"
        fi
    fi
    
    log_message "Android Studio cleanup completed successfully"
fi

log_message "Moving to iOS Simulator Cleanup..."

# Subsection 4.8: iOS Simulator Cleanup
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would clean iOS Simulator caches and unused simulators"
else
    if check_xcode_installed; then
        # Clean simulator caches
        log_message "Cleaning iOS Simulator caches..."
        if ! rm -rf ~/Library/Developer/CoreSimulator/Caches/* 2>/dev/null; then
            log_message "WARNING: Failed to clean simulator caches - permission denied or files in use"
        fi
        
        # Remove unavailable simulators
        log_message "Removing unavailable simulators..."
        if ! xcrun simctl delete unavailable 2>&1 | tee -a "$LOG_FILE"; then
            log_message "WARNING: Failed to remove unavailable simulators - permission denied or command failed"
        fi
    else
        log_message "Skipping iOS Simulator cleanup - Xcode not installed"
    fi
fi

log_message "----------------------------------------"

# Section 5: Application Cache Cleanup
log_message "SECTION 5: Application Cache Cleanup"

# Subsection 5.1: Check for large files in Application Support
log_message "Checking for large files in Application Support..."
large_app_support=$(find "$HOME/Library/Application Support" -type f -size +100M -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)

if [ -n "$large_app_support" ]; then
    log_message "Found the following large files in Application Support:"
    echo "$large_app_support" | tee -a "$LOG_FILE"
    log_message "NOTE: These files may be important for your applications. Review manually before removing."
fi

# Subsection 5.2: XCode Cleanup
if [ -d "$HOME/Library/Developer/Xcode" ]; then
    log_message "XCode detected. Checking for cleanable files..."
    
    # Check DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        derived_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1}')
        log_message "XCode DerivedData size: $derived_size"
        
        if [ "$DRY_RUN" = false ]; then
            if [[ "$AUTO_CLEAN" == "true" ]]; then
                # Auto-clean 모드에서는 바로 정리
                log_message "Auto-cleaning XCode DerivedData..."
                if rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null; then
                    log_message "Successfully cleaned XCode DerivedData"
                else
                    handle_error "Failed to clean XCode DerivedData"
                fi
            else
                # 사용자 입력을 받는 인터랙티브 모드에서 예외 처리 추가
                if confirm_action "Clean XCode DerivedData?" "n"; then
                    log_message "Cleaning XCode DerivedData..."
                    if rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null; then
                        log_message "Successfully cleaned XCode DerivedData"
                    else
                        handle_error "Failed to clean XCode DerivedData"
                    fi
                fi
            fi
        fi
    fi
    
    # Check iOS Device Support (can be very large)
    if [ -d "$HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
        devicesupport_size=$(du -sh "$HOME/Library/Developer/Xcode/iOS DeviceSupport" 2>/dev/null | awk '{print $1}')
        log_message "iOS Device Support files size: $devicesupport_size"
        
        # This is a more cautious cleanup - only suggest, not auto-clean
        log_message "Consider manually removing old iOS device support files to free up space"
    fi
    
    # Check Archives
    if [ -d "$HOME/Library/Developer/Xcode/Archives" ]; then
        archives_size=$(du -sh "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null | awk '{print $1}')
        log_message "XCode Archives size: $archives_size"
        
        if [ "$DRY_RUN" = false ]; then 
            if [[ "$AUTO_CLEAN" == "true" ]]; then
                # Auto-clean 모드에서는 바로 정리
                log_message "Cleaning XCode Archives older than 90 days..."
                if find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null; then
                    log_message "Successfully cleaned old XCode Archives"
                else
                    handle_error "Failed to clean old XCode Archives"
                fi
            else
                if confirm_action "Clean old XCode Archives (older than 90 days)?" "n"; then
                    log_message "Cleaning XCode Archives older than 90 days..."
                    if find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null; then
                        log_message "Successfully cleaned old XCode Archives"
                    else
                        handle_error "Failed to clean old XCode Archives"
                    fi
                fi
            fi
        fi
    fi
else
    log_message "XCode not detected on this system"
fi

log_message "----------------------------------------"

# Section 6: System Files Cleanup
log_message "SECTION 6: System Files Cleanup"

# Subsection 6.1: .DS_Store Files Cleanup
log_message "Checking for .DS_Store files..."

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for and count .DS_Store files"
else
    # Count and calculate size of all .DS_Store files with progress
    total_found=0
    total_size=0
    
    # Find all .DS_Store files with progress
    while IFS= read -r -d '' file; do
        total_found=$((total_found + 1))
        file_size=$(du -k "$file" 2>/dev/null | cut -f1)
        total_size=$((total_size + file_size))
        
        # Show progress every 100 files
        if [ $((total_found % 100)) -eq 0 ]; then
            log_message "Found $total_found .DS_Store files so far..."
        fi
    done < <(find "$HOME" -name ".DS_Store" -type f -print0 2>/dev/null)
    
    if [ "$total_found" -gt 0 ]; then
        # numfmt 대신 직접 계산하여 출력
        if [ $total_size -ge 1024 ]; then
            size_mb=$(echo "scale=2; $total_size/1024" | bc)
            log_message "Found $total_found .DS_Store files, total size: ${size_mb}MB"
        else
            log_message "Found $total_found .DS_Store files, total size: ${total_size}KB"
        fi
        
        if [[ "$AUTO_CLEAN" == "true" ]]; then
            log_message "Auto-cleaning .DS_Store files..."
            if find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
                log_message "Successfully removed .DS_Store files"
            else
                log_message "WARNING: Some .DS_Store files could not be removed. Continuing..."
            fi
        else
            if confirm_action "Would you like to remove all .DS_Store files?" "n"; then
                log_message "Removing .DS_Store files..."
                if find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
                    log_message "Successfully removed .DS_Store files"
                else
                    log_message "WARNING: Some .DS_Store files could not be removed. Continuing..."
                fi
            else
                log_message "Skipping .DS_Store cleanup"
            fi
        fi
    else
        log_message "No .DS_Store files found"
    fi
fi

# Subsection 6.2: macOS Language Resources
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would check for unused language resources"
elif [ "$AUTO_CLEAN" = true ]; then
    log_message "Auto-cleaning language resources..."
    # Find top 10 largest localization directories
    large_locales=$(find /Applications -path "*.lproj" -type d -not -path "*/en.lproj" -not -path "*/Base.lproj" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_locales" ]; then
        log_message "Found the following large localization directories:"
        echo "$large_locales" | tee -a "$LOG_FILE"
        log_message "WARNING: Removing these may affect applications. Consider manual review."
    else
        log_message "No significant localization directories found."
    fi
else
    if confirm_action "Would you like to check for unused language resources?" "n"; then
        log_message "Checking for large language resource directories..."

        # Find top 10 largest localization directories
        large_locales=$(find /Applications -path "*.lproj" -type d -not -path "*/en.lproj" -not -path "*/Base.lproj" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
        
        if [ -n "$large_locales" ]; then
            log_message "Found the following large localization directories:"
            echo "$large_locales" | tee -a "$LOG_FILE"
            log_message "WARNING: Removing these may affect applications. Consider manual review."
        else
            log_message "No significant localization directories found."
        fi
    else
        log_message "Skipping language resources check"
    fi
fi

log_message "----------------------------------------"

# Section 7: Final Summary
log_message "SECTION 7: Final Summary"

# 스크립트 종료 시 실행될 cleanup 함수 정의
# shellcheck disable=SC2317
cleanup() {
    # 종료 직전에 항상 최종 요약 보여주기
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        log_message "Cleanup function called - ensuring proper script termination"
        log_message "Log file is available at: $LOG_FILE"
        echo ""
        echo "===================================================="
        echo "          Cleanup process has completed!            "
        echo "===================================================="
        echo "Log file saved to: $LOG_FILE"
        echo "===================================================="
    fi
    
    # 모든 백그라운드 프로세스 종료 (필요시)
    # jobs -p | xargs -r kill 2>/dev/null
}

# 스크립트 종료 시 cleanup 함수 실행
trap cleanup EXIT

# 중단 신호 처리
trap 'log_message "Script interrupted by user"; exit 130;' INT TERM

# 최종 요약을 안전하게 계산하고 출력
log_message "Computing final results..."

# Calculate space saved (오류가 발생하지 않도록 안전하게 처리)
FINAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}' 2>/dev/null || echo "0")
if [ -z "$FINAL_FREE_SPACE" ] || ! [[ "$FINAL_FREE_SPACE" =~ ^[0-9]+$ ]]; then
    FINAL_FREE_SPACE=0
    log_message "WARNING: Could not get final free space value"
fi

if [ -z "$INITIAL_FREE_SPACE" ] || ! [[ "$INITIAL_FREE_SPACE" =~ ^[0-9]+$ ]]; then
    INITIAL_FREE_SPACE=0
    log_message "WARNING: Initial free space value was invalid"
fi

# 오류 없이 계산될 수 있도록 함
SPACE_SAVED=$((FINAL_FREE_SPACE - INITIAL_FREE_SPACE))

# Check disk usage after cleanup
log_message "Initial disk free space: $(format_disk_space $((INITIAL_FREE_SPACE * 1024)) 2>/dev/null)"
log_message "Final disk free space: $(format_disk_space $((FINAL_FREE_SPACE * 1024)) 2>/dev/null)"

# 안전하게 공간 절약 결과 계산
if [ $SPACE_SAVED -gt 0 ]; then
    log_message "Total space saved: $(calculate_space_saved "$INITIAL_FREE_SPACE" "$FINAL_FREE_SPACE")"
elif [ $SPACE_SAVED -lt 0 ]; then
    log_message "WARNING: Disk space appears to have decreased by: $(format_disk_space $((-SPACE_SAVED * 1024)) 2>/dev/null)"
    log_message "This might be due to system activities during cleanup or measurement errors"
else
    log_message "No significant disk space was saved"
fi

log_message "========================================="
log_message "System cleanup completed. Log saved to: $LOG_FILE"
log_message "End time: $(date)"
log_message "========================================="

# Provide some user guidance
echo ""
echo "=================================================="
echo "             Cleanup process completed!            "
echo "=================================================="
if [ $SPACE_SAVED -gt 0 ]; then
    echo "Total space saved: $(calculate_space_saved "$INITIAL_FREE_SPACE" "$FINAL_FREE_SPACE")"
else
    echo "No significant disk space was saved"
fi
echo ""
echo "For additional manual cleanup, consider:"
echo "1. Emptying the Trash (rm -rf ~/.Trash/*)"
echo "2. Cleaning browser caches"
echo "3. Removing unused applications"
echo "4. Checking Time Machine backups"
echo "5. Using tools like OmniDiskSweeper or GrandPerspective to find large files"
echo ""
echo "For additional options, run: $0 --help"
echo "Log file saved to: $LOG_FILE"
echo "=================================================="

fi

# 정상 종료 상태를 반환 (0은 성공을 의미함)
exit 0