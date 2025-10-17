#!/bin/bash

# system_cleanup.sh - Automated System Cleanup Script for macOS
# v2.5 - 2025-05-20
#
# This script performs various system cleanup tasks to free up disk space
# and maintain system health. It includes comprehensive cleanup options
# for development tools, application caches, and system files with
# built-in error recovery and stability mechanisms.

# 에러 발생 시 스크립트 중단
set -e

# 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Print help message
show_help() {
    echo "macos-system-cleanup v2.5 - 시스템 정리 도구"
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
    echo "권한 문제 해결:"
    echo "  logs 디렉토리 권한 문제가 발생하면 다음 명령어를 실행하세요:"
    echo "  sudo chown -R \$(whoami):staff logs/"
    echo
    echo "  또는 logs 디렉토리를 완전히 재생성:"
    echo "  sudo rm -rf logs && mkdir -p logs"
    exit 0
}

# Process command line arguments
DRY_RUN=false
SKIP_BREW=false
SKIP_NPM=false
SKIP_DOCKER=false
SKIP_ANDROID=false
AUTO_CLEAN=false

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
    esac
done

# 로깅 시스템 초기화 (common.sh 사용)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

# 안전한 로깅 초기화 (권한 검사 포함)
if ! LOG_FILE=$(setup_logging "cleanup"); then
    echo "🛑 FATAL: 로깅 시스템 초기화 실패"
    echo "logs 디렉토리 권한을 확인하세요: $LOG_DIR"
    exit 1
fi

# 로깅 함수들은 common.sh에서 제공됨
# handle_error()와 log_message() 함수는 이미 common.sh에 정의되어 있음

# 스크립트 시작 로그
log_message "========================================="
log_message "macOS System Cleanup Utility 시작"
log_message "========================================="
log_message "스크립트: $0"
log_message "로그 파일: $LOG_FILE"
log_message "실행 사용자: $(whoami)"
log_message "실행 시간: $(date)"

# Note: calculate_space_saved, format_disk_space, check_sudo functions
# are now provided by common.sh

# Function to check if Docker daemon is running
check_docker_daemon() {
    if ! command -v docker &>/dev/null; then
        log_message "Docker is not installed on this system"
        return 1
    fi
    
    if ! timeout 5s docker info &>/dev/null; then
        log_message "Docker daemon is not running"
        return 1
    fi
    
    return 0
}

# Function to check if Xcode is installed
check_xcode_installed() {
    if ! command -v xcode-select &>/dev/null; then
        log_message "Xcode command line tools are not installed"
        return 1
    fi
    
    if ! xcode-select -p &>/dev/null; then
        log_message "Xcode is not installed"
        return 1
    fi
    
    return 0
}

# Function to clean user level caches
clean_user_caches() {
    local space_before=$(df -k / | awk 'NR==2 {print $4}')
    
    log_message "Cleaning user level caches..."
    
    # Browser caches
    if [ -d "$HOME/Library/Caches/Google/Chrome" ]; then
        log_message "Cleaning Chrome cache..."
        rm -rf "$HOME/Library/Caches/Google/Chrome/Default/Cache/"* 2>/dev/null
        rm -rf "$HOME/Library/Caches/Google/Chrome/Default/Code Cache/"* 2>/dev/null
    fi
    
    if [ -d "$HOME/Library/Caches/Firefox" ]; then
        log_message "Cleaning Firefox cache..."
        rm -rf "$HOME/Library/Caches/Firefox/"* 2>/dev/null
    fi
    
    # Development tools caches
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        log_message "Cleaning XCode DerivedData..."
        rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"* 2>/dev/null
    fi
    
    if [ -d "$HOME/Library/Developer/CoreSimulator/Caches" ]; then
        log_message "Cleaning iOS Simulator caches..."
        rm -rf "$HOME/Library/Developer/CoreSimulator/Caches/"* 2>/dev/null
    fi
    
    # Application caches
    find "$HOME/Library/Caches" -type f -atime +30 -delete 2>/dev/null
    find "$HOME/Library/Application Support" -name "*.log" -type f -mtime +30 -delete 2>/dev/null
    
    local space_after=$(df -k / | awk 'NR==2 {print $4}')
    local space_saved=$((space_after - space_before))
    
    if [ $space_saved -gt 0 ]; then
        log_message "Successfully cleaned user caches. Space saved: $(format_disk_space $((space_saved * 1024)))"
    else
        log_message "No significant space saved from user cache cleanup"
    fi
    
    return 0
}

# Function to clean system level caches (requires sudo)
clean_system_caches() {
    if check_sudo; then
        local space_before=$(df -k / | awk 'NR==2 {print $4}')
        
        log_message "Cleaning system level caches..."
        
        # System caches
        sudo rm -rf /Library/Caches/* 2>/dev/null || log_message "Some system caches could not be cleaned"
        
        # System logs (preserve critical logs)
        sudo find /var/log -type f -not -name "system.log" \
                                   -not -name "kernel.log" \
                                   -not -name "secure.log" \
                                   -not -name "auth.log" \
                                   -mtime +30 -delete 2>/dev/null
        
        local space_after=$(df -k / | awk 'NR==2 {print $4}')
        local space_saved=$((space_after - space_before))
        
        if [ $space_saved -gt 0 ]; then
            log_message "Successfully cleaned system caches. Space saved: $(format_disk_space $((space_saved * 1024)))"
        else
            log_message "No significant space saved from system cache cleanup"
        fi
    else
        log_message "Skipping system level cache cleanup - requires sudo privileges"
        log_message "To clean system caches, run the script with sudo"
    fi
    
    return 0
}

# 시스템 정리 프로세스 시작
log_message "시스템 정리 프로세스 시작"

# Record initial system state
INITIAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
log_message "Initial free space: $(df -h / | awk 'NR==2 {print $4}')"

# Section 1: System Overview
log_message "SECTION 1: System Overview"
df -h / | tee -a "$LOG_FILE"
log_message "----------------------------------------"

# Section 2: System Library and Cache Cleanup
log_message "SECTION 2: System Library and Cache Cleanup"

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would clean system and user caches"
else
    # Always clean user level caches
    if ! clean_user_caches; then
        log_message "⚠️ Warning: User cache cleanup had issues, but continuing..."
    fi
    
    # Attempt system level cleanup if sudo is available
    if ! clean_system_caches; then
        log_message "⚠️ Warning: System cache cleanup had issues, but continuing..."
    fi
fi

log_message "----------------------------------------"

# Section 3: Time Machine Local Snapshots
log_message "SECTION 3: Time Machine Local Snapshots"

# 스냅샷 제거 함수
clean_time_machine_snapshots() {
    log_message "Removing local snapshots..."
    if sudo tmutil thinlocalsnapshots / 9999999999999999 1 2>&1 | tee -a "$LOG_FILE"; then
        log_message "Successfully removed local snapshots"
        return 0
    else
        handle_error "Failed to remove local snapshots - sudo privileges may be required"
        return 1
    fi
}

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would check and manage Time Machine local snapshots"
else
    if command -v tmutil &>/dev/null; then
        # List local snapshots
        log_message "Checking Time Machine local snapshots..."
        local_snapshots=$(tmutil listlocalsnapshots / 2>/dev/null)
        
        if [ -n "$local_snapshots" ]; then
            log_message "Found the following local snapshots:"
            echo "$local_snapshots" | tee -a "$LOG_FILE"
            
            # 스냅샷 개수 계산 - 개선된 버전
            snapshot_count=0
            if [ -n "$local_snapshots" ]; then
                # 헤더 라인("Snapshots for disk /:")을 제외하고 실제 스냅샷만 카운트
                snapshot_count=$(echo "$local_snapshots" | grep -v "Snapshots for disk" | grep -v "^$" | wc -l | tr -d ' ')
                
                # 디버그 정보 출력 (선택사항)
                log_message "DEBUG: Raw snapshot output lines: $(echo "$local_snapshots" | wc -l)"
                log_message "DEBUG: Filtered snapshot count: $snapshot_count"
            fi
            
            # 스냅샷 개수 검증
            if [ "$snapshot_count" -gt 0 ] 2>/dev/null; then
                log_message "총 ${snapshot_count}개의 로컬 스냅샷이 있습니다"
            else
                log_message "스냅샷 개수를 정확히 계산할 수 없습니다. 수동으로 확인이 필요합니다."
                snapshot_count=0
            fi
            
            if [[ "$AUTO_CLEAN" == true ]]; then
                log_message "자동 정리 모드: 로컬 스냅샷 정리 중..."
                if ! clean_time_machine_snapshots; then
                    log_message "⚠️ Warning: Failed to clean Time Machine snapshots, but continuing..."
                fi
            else
                read -p "Would you like to remove local snapshots? (y/n): " remove_snapshots
                if [[ "$remove_snapshots" == "y" || "$remove_snapshots" == "Y" ]]; then
                    if ! clean_time_machine_snapshots; then
                        log_message "⚠️ Warning: Failed to clean Time Machine snapshots, but continuing..."
                    fi
                else
                    log_message "Skipping local snapshots cleanup"
                fi
            fi
        else
            log_message "No local snapshots found"
            snapshot_count=0
        fi
        
        # 스냅샷 정리 후 상태 확인
        if [ "$snapshot_count" -gt 0 ] 2>/dev/null; then
            log_message "스냅샷 정리 후 상태를 확인합니다..."
            remaining_snapshots=$(tmutil listlocalsnapshots / 2>/dev/null)
            if [ -n "$remaining_snapshots" ]; then
                # 헤더 라인을 제외하고 실제 스냅샷만 카운트
                remaining_count=$(echo "$remaining_snapshots" | grep -v "Snapshots for disk" | grep -v "^$" | wc -l | tr -d ' ')
                log_message "정리 후 남은 스냅샷: ${remaining_count}개"
            else
                log_message "모든 로컬 스냅샷이 정리되었습니다."
            fi
        fi
    else
        log_message "tmutil command not found, skipping Time Machine cleanup"
        snapshot_count=0
    fi
fi

log_message "----------------------------------------"

# Section 4: Development Tools Cleanup
log_message "SECTION 4: Development Tools Cleanup"

# Subsection 4.1: Homebrew Cleanup
clean_homebrew() {
    # Check if running as root
    if [ "$(id -u)" = "0" ]; then
        log_message "WARNING: Running Homebrew as root is not supported. Skipping Homebrew cleanup."
        return 1
    fi
    
    # Update Homebrew and upgrade all installed packages
    log_message "Updating Homebrew and upgrading installed packages..."
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew update 2>&1 | tee -a "$LOG_FILE"; then
        handle_error "Failed to update Homebrew"
        return 1
    fi
    
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade 2>&1 | tee -a "$LOG_FILE"; then
        handle_error "Failed to upgrade packages"
        return 1
    fi
    
    # Run brew doctor to check for potential problems
    log_message "Running brew doctor to check for potential problems..."
    if ! brew doctor 2>&1 | tee -a "$LOG_FILE"; then
        handle_error "Brew doctor check failed"
        # Continue despite errors from brew doctor
    fi
    
    # Check for outdated packages
    log_message "Checking for outdated packages..."
    brew outdated 2>&1 | tee -a "$LOG_FILE"
    
    # Check for unused dependencies
    log_message "Checking for unused dependencies..."
    brew autoremove -n 2>&1 | tee -a "$LOG_FILE"
    
    if [[ "$1" == "--auto-clean" ]]; then
        log_message "Auto-removing unused dependencies..."
        if ! brew autoremove 2>&1 | tee -a "$LOG_FILE"; then
            handle_error "Failed to remove unused dependencies"
            # Continue despite errors
        fi
    fi
    
    # Clean up Homebrew
    log_message "Cleaning up Homebrew cache and old versions..."
    if ! brew cleanup --prune=all 2>&1 | tee -a "$LOG_FILE"; then
        handle_error "Failed to clean Homebrew"
        return 1
    fi
    
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
            # Call the cleanup function
            if ! clean_homebrew "$1"; then
                log_message "⚠️ Warning: Some Homebrew cleanup operations failed, but continuing..."
            fi
            
            # Get cache size after cleaning
            brew_cache_size_after=$(du -sh "$brew_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "Homebrew cache size after cleaning: $brew_cache_size_after"
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
                if [[ "$1" == "--auto-clean" ]]; then
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
        elif [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning Yarn cache..."
            yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
            
            # Verify cleaning was successful
            yarn_cache_size_after=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "Yarn cache size after cleaning: $yarn_cache_size_after"
        else
            read -p "Would you like to clean the Yarn cache? (y/n): " yarn_clean
            if [[ "$yarn_clean" == "y" || "$yarn_clean" == "Y" ]]; then
                log_message "Cleaning Yarn cache..."
                yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
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
    # Find top 10 largest node_modules directories - 한정된 시간 내 실행되도록 timeout 적용
    log_message "Searching for large node_modules directories (timeout: 60s)..."
    large_dirs=$(timeout 60s find "$HOME" -type d -name "node_modules" -not -path "*/\.*" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_dirs" ]; then
        log_message "Found the following large node_modules directories:"
        echo "$large_dirs" | tee -a "$LOG_FILE"
        
        if [[ "$1" == "--auto-clean" ]]; then
            log_message "Checking for unused node_modules (projects not modified in last 90 days)..."
            
            # 검색 범위를 일반적인 프로젝트 디렉토리로 제한하고 타임아웃 설정
            log_message "Searching in common project directories only (timeout: 30s)..."
            
            # 특정 디렉토리만 검색 (일반적인 프로젝트 위치)
            project_dirs=("$HOME/Documents" "$HOME/Projects" "$HOME/Development" "$HOME/Dev")
            
            old_projects=""
            for dir in "${project_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    log_message "Scanning $dir for unused node_modules..."
                    result=$(timeout 30s find "$dir" -type d -name "node_modules" -not -path "*/\.*" -mtime +90 -exec dirname {} \; 2>/dev/null || echo "")
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
                log_message "No potentially unused node_modules directories found or search timed out."
            fi
        fi
    else
        log_message "No large node_modules directories found or search timed out."
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
        elif [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning Docker resources (--auto-clean flag detected)..."
            
            # 안전하게 실행 (각 명령마다 오류 처리 및 타임아웃 추가)
            log_message "Pruning Docker system (images, containers, networks)..."
            if timeout 60s docker system prune -f 2>&1 | tee -a "$LOG_FILE"; then
                log_message "Successfully pruned Docker system"
            else
                log_message "WARNING: Failed or timed out while pruning Docker system. Continuing..."
            fi
            
            log_message "Pruning Docker volumes..."
            if timeout 30s docker volume prune -f 2>&1 | tee -a "$LOG_FILE"; then
                log_message "Successfully pruned Docker volumes"
            else
                log_message "WARNING: Failed or timed out while pruning Docker volumes. Continuing..."
            fi
            
            log_message "Docker cleanup completed"
        else
            docker_clean=""
            if ! read -p "Would you like to clean unused Docker resources? (y/n): " docker_clean; then
                log_message "WARNING: Input error encountered for Docker cleanup prompt. Skipping..."
                docker_clean="n"
            fi
            
            if [[ "$docker_clean" == "y" || "$docker_clean" == "Y" ]]; then
                log_message "Cleaning Docker resources..."
                timeout 60s docker system prune -f 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Docker system prune failed or timed out"
                
                docker_vol_clean=""
                if ! read -p "Also clean unused Docker volumes? This will delete ALL volumes not used by at least one container (y/n): " docker_vol_clean; then
                    log_message "WARNING: Input error encountered for Docker volumes cleanup prompt. Skipping..."
                    docker_vol_clean="n"
                fi
                
                if [[ "$docker_vol_clean" == "y" || "$docker_vol_clean" == "Y" ]]; then
                    log_message "Cleaning Docker volumes..."
                    timeout 30s docker volume prune -f 2>&1 | tee -a "$LOG_FILE" || log_message "WARNING: Docker volume prune failed or timed out"
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
    if timeout 5s docker info &>/dev/null; then
        docker_running=true
    else
        log_message "WARNING: Docker daemon is not running. Skipping OpenWebUI checks."
    fi
    
    if [ "$docker_running" = true ]; then
        # Check if OpenWebUI is installed/running
        if timeout 10s docker ps | grep -q "open-webui"; then
            log_message "OpenWebUI detected. Checking data volume..."
            
            # Get data volume size before cleaning - 안전하게 타임아웃 설정
            openwebui_volume_size_before=$(timeout 10s docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -sh /vol" 2>/dev/null | awk '{print $1}' || echo "unknown")
            # Get numeric size in bytes for comparison
            openwebui_bytes_before=$(timeout 10s docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -b /vol | cut -f1" 2>/dev/null || echo "0")
            log_message "OpenWebUI data volume size before cleaning: $openwebui_volume_size_before"
            
            if [ "$DRY_RUN" = true ]; then
                # Dry run mode - show what would be cleaned
                log_message "DRY RUN: Would clean OpenWebUI cache files and temporary data"
                log_message "DRY RUN: Would preserve conversation history and important settings"
            elif [[ "$1" == "--auto-clean" ]]; then
                # Auto-clean mode
                log_message "Auto-cleaning OpenWebUI data (--auto-clean flag detected)..."
                
                # Clean cache files and temporary data - 안전한 명령어 실행
                log_message "Removing cache and temporary files..."
                if timeout 30s docker run --rm -v open-webui_open-webui:/data alpine sh -c "
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
                    log_message "WARNING: OpenWebUI cleanup may have timed out or failed. Continuing..."
                fi
                
                # Restart OpenWebUI to apply changes
                log_message "Restarting OpenWebUI container to apply changes..."
                if timeout 20s docker restart open-webui 2>&1 | tee -a "$LOG_FILE"; then
                    log_message "Successfully restarted OpenWebUI container"
                else
                    log_message "WARNING: Failed to restart OpenWebUI container. It may be in an inconsistent state."
                fi
            else
                # 이 부분은 입력을 받으므로 복잡합니다 - 단순화하여 안전하게 실행
                log_message "OpenWebUI cleanup requires interactive input."
                
                cache_clean=""
                if ! read -p "Clean cache files? (y/n): " cache_clean; then
                    log_message "WARNING: Input error encountered for OpenWebUI cache cleanup prompt. Skipping..."
                    cache_clean="n"
                fi
                
                # 단순화된 정리 작업: 기본 캐시 파일만 정리
                if [[ "$cache_clean" == "y" || "$cache_clean" == "Y" ]]; then
                    log_message "Cleaning OpenWebUI cache files..."
                    if timeout 30s docker run --rm -v open-webui_open-webui:/data alpine sh -c "
                        find /data -name '*cache*' -type d -exec rm -rf {} \; 2>/dev/null || echo 'No cache directories found or already cleaned'
                        find /data -name '*.temp' -o -name '*.tmp' -o -name '*.downloading' -o -name '*.part' -delete 2>/dev/null || echo 'No temporary files found or already cleaned'
                        echo 'OpenWebUI cache cleanup completed'
                    " 2>&1 | tee -a "$LOG_FILE"; then
                        log_message "OpenWebUI cache cleanup completed successfully"
                    else
                        log_message "WARNING: OpenWebUI cache cleanup timed out or failed"
                    fi
                    
                    restart_openwebui=""
                    if ! read -p "Would you like to restart the OpenWebUI container to apply changes? (y/n): " restart_openwebui; then
                        log_message "WARNING: Input error encountered for OpenWebUI restart prompt. Skipping..."
                        restart_openwebui="n"
                    fi
                    
                    if [[ "$restart_openwebui" == "y" || "$restart_openwebui" == "Y" ]]; then
                        log_message "Restarting OpenWebUI container..."
                        if timeout 20s docker restart open-webui 2>&1 | tee -a "$LOG_FILE"; then
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
            openwebui_volume_size_after=$(timeout 10s docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -sh /vol" 2>/dev/null | awk '{print $1}' || echo "unknown")
            # Get numeric size in bytes for comparison
            openwebui_bytes_after=$(timeout 10s docker run --rm -v open-webui_open-webui:/vol alpine sh -c "du -b /vol | cut -f1" 2>/dev/null || echo "0")
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
            if timeout 5s docker volume ls | grep -q "open-webui_open-webui"; then
                log_message "OpenWebUI data volume found but container not running"
                
                check_volume=""
                if [[ "$1" == "--auto-clean" ]]; then
                    check_volume="y"
                    log_message "Auto-cleaning OpenWebUI volume..."
                else
                    if ! read -p "Would you like to check OpenWebUI data volume for cleanup? (y/n): " check_volume; then
                        log_message "WARNING: Input error encountered for OpenWebUI volume cleanup prompt. Skipping..."
                        check_volume="n"
                    fi
                fi
                
                if [[ "$check_volume" == "y" || "$check_volume" == "Y" ]]; then
                    log_message "Cleaning OpenWebUI data volume even though container is not running..."
                    if timeout 30s docker run --rm -v open-webui_open-webui:/data alpine sh -c "
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
                        log_message "WARNING: OpenWebUI volume cleanup timed out or failed"
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
            
            if [[ "$1" == "--auto-clean" ]]; then
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
                read -p "Clean old Android Studio versions (keep latest only)? (y/n): " clean_old_versions
                if [[ "$clean_old_versions" == "y" || "$clean_old_versions" == "Y" ]]; then
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
                    log_message "Skipping old Android Studio version cleanup"
                fi
            fi
        fi
    fi
    
    # Clean Android Studio preferences
    as_prefs="$HOME/Library/Preferences/com.google.android.studio.plist"
    if [ -f "$as_prefs" ]; then
        log_message "Found Android Studio preferences file"
        # Check file modification time (cleanup if older than 90 days and auto-clean is enabled)
        if [[ "$1" == "--auto-clean" ]] && find "$as_prefs" -mtime +90 -print 2>/dev/null | grep -q .; then
            log_message "Removing old Android Studio preferences (older than 90 days)"
            rm -f "$as_prefs" 2>/dev/null || log_message "Warning: Could not remove preferences file"
        fi
    fi
    
    # Clean Android Emulator preferences
    emulator_prefs="$HOME/Library/Preferences/com.android.Emulator.plist"
    if [ -f "$emulator_prefs" ]; then
        log_message "Found Android Emulator preferences file"
        if [[ "$1" == "--auto-clean" ]] && find "$emulator_prefs" -mtime +90 -print 2>/dev/null | grep -q .; then
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
            if [[ "$1" == "--auto-clean" ]]; then
                # Auto-clean 모드에서는 바로 정리
                log_message "Auto-cleaning XCode DerivedData..."
                if rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null; then
                    log_message "Successfully cleaned XCode DerivedData"
                else
                    handle_error "Failed to clean XCode DerivedData"
                fi
            else
                # 사용자 입력을 받는 인터랙티브 모드에서 예외 처리 추가
                xcode_clean=""
                if ! read -p "Clean XCode DerivedData? (y/n): " xcode_clean; then
                    log_message "WARNING: Input error encountered for XCode DerivedData cleanup prompt. Skipping..."
                    xcode_clean="n"  # 입력 오류 시 기본값을 n으로 설정
                fi
                
                if [[ "$xcode_clean" == "y" || "$xcode_clean" == "Y" ]]; then
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
            if [[ "$1" == "--auto-clean" ]]; then
                # Auto-clean 모드에서는 바로 정리
                log_message "Cleaning XCode Archives older than 90 days..."
                if find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null; then
                    log_message "Successfully cleaned old XCode Archives"
                else
                    handle_error "Failed to clean old XCode Archives"
                fi
            else
                # 사용자 입력을 받는 인터랙티브 모드에서 예외 처리 추가
                archives_clean=""
                if ! read -p "Clean old XCode Archives (older than 90 days)? (y/n): " archives_clean; then
                    log_message "WARNING: Input error encountered for XCode Archives cleanup prompt. Skipping..."
                    archives_clean="n"  # 입력 오류 시 기본값을 n으로 설정
                fi
                
                if [[ "$archives_clean" == "y" || "$archives_clean" == "Y" ]]; then
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
        
        if [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning .DS_Store files..."
            if timeout 60s find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
                log_message "Successfully removed .DS_Store files"
            else
                log_message "WARNING: Some .DS_Store files could not be removed or timed out. Continuing..."
            fi
        else
            ds_clean=""
            if ! read -p "Would you like to remove all .DS_Store files? (y/n): " ds_clean; then
                log_message "WARNING: Input error encountered for .DS_Store cleanup prompt. Skipping..."
                ds_clean="n"
            fi
            
            if [[ "$ds_clean" == "y" || "$ds_clean" == "Y" ]]; then
                log_message "Removing .DS_Store files..."
                if timeout 60s find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
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
    lang_check=""
    if ! read -p "Would you like to check for unused language resources? (y/n): " lang_check; then
        log_message "WARNING: Input error encountered for language resources prompt. Skipping..."
        lang_check="n"
    fi
    
    if [[ "$lang_check" == "y" || "$lang_check" == "Y" ]]; then
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
log_message "macOS System Cleanup Utility 완료"
log_message "========================================="
log_message "시스템 정리 완료. 로그 저장 위치: $LOG_FILE"
log_message "종료 시간: $(date '+%Y-%m-%d %H:%M:%S')"
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

# 정상 종료 상태를 반환 (0은 성공을 의미함)
exit 0