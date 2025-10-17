#!/bin/bash
# common/logging.sh - 공통 로깅 및 오류 처리 함수

# 로그 디렉토리 설정 함수
setup_logging() {
    local script_name="$1"
    
    # 호출한 스크립트의 디렉토리를 찾기 위해 스택을 거슬러 올라감
    local script_dir=""
    local i=1
    while [[ $i -lt ${#BASH_SOURCE[@]} ]]; do
        local source_file="${BASH_SOURCE[$i]}"
        if [[ "$source_file" != *"common.sh" ]]; then
            script_dir="$(cd "$(dirname "$source_file")" && pwd)"
            break
        fi
        ((i++))
    done
    
    # fallback: 현재 작업 디렉토리 사용
    if [[ -z "$script_dir" ]]; then
        script_dir="$(pwd)"
    fi
    
    local project_root="$(dirname "$script_dir")"
    local log_dir="$project_root/logs"
    local log_file="$log_dir/${script_name}_$(date +"%Y%m%d_%H%M%S").log"
    
    # 로그 디렉토리 생성 시도
    if mkdir -p "$log_dir" 2>/dev/null; then
        # 로그 파일 생성 시도
        if touch "$log_file" 2>/dev/null; then
            echo "$log_file"
            return 0
        fi
    fi
    
    # 권한 문제로 실패한 경우 홈 디렉토리에 로그 생성
    local fallback_log_dir="$HOME/.macos-system-cleanup/logs"
    mkdir -p "$fallback_log_dir"
    local fallback_log_file="$fallback_log_dir/${script_name}_$(date +"%Y%m%d_%H%M%S").log"
    
    if touch "$fallback_log_file" 2>/dev/null; then
        echo "⚠️  WARNING: 프로젝트 logs 디렉토리에 권한이 없습니다." >&2
        echo "⚠️  WARNING: 대체 위치에 로그를 생성합니다: $fallback_log_file" >&2
        echo "⚠️  WARNING: 권한 문제를 해결하려면 다음 명령어를 실행하세요:" >&2
        echo "⚠️  WARNING: sudo chown -R $(whoami):staff logs/" >&2
        echo "$fallback_log_file"
        return 0
    else
        echo "🛑 FATAL: 로그 파일 생성 실패. 권한 확인 필요" >&2
        echo "🛑 FATAL: 프로젝트 logs 디렉토리: $log_dir" >&2
        echo "🛑 FATAL: 대체 logs 디렉토리: $fallback_log_dir" >&2
        exit 1
    fi
}

# 통합 로깅 함수 (로그 파일이 설정된 경우 자동 사용)
log_message() {
    local message="$1"
    local timestamp
    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"
    
    # 입력 검증
    if [[ -z "$message" ]]; then
        echo "WARNING: log_message() called with empty message"
        return 1
    fi
    
    # 로그 파일이 설정되어 있으면 파일에도 기록
    if [[ -n "$LOG_FILE" && -w "$LOG_FILE" ]]; then
        echo "[$timestamp] $message" | tee -a "$LOG_FILE"
    else
        echo "[$timestamp] $message"
    fi
}

# 에러 로깅 및 처리 함수
handle_error() {
    local error_message="$1"
    local exit_on_error="${2:-false}"
    
    # 입력 검증
    if [[ -z "$error_message" ]]; then
        log_message "WARNING: handle_error() called with empty error message"
        return 1
    fi
    
    # 에러 메시지 로깅
    log_message "❌ ERROR: $error_message"
    
    if [[ "$exit_on_error" == "true" ]]; then
        log_message "🛑 FATAL: 치명적 오류로 인해 스크립트를 종료합니다."
        exit 1
    else
        log_message "⚠️  계속 진행합니다..."
        return 1
    fi
}

# 성공 메시지 로깅
log_success() {
    local message="$1"
    log_message "✅ SUCCESS: $message"
}

# 경고 메시지 로깅
log_warning() {
    local message="$1"
    log_message "⚠️  WARNING: $message"
}

# 정보 메시지 로깅
log_info() {
    local message="$1"
    log_message "ℹ️  INFO: $message"
}

# ==============================================
# 유틸리티 함수들
# ==============================================

# 디스크 공간 포맷 함수 (개선된 버전)
format_disk_space() {
    local space="$1"
    
    # 입력 검증
    if [[ ! "$space" =~ ^[0-9]+$ ]]; then
        echo "Invalid"
        return 1
    fi
    
    # 더 정확한 계산을 위해 bc 사용
    if command -v bc >/dev/null 2>&1; then
        if [ "$space" -ge 1073741824 ]; then
            echo "$(echo "scale=2; $space/1073741824" | bc)GB"
        elif [ "$space" -ge 1048576 ]; then
            echo "$(echo "scale=2; $space/1048576" | bc)MB"
        elif [ "$space" -ge 1024 ]; then
            echo "$(echo "scale=2; $space/1024" | bc)KB"
        else
            echo "${space}B"
        fi
    else
        # bc가 없는 경우 간단한 정수 연산
        if [ "$space" -ge 1073741824 ]; then
            echo "$((space/1073741824))GB"
        elif [ "$space" -ge 1048576 ]; then
            echo "$((space/1048576))MB"
        elif [ "$space" -ge 1024 ]; then
            echo "$((space/1024))KB"
        else
            echo "${space}B"
        fi
    fi
}

# 공간 절약 계산 함수 (개선된 버전)
calculate_space_saved() {
    local before="$1"
    local after="$2"
    
    # 입력 검증
    if [[ ! "$before" =~ ^[0-9]+$ ]] || [[ ! "$after" =~ ^[0-9]+$ ]]; then
        echo "Unable to calculate (invalid input)"
        return 1
    fi
    
    local saved=$((after - before))
    
    if [ "$saved" -gt 0 ]; then
        format_disk_space "$saved"
    elif [ "$saved" -lt 0 ]; then
        echo "-$(format_disk_space "$((-saved))")"
    else
        echo "0B"
    fi
}

# 현재 디스크 여유 공간 가져오기 (KB 단위)
get_free_space() {
    local path="${1:-/}"
    df -k "$path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0"
}

# ==============================================
# 권한 및 보안 관련 함수
# ==============================================

# sudo 사용 가능 여부 확인 함수 (개선된 버전)
check_sudo() {
    # root 사용자인지 확인
    if [ "$(id -u)" = "0" ]; then
        return 0
    fi
    
    # sudo 명령어 존재 여부 확인
    if ! command -v sudo >/dev/null 2>&1; then
        return 1
    fi
    
    # sudo 권한 확인 (패스워드 없이)
    if sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 안전한 임시 디렉토리 생성
create_temp_dir() {
    local prefix="${1:-macos_cleanup}"
    local temp_dir
    
    # mktemp를 사용하여 안전한 임시 디렉토리 생성
    if command -v mktemp >/dev/null 2>&1; then
        temp_dir=$(mktemp -d -t "${prefix}.XXXXXX") || {
            handle_error "임시 디렉토리 생성 실패" "true"
        }
    else
        # mktemp가 없는 경우 fallback
        temp_dir="/tmp/${prefix}_$$_$(date +%s)"
        mkdir -p "$temp_dir" || {
            handle_error "임시 디렉토리 생성 실패" "true"
        }
    fi
    
    # 권한 설정
    chmod 700 "$temp_dir" || {
        handle_error "임시 디렉토리 권한 설정 실패" "true"
    }
    
    echo "$temp_dir"
}

# ==============================================
# 앱 백업 및 복원 함수들
# ==============================================

# Homebrew Bundle 백업 생성
backup_homebrew_bundle() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local bundle_file="$backup_dir/Brewfile_$timestamp"
    
    log_info "Homebrew Bundle 백업 생성 중..."
    
    if brew bundle dump --file="$bundle_file" 2>/dev/null; then
        log_success "Homebrew Bundle 백업 완료: $bundle_file"
        echo "$bundle_file"
        return 0
    else
        handle_error "Homebrew Bundle 백업 실패"
        return 1
    fi
}

# npm 전역 패키지 백업
backup_npm_globals() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local npm_file="$backup_dir/npm_globals_$timestamp.txt"
    
    log_info "npm 전역 패키지 백업 생성 중..."
    
    if npm list -g --depth=0 > "$npm_file" 2>/dev/null; then
        log_success "npm 전역 패키지 백업 완료: $npm_file"
        echo "$npm_file"
        return 0
    else
        handle_error "npm 전역 패키지 백업 실패"
        return 1
    fi
}

# 시스템 설정 백업
backup_system_settings() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local settings_file="$backup_dir/system_settings_$timestamp.txt"
    
    log_info "시스템 설정 백업 생성 중..."
    
    if defaults read > "$settings_file" 2>/dev/null; then
        log_success "시스템 설정 백업 완료: $settings_file"
        echo "$settings_file"
        return 0
    else
        handle_error "시스템 설정 백업 실패"
        return 1
    fi
}

# 앱 설정 백업
backup_app_preferences() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local prefs_dir="$backup_dir/preferences_$timestamp"
    
    log_info "앱 설정 백업 생성 중..."
    
    if [ -d "$HOME/Library/Preferences" ]; then
        if cp -R "$HOME/Library/Preferences" "$prefs_dir" 2>/dev/null; then
            log_success "앱 설정 백업 완료: $prefs_dir"
            echo "$prefs_dir"
            return 0
        else
            handle_error "앱 설정 백업 실패"
            return 1
        fi
    else
        log_warning "Preferences 디렉토리를 찾을 수 없습니다"
        return 1
    fi
}

# Android Studio 설정 백업
backup_android_studio() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local android_dir="$backup_dir/android_studio_$timestamp"
    
    log_info "Android Studio 설정 백업 생성 중..."
    
    # Android Studio 관련 디렉토리들 백업
    local android_paths=(
        "$HOME/.android"
        "$HOME/Library/Application Support/Google/AndroidStudio*"
        "$HOME/Library/Preferences/com.google.android.studio.plist"
        "$HOME/Library/Preferences/com.android.Emulator.plist"
    )
    
    local backup_created=false
    
    for path in "${android_paths[@]}"; do
        if [ -e "$path" ]; then
            local target_dir="$android_dir/$(basename "$path")"
            if cp -R "$path" "$target_dir" 2>/dev/null; then
                log_info "백업 완료: $path"
                backup_created=true
            else
                log_warning "백업 실패: $path"
            fi
        fi
    done
    
    if [ "$backup_created" = true ]; then
        log_success "Android Studio 설정 백업 완료: $android_dir"
        echo "$android_dir"
        return 0
    else
        log_warning "Android Studio 관련 파일을 찾을 수 없습니다"
        return 1
    fi
}

# 전체 시스템 백업 (포맷 전)
backup_full_system() {
    local backup_dir="${1:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local system_backup_dir="$backup_dir/full_system_$timestamp"
    
    log_info "전체 시스템 백업 시작..."
    
    # 백업 디렉토리 생성
    mkdir -p "$system_backup_dir" || {
        handle_error "시스템 백업 디렉토리 생성 실패"
        return 1
    }
    
    # 각 백업 함수 실행
    local backup_results=()
    
    # Homebrew Bundle 백업
    if homebrew_backup=$(backup_homebrew_bundle "$system_backup_dir"); then
        backup_results+=("Homebrew: $homebrew_backup")
    fi
    
    # npm 전역 패키지 백업
    if npm_backup=$(backup_npm_globals "$system_backup_dir"); then
        backup_results+=("npm: $npm_backup")
    fi
    
    # 시스템 설정 백업
    if settings_backup=$(backup_system_settings "$system_backup_dir"); then
        backup_results+=("System Settings: $settings_backup")
    fi
    
    # 앱 설정 백업
    if prefs_backup=$(backup_app_preferences "$system_backup_dir"); then
        backup_results+=("App Preferences: $prefs_backup")
    fi
    
    # Android Studio 설정 백업
    if android_backup=$(backup_android_studio "$system_backup_dir"); then
        backup_results+=("Android Studio: $android_backup")
    fi
    
    # 백업 요약 생성
    local summary_file="$system_backup_dir/backup_summary.txt"
    {
        echo "macOS System Backup Summary"
        echo "=========================="
        echo "Backup Date: $(date)"
        echo "Backup Directory: $system_backup_dir"
        echo ""
        echo "Backup Contents:"
        for result in "${backup_results[@]}"; do
            echo "- $result"
        done
        echo ""
        echo "Restore Instructions:"
        echo "1. Run: ./src/system_restore.sh --restore-from=$system_backup_dir"
        echo "2. Or manually restore each component"
    } > "$summary_file"
    
    log_success "전체 시스템 백업 완료: $system_backup_dir"
    log_info "백업 요약: $summary_file"
    
    echo "$system_backup_dir"
    return 0
}

# Homebrew Bundle 복원
restore_homebrew_bundle() {
    local bundle_file="$1"
    
    if [[ ! -f "$bundle_file" ]]; then
        handle_error "Bundle 파일을 찾을 수 없습니다: $bundle_file"
        return 1
    fi
    
    log_info "Homebrew Bundle 복원 중..."
    
    if brew bundle --file="$bundle_file" 2>/dev/null; then
        log_success "Homebrew Bundle 복원 완료"
        return 0
    else
        handle_error "Homebrew Bundle 복원 실패"
        return 1
    fi
}

# npm 전역 패키지 복원
restore_npm_globals() {
    local npm_file="$1"
    
    if [[ ! -f "$npm_file" ]]; then
        handle_error "npm 백업 파일을 찾을 수 없습니다: $npm_file"
        return 1
    fi
    
    log_info "npm 전역 패키지 복원 중..."
    
    # npm 패키지 목록에서 패키지명만 추출하여 설치
    local packages
    packages=$(grep -v "npm" "$npm_file" | awk '{print $2}' | grep -v "empty" | grep -v "UNMET" | grep -v "npm ERR!")
    
    if [[ -n "$packages" ]]; then
        for package in $packages; do
            if [[ -n "$package" && "$package" != "npm" ]]; then
                log_info "npm 패키지 설치 중: $package"
                if npm install -g "$package" 2>/dev/null; then
                    log_info "✅ $package 설치 완료"
                else
                    log_warning "⚠️ $package 설치 실패"
                fi
            fi
        done
        log_success "npm 전역 패키지 복원 완료"
    else
        log_warning "복원할 npm 패키지가 없습니다"
    fi
    
    return 0
}

# 시스템 설정 복원
restore_system_settings() {
    local settings_file="$1"
    
    if [[ ! -f "$settings_file" ]]; then
        handle_error "시스템 설정 백업 파일을 찾을 수 없습니다: $settings_file"
        return 1
    fi
    
    log_info "시스템 설정 복원 중..."
    log_warning "⚠️ 시스템 설정 복원은 수동으로 진행해야 합니다"
    log_info "백업 파일: $settings_file"
    log_info "각 설정을 개별적으로 확인하고 복원하세요"
    
    return 0
}

# 앱 설정 복원
restore_app_preferences() {
    local prefs_dir="$1"
    
    if [[ ! -d "$prefs_dir" ]]; then
        handle_error "앱 설정 백업 디렉토리를 찾을 수 없습니다: $prefs_dir"
        return 1
    fi
    
    log_info "앱 설정 복원 중..."
    
    # 기존 Preferences 디렉토리 백업
    if [ -d "$HOME/Library/Preferences" ]; then
        local backup_prefs="$HOME/Library/Preferences.backup.$(date +%s)"
        if cp -R "$HOME/Library/Preferences" "$backup_prefs" 2>/dev/null; then
            log_info "기존 설정 백업: $backup_prefs"
        fi
    fi
    
    # 백업된 설정 복원
    if cp -R "$prefs_dir"/* "$HOME/Library/Preferences/" 2>/dev/null; then
        log_success "앱 설정 복원 완료"
        return 0
    else
        handle_error "앱 설정 복원 실패"
        return 1
    fi
}

# Android Studio 설정 복원
restore_android_studio() {
    local android_dir="$1"
    
    if [[ ! -d "$android_dir" ]]; then
        handle_error "Android Studio 백업 디렉토리를 찾을 수 없습니다: $android_dir"
        return 1
    fi
    
    log_info "Android Studio 설정 복원 중..."
    
    # 각 백업된 디렉토리 복원
    for backup_path in "$android_dir"/*; do
        if [ -d "$backup_path" ]; then
            local dir_name=$(basename "$backup_path")
            local target_path="$HOME"
            
            case "$dir_name" in
                ".android")
                    target_path="$HOME/.android"
                    ;;
                "AndroidStudio"*)
                    target_path="$HOME/Library/Application Support/Google/"
                    ;;
                "preferences_*")
                    target_path="$HOME/Library/Preferences/"
                    ;;
            esac
            
            if [ -d "$target_path" ]; then
                if cp -R "$backup_path"/* "$target_path/" 2>/dev/null; then
                    log_info "복원 완료: $dir_name"
                else
                    log_warning "복원 실패: $dir_name"
                fi
            fi
        fi
    done
    
    log_success "Android Studio 설정 복원 완료"
    return 0
}

# 전체 시스템 복원
restore_full_system() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        handle_error "백업 디렉토리를 찾을 수 없습니다: $backup_dir"
        return 1
    fi
    
    log_info "전체 시스템 복원 시작..."
    
    # 백업 요약 파일 확인
    local summary_file="$backup_dir/backup_summary.txt"
    if [ -f "$summary_file" ]; then
        log_info "백업 요약:"
        cat "$summary_file" | tee -a "$LOG_FILE"
    fi
    
    # 각 백업 파일 찾기 및 복원
    local restored_count=0
    
    # Homebrew Bundle 복원
    for bundle_file in "$backup_dir"/Brewfile_*; do
        if [ -f "$bundle_file" ]; then
            if restore_homebrew_bundle "$bundle_file"; then
                ((restored_count++))
            fi
            break
        fi
    done
    
    # npm 전역 패키지 복원
    for npm_file in "$backup_dir"/npm_globals_*; do
        if [ -f "$npm_file" ]; then
            if restore_npm_globals "$npm_file"; then
                ((restored_count++))
            fi
            break
        fi
    done
    
    # 앱 설정 복원
    for prefs_dir in "$backup_dir"/preferences_*; do
        if [ -d "$prefs_dir" ]; then
            if restore_app_preferences "$prefs_dir"; then
                ((restored_count++))
            fi
            break
        fi
    done
    
    # Android Studio 설정 복원
    for android_dir in "$backup_dir"/android_studio_*; do
        if [ -d "$android_dir" ]; then
            if restore_android_studio "$android_dir"; then
                ((restored_count++))
            fi
            break
        fi
    done
    
    log_success "전체 시스템 복원 완료 ($restored_count개 구성 요소)"
    return 0
}

# ==============================================
# 초기화 함수
# ==============================================

# 공통 스크립트 초기화
init_common() {
    local script_name="$1"
    
    # 입력 검증
    if [[ -z "$script_name" ]]; then
        echo "🛑 FATAL: init_common() requires script name parameter"
        exit 1
    fi
    
    # 로깅 시스템 초기화
    setup_logging "$script_name"
    
    # 시그널 핸들러 설정
    setup_signal_handlers
    
    # 초기화 완료 로그
    log_success "공통 시스템 초기화 완료"
    log_info "스크립트: $script_name"
    log_info "로그 파일: $LOG_FILE"
    
    return 0
}

# ==============================================
# 진행률 및 상태 표시
# ==============================================

# 진행률 표시 함수
show_progress() {
    local current="$1"
    local total="$2"
    local description="${3:-작업 진행 중}"
    
    # 입력 검증
    if [[ ! "$current" =~ ^[0-9]+$ ]] || [[ ! "$total" =~ ^[0-9]+$ ]]; then
        log_warning "show_progress: 잘못된 매개변수"
        return 1
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    # 진행률 바 생성
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    printf "\r%s [%s] %d%% (%d/%d)" "$description" "$bar" "$percentage" "$current" "$total"
    
    # 완료되면 새 줄
    if [[ "$current" -eq "$total" ]]; then
        echo ""
        log_success "$description 완료"
    fi
}

# 스피너 표시 (백그라운드 작업용)
show_spinner() {
    local pid="$1"
    local description="${2:-작업 중}"
    local delay=0.1
    local spinstr="|/-\\"
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(((i + 1) % 4))
        printf "\r%s %c" "$description" "${spinstr:$i:1}"
        sleep "$delay"
    done

    printf "\r%s 완료\n" "$description"
}

# ==============================================
# 버전 정보
# ==============================================

# 공통 라이브러리 버전
COMMON_VERSION="2.0.0"

# 버전 정보 출력
show_common_version() {
    echo "macOS System Utilities Common Library v$COMMON_VERSION"
}

# ==============================================
# UI 표준화 함수들
# ==============================================

# 표준화된 섹션 헤더
print_section_header() {
    local section_title="$1"
    local section_number="${2:-}"
    
    echo ""
    if [[ -n "$section_number" ]]; then
        echo "========================================="
        echo "섹션 $section_number: $section_title"
        echo "========================================="
    fi
}

# 안전한 캐시 정리
safe_clear_cache() {
    local cache_path="$1"
    local dry_run="${2:-false}"
    local max_age_days="${3:-30}"
    
    if [[ ! -d "$cache_path" ]]; then
        log_info "캐시 디렉토리가 존재하지 않습니다: $cache_path"
        return 0
    fi
    
    log_info "캐시 정리 중: $cache_path (${max_age_days}일 이상 된 파일)"
    
    if [[ "$dry_run" == "true" ]]; then
        local file_count
        file_count=$(find "$cache_path" -type f -mtime +"$max_age_days" 2>/dev/null | wc -l)
        log_info "DRY RUN: $file_count개의 파일이 삭제 예정입니다"
        return 0
    fi
    
    # 안전한 캐시 정리 실행
    local deleted_count=0
    while IFS= read -r -d '' file; do
        if rm -f "$file" 2>/dev/null; then
            ((deleted_count++))
        fi
    done < <(find "$cache_path" -type f -mtime +"$max_age_days" -print0 2>/dev/null)
    
    if [[ $deleted_count -gt 0 ]]; then
        log_success "캐시 정리 완료: $deleted_count개 파일 삭제"
    else
        log_info "정리할 캐시 파일이 없습니다"
    fi
    
    return 0
}

# 백업 생성
create_backup() {
    local source_path="$1"
    local backup_dir="${2:-$HOME/.macos_utility_backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    if [[ ! -e "$source_path" ]]; then
        log_warning "백업할 경로가 존재하지 않습니다: $source_path"
        return 1
    fi
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local backup_name
    backup_name="$(basename "$source_path")_backup_$timestamp"
    local backup_path="$backup_dir/$backup_name"
    
    log_info "백업 생성 중: $source_path -> $backup_path"
    
    if cp -R "$source_path" "$backup_path" 2>/dev/null; then
        log_success "백업 생성 완료: $backup_path"
        echo "$backup_path"
        return 0
    else
        handle_error "백업 생성 실패: $source_path"
        return 1
    fi
}
