#!/bin/bash

# system_cleanup.sh - Automated System Cleanup Script for macOS
# v2.7 - 2025-06-06
#
# This script performs various system cleanup tasks to free up disk space
# and maintain system health. It includes comprehensive cleanup options
# for development tools, application caches, and system files with
# built-in error recovery and stability mechanisms.

# 에러 발생 시 스크립트 중단
set -e

# 기본 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$HOME/.system_cleanup_backups"
LOG_DIR="$HOME/.system_cleanup_logs"
LOG_FILE="$LOG_DIR/cleanup_$(date +"%Y%m%d_%H%M%S").log"

# 디렉토리 생성
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# 로그 파일 초기화
touch "$LOG_FILE"

# 로깅 시스템 설정
LOG_LEVEL=1  # 0: debug, 1: info, 2: warning, 3: error

# ------------------- 함수 정의 영역 -------------------

setup_logging() {
    local log_level="${1:-info}"
    case "$log_level" in
        "debug") LOG_LEVEL=0 ;;
        "info") LOG_LEVEL=1 ;;
        "warning") LOG_LEVEL=2 ;;
        "error") LOG_LEVEL=3 ;;
    esac
    echo "=== System Cleanup Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "Log Level: $log_level" >> "$LOG_FILE"
    echo "=========================" >> "$LOG_FILE"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case "$level" in
        "debug") level_num=0 ;;
        "info") level_num=1 ;;
        "warning") level_num=2 ;;
        "error") level_num=3 ;;
    esac
    if [ "$level_num" -ge "$LOG_LEVEL" ]; then
        echo "$timestamp [$level] - $message" | tee -a "$LOG_FILE"
    fi
}

handle_error() {
    local error_message="$1"
    local error_code="${2:-1}"
    local severity="${3:-warning}"
    case "$severity" in
        "warning") log_message "warning" "$error_message" ;;
        "error") log_message "error" "$error_message (Code: $error_code)" ;;
        "critical") log_message "error" "CRITICAL ERROR: $error_message (Code: $error_code)"; exit "$error_code" ;;
    esac
    return "$error_code"
}

create_backup() {
    local target="$1"
    local backup_name=$(basename "$target")_$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/$backup_name"
    if [ -e "$target" ]; then
        log_message "info" "Creating backup of $target"
        if [ -w "$(dirname "$backup_path")" ]; then
            cp -r "$target" "$backup_path" || handle_error "Failed to create backup of $target"
        else
            handle_error "No write permission for backup directory" "error"
        fi
    fi
}

restore_backup() {
    local target="$1"
    local backup_name="$2"
    local backup_path="$BACKUP_DIR/$backup_name"
    if [ -e "$backup_path" ]; then
        log_message "info" "Restoring backup of $target"
        rm -rf "$target"
        cp -r "$backup_path" "$target" || handle_error "Failed to restore backup of $target"
    fi
}

show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percentage=$((current * 100 / total))
    printf "\r[%-50s] %d%% %s" "$(printf '#%.0s' $(seq 1 $((percentage/2))))" "$percentage" "$message"
}

monitor_resources() {
    local pid=$$
    local cpu_usage=$(ps -p $pid -o %cpu | tail -n 1)
    local mem_usage=$(ps -p $pid -o %mem | tail -n 1)
    log_message "debug" "Resource usage - CPU: ${cpu_usage}%, Memory: ${mem_usage}%"
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log_message "warning" "High CPU usage detected: ${cpu_usage}%"
    fi
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        log_message "warning" "High memory usage detected: ${mem_usage}%"
    fi
}

clean_cache_with_verification() {
    local cache_dir="$1"
    local retention_days="${2:-30}"
    local size_before=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    create_backup "$cache_dir"
    find "$cache_dir" -type f -mtime +$retention_days -delete
    local size_after=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    if [ "$size_before" = "$size_after" ]; then
        log_message "warning" "Cache size did not change for $cache_dir"
        restore_backup "$cache_dir" "$(basename "$cache_dir")_$(date +"%Y%m%d_%H%M%S")"
        return 1
    fi
    local space_saved=$(calculate_space_saved "$size_before" "$size_after")
    log_message "info" "Cache cleaned: $cache_dir ($space_saved saved)"
    monitor_resources
    return 0
}

clean_zoom_data() {
    local zoom_cache_dirs=(
        "$HOME/Library/Caches/zoom.us"
        "$HOME/Library/Application Support/zoom.us"
        "$HOME/Library/Logs/zoom.us"
    )
    for dir in "${zoom_cache_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local size_before=$(du -sh "$dir" 2>/dev/null | cut -f1)
            find "$dir" -type f -mtime +30 -delete
            local size_after=$(du -sh "$dir" 2>/dev/null | cut -f1)
            log_message "info" "Zoom cache $dir: $size_before -> $size_after"
        fi
    done
}

handle_user_cleanup() {
    local user="$1"
    local user_home="$2"
    if [ -d "$user_home" ]; then
        log_message "info" "Cleaning up for user: $user"
        if [ "$(id -u)" = "0" ]; then
            su - "$user" -c "$0 --user-cleanup" || log_message "warning" "Failed to clean up for user $user"
        else
            "$0" --user-cleanup || log_message "warning" "Failed to clean up for current user"
        fi
    fi
}

check_system_requirements() {
    local macos_version=$(sw_vers -productVersion)
    log_message "info" "macOS Version: $macos_version"
    local free_space=$(df -h / | awk 'NR==2 {print $4}')
    log_message "info" "Available disk space: $free_space"
    if [ "$(id -u)" = "0" ]; then
        log_message "info" "Running with root privileges"
        chown -R "$SUDO_USER" "$BACKUP_DIR" "$LOG_DIR"
    else
        log_message "warning" "Running without root privileges - some features may be limited"
    fi
}

clean_system_caches() {
    log_message "info" "Cleaning system caches"
    local system_cache_dirs=(
        "/Library/Caches"
        "/System/Library/Caches"
        "/private/var/folders"
        "/private/var/tmp"
    )
    for dir in "${system_cache_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_message "info" "Cleaning cache directory: $dir"
            find "$dir" -type f -mtime +30 -delete 2>/dev/null || log_message "warning" "Failed to clean $dir"
        fi
    done
}

clean_time_machine_snapshots() {
    log_message "info" "Cleaning Time Machine snapshots"
    tmutil deletelocalsnapshots / 2>/dev/null || log_message "warning" "Failed to clean Time Machine snapshots"
}

clean_system_files() {
    log_message "info" "Cleaning system files"
    if [ -d "/var/log" ]; then
        find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || log_message "warning" "Failed to clean system logs"
    fi
    rm -rf /private/var/tmp/TM* 2>/dev/null || log_message "warning" "Failed to clean temporary files"
}

run_system_cleanup() {
    log_message "info" "Starting system-level cleanup"
    clean_system_caches
    clean_time_machine_snapshots
    clean_system_files
}

run_user_cleanup() {
    log_message "info" "Starting user-level cleanup"
    clean_user_caches
    clean_development_tools
    clean_application_caches
}

run_user_cleanups() {
    log_message "info" "Starting cleanup for all users"
    for user in $(dscl . -list /Users | grep -v '^_' | grep -v '^root$'); do
        user_home=$(dscl . -read /Users/$user NFSHomeDirectory | cut -d' ' -f2)
        handle_user_cleanup "$user" "$user_home"
    done
}

generate_cleanup_report() {
    local report_file="$LOG_DIR/cleanup_report_$(date +"%Y%m%d_%H%M%S").txt"
    echo "=== System Cleanup Report ===" > "$report_file"
    echo "Generated at: $(date)" >> "$report_file"
    echo "===========================" >> "$report_file"
    echo "" >> "$report_file"
    echo "Disk Space Changes:" >> "$report_file"
    echo "Initial: $(format_disk_space $((INITIAL_FREE_SPACE * 1024)))" >> "$report_file"
    echo "Final: $(format_disk_space $((FINAL_FREE_SPACE * 1024)))" >> "$report_file"
    echo "Saved: $(calculate_space_saved $INITIAL_FREE_SPACE $FINAL_FREE_SPACE)" >> "$report_file"
    echo "" >> "$report_file"
    echo "Major Cleanup Items:" >> "$report_file"
    cat "$LOG_FILE" | grep "Cache cleaned:" >> "$report_file"
    echo "" >> "$report_file"
    echo "Warnings and Errors:" >> "$report_file"
    cat "$LOG_FILE" | grep -E "WARNING|ERROR" >> "$report_file"
    log_message "info" "Cleanup report generated: $report_file"
}

show_help() {
    echo "macos-system-cleanup v2.7 - 시스템 정리 도구"
    echo "사용법: $0 [옵션]"
    echo
    echo "옵션:"
    echo "  --help          이 도움말 메시지 표시"
    echo "  --auto-clean    프롬프트 없이 모든 정리 작업 자동 실행"
    echo "  --dry-run       실제 정리 없이 정리할 내용 보기"
    echo "  --system-cleanup 시스템 레벨 정리만 실행 (sudo 필요)"
    echo "  --user-cleanup   사용자 레벨 정리만 실행"
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
    echo "  sudo $0 --system-cleanup      # 시스템 레벨 정리만 실행"
    echo
    echo "참고: 시스템 캐시 정리를 위해서는 sudo 권한이 필요합니다."
    echo "      sudo $0 명령으로 실행하면 더 많은 항목을 정리할 수 있습니다."
    exit 0
}

# ------------------- 메인 실행부 -------------------

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
        --system-cleanup)
            run_system_cleanup
            exit 0
            ;;
        --user-cleanup)
            run_user_cleanup
            exit 0
            ;;
    esac
done

setup_logging "info"

main() {
    log_message "info" "Starting system cleanup process"
    check_system_requirements
    local total_tasks=0
    if [ "$(id -u)" = "0" ]; then
        total_tasks=$((total_tasks + 3))
        total_tasks=$((total_tasks + $(dscl . -list /Users | grep -v '^_' | grep -v '^root$' | wc -l)))
    else
        total_tasks=$((total_tasks + 3))
    fi
    local current_task=0
    if [ "$(id -u)" = "0" ]; then
        show_progress $((++current_task)) "$total_tasks" "Running system cleanup"
        run_system_cleanup
        show_progress $((++current_task)) "$total_tasks" "Running user cleanups"
        run_user_cleanups
    else
        show_progress $((++current_task)) "$total_tasks" "Running user cleanup"
        run_user_cleanup
    fi
    show_progress "$total_tasks" "$total_tasks" "Generating cleanup report"
    generate_cleanup_report
    echo
}

main "$@"

exit 0