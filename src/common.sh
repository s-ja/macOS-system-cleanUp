#!/bin/zsh
# common.sh - 공통 함수 라이브러리
# macOS 시스템 유지보수 스크립트들을 위한 통합 함수 모음

# ==============================================
# 전역 변수 설정
# ==============================================

# 안전한 PATH 설정 (시스템 명령어 접근 보장)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 명령어 alias 설정 (확실한 접근 보장)
alias awk='/usr/bin/awk'

# 스크립트 정보 설정
# zsh와 bash 모두 호환되는 스크립트 경로 얻기
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

# 로그 파일 변수 (각 스크립트에서 설정)
# declare -g는 Bash 4.2+ 필요, 호환성을 위해 일반 변수로 선언
LOG_FILE=""

# ==============================================
# 로깅 시스템
# ==============================================

# 로그 시스템 초기화
setup_logging() {
    local script_name="$1"
    
    # 입력 검증
    if [[ -z "$script_name" ]]; then
        echo "🛑 FATAL: setup_logging() requires script name parameter"
        exit 1
    fi
    
    # 로그 디렉토리 생성
    if ! mkdir -p "$LOG_DIR"; then
        echo "🛑 FATAL: 로그 디렉토리 생성 실패: $LOG_DIR"
        exit 1
    fi
    
    # 로그 파일 경로 설정
    LOG_FILE="$LOG_DIR/${script_name}_$(date +"%Y%m%d_%H%M%S").log"
    
    # 로그 파일 초기화
    if ! touch "$LOG_FILE"; then
        echo "🛑 FATAL: 로그 파일 생성 실패: $LOG_FILE"
        echo "권한을 확인하고 다시 시도하세요."
        exit 1
    fi
    
    # 성공 시 로그 파일 경로 반환
    echo "$LOG_FILE"
}

# 통합 로깅 함수 (로그 파일이 설정된 경우 자동 사용)
log_message() {
    local message="$1"
    local timestamp="$(date +"%Y-%m-%d %H:%M:%S")"
    
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
        echo "$(format_disk_space "$saved")"
    elif [ "$saved" -lt 0 ]; then
        echo "-$(format_disk_space $((-saved)))"
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

# 디렉토리 존재 및 쓰기 권한 확인
check_directory_writable() {
    local dir_path="$1"
    
    # 입력 검증
    if [[ -z "$dir_path" ]]; then
        return 1
    fi
    
    # 디렉토리 존재 여부 확인
    if [[ ! -d "$dir_path" ]]; then
        return 1
    fi
    
    # 쓰기 권한 확인
    if [[ -w "$dir_path" ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================
# 사용자 입력 검증 및 처리
# ==============================================

# 안전한 사용자 입력 받기
get_user_input() {
    local prompt="$1"
    local default_value="${2:-}"
    local valid_options="${3:-}"
    local user_input=""
    
    # 기본 타임아웃 30초로 get_user_input_with_timeout 호출
    get_user_input_with_timeout "$1" "$2" "$3" 30
}

# 타임아웃 지원 사용자 입력 받기
get_user_input_with_timeout() {
    local prompt="$1"
    local default_value="${2:-}"
    local valid_options="${3:-}"
    local timeout="${4:-30}"
    local user_input=""
    
    # 입력 검증
    if [[ -z "$prompt" ]]; then
        handle_error "get_user_input() requires prompt parameter"
        return 1
    fi
    
    while true; do
        # 프롬프트 출력
        if [[ -n "$default_value" ]]; then
            printf "%s [기본값: %s]: " "$prompt" "$default_value"
        else
            printf "%s: " "$prompt"
        fi
        
        # 입력 받기
        if read -r user_input; then
            # 빈 입력시 기본값 사용
            if [[ -z "$user_input" && -n "$default_value" ]]; then
                user_input="$default_value"
            fi

            # 유효한 옵션이 지정된 경우 검증
            if [[ -n "$valid_options" ]]; then
                if echo "$valid_options" | grep -q "$user_input"; then
                    echo "$user_input"
                    return 0
                else
                    log_warning "유효하지 않은 입력입니다. 다음 중 선택하세요: $valid_options"
                    continue
                fi
            else
                echo "$user_input"
                return 0
            fi
        fi
    done
}

# Y/N 확인 입력 받기
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"
    local timeout="${3:-30}"
    local response
    
    response=$(get_user_input_with_timeout "$prompt (y/n)" "$default" "y n Y N" "$timeout")
    
    case "$response" in
        [Yy]*)
            return 0
            ;;
        [Nn]*)
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ==============================================
# 시스템 상태 확인 함수
# ==============================================

# 명령어 존재 여부 확인
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Docker 데몬 실행 상태 확인
check_docker_daemon() {
    if ! command_exists docker; then
        log_info "Docker가 설치되어 있지 않습니다"
        return 1
    fi
    
    if docker info >/dev/null 2>&1; then
        return 0
    else
        log_info "Docker 데몬이 실행되고 있지 않습니다"
        return 1
    fi
}

# Xcode 설치 상태 확인
check_xcode_installed() {
    if ! command_exists xcode-select; then
        log_info "Xcode 명령줄 도구가 설치되어 있지 않습니다"
        return 1
    fi
    
    if xcode-select -p >/dev/null 2>&1; then
        return 0
    else
        log_info "Xcode가 설치되어 있지 않습니다"
        return 1
    fi
}

# Homebrew 상태 확인
check_homebrew_health() {
    if ! command_exists brew; then
        log_info "Homebrew가 설치되어 있지 않습니다"
        return 1
    fi
    
    # root 사용자로 실행 중인지 확인
    if [ "$(id -u)" = "0" ]; then
        log_warning "Homebrew는 root 사용자로 실행할 수 없습니다"
        return 1
    fi
    
    # brew doctor 실행으로 상태 확인 (출력 내용 분석)
    local doctor_output
    doctor_output=$(brew doctor 2>&1)
    local doctor_exit_code=$?
    
    # 정상 상태 메시지 확인 ("Your system is ready to brew.")
    if [[ "$doctor_output" == *"Your system is ready to brew"* ]]; then
        return 0
    fi
    
    # PATH 관련 warning만 있는 경우는 정상으로 처리
    if [[ "$doctor_output" == *"occurs before"* ]] && [[ "$doctor_output" == *"in your PATH"* ]]; then
        # PATH warning만 있고 다른 critical 오류가 없으면 정상
        if [[ "$doctor_output" != *"Error:"* ]] && [[ "$doctor_output" != *"Fatal:"* ]]; then
            return 0
        fi
    fi
    
    # "please don't worry or file an issue; just ignore this" 메시지가 있으면 정상
    if [[ "$doctor_output" == *"just ignore this"* ]] && [[ "$doctor_output" != *"Error:"* ]]; then
        return 0
    fi
    
    # Warning만 있고 치명적인 오류가 없으면 정상으로 처리
    if [[ "$doctor_output" == *"Warning:"* ]] && [[ "$doctor_output" != *"Error:"* ]] && [[ "$doctor_output" != *"Fatal:"* ]]; then
        return 0
    fi
    
    # 실제 치명적 오류가 있는 경우만 문제로 판단
    log_warning "Homebrew 상태에 문제가 있습니다"
    return 1
}

# ==============================================
# 클린업 및 종료 처리
# ==============================================

# 임시 파일 정리 함수
cleanup_temp_files() {
    local temp_dirs=("$@")
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
            log_info "임시 디렉토리 정리 중: $temp_dir"
            if rm -rf "$temp_dir"; then
                log_success "임시 디렉토리 정리 완료: $temp_dir"
            else
                log_warning "임시 디렉토리 정리 실패: $temp_dir"
            fi
        fi
    done
}

# 스크립트 종료 시 실행할 정리 함수
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "스크립트가 성공적으로 완료되었습니다"
    elif [[ $exit_code -eq 130 ]]; then
        log_warning "사용자에 의해 스크립트가 중단되었습니다"
    else
        log_warning "스크립트가 오류와 함께 종료되었습니다 (종료 코드: $exit_code)"
    fi
    
    # 로그 파일 위치 안내
    if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
        echo ""
        echo "=================================================="
        echo "로그 파일 위치: $LOG_FILE"
        echo "=================================================="
    fi
}

# 시그널 핸들러 설정
setup_signal_handlers() {
    # 스크립트 종료 시 정리 함수 실행
    trap cleanup_on_exit EXIT
    
    # 중단 시그널 처리 (Ctrl+C, TERM)
    trap 'log_warning "스크립트가 중단되었습니다"; exit 130' INT TERM
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
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%s %c" "$description" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
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
    else
        echo "========================================="
        echo "$section_title"
        echo "========================================="
    fi
    log_message "섹션 시작: $section_title"
}

# 표준화된 섹션 구분선
print_section_divider() {
    echo "----------------------------------------"
}

# 표준화된 서브섹션 헤더
print_subsection_header() {
    local subsection_title="$1"
    local subsection_number="${2:-}"
    
    echo ""
    if [[ -n "$subsection_number" ]]; then
        log_info "서브섹션 $subsection_number: $subsection_title"
        echo "--- $subsection_number. $subsection_title ---"
    else
        log_info "서브섹션: $subsection_title"
        echo "--- $subsection_title ---"
    fi
}

# 표준화된 시작 메시지
print_script_start() {
    local script_name="$1"
    local script_version="${2:-3.0}"
    
    print_section_header "$script_name v$script_version 시작"
    log_info "스크립트 시작 시간: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "실행 사용자: $(whoami)"
    log_info "시스템 정보: $(uname -a)"
}

# 표준화된 완료 메시지
print_script_end() {
    local script_name="$1"
    local success="${2:-true}"
    
    echo ""
    if [[ "$success" == "true" ]]; then
        print_section_header "$script_name 완료"
        log_success "스크립트가 성공적으로 완료되었습니다"
    else
        print_section_header "$script_name 오류로 인한 종료"
        log_warning "스크립트가 오류와 함께 종료되었습니다"
    fi
    log_info "스크립트 종료 시간: $(date)"
}

# DRY RUN 모드 경고 메시지
print_dry_run_warning() {
    echo ""
    echo "🔍 DRY RUN 모드가 활성화되었습니다"
    echo "   실제 변경사항은 적용되지 않고, 수행할 작업만 표시됩니다."
    echo ""
    log_warning "DRY RUN 모드로 실행 중"
}

# 작업 완료 요약
print_summary() {
    local total_tasks="$1"
    local completed_tasks="$2"
    local failed_tasks="${3:-0}"
    local space_saved="${4:-알 수 없음}"
    
    print_section_header "작업 요약"
    echo "총 작업 수:     $total_tasks"
    echo "완료된 작업:    $completed_tasks"
    echo "실패한 작업:    $failed_tasks"
    echo "절약된 공간:    $space_saved"
    echo ""
    
    if [[ $failed_tasks -eq 0 ]]; then
        log_success "모든 작업이 성공적으로 완료되었습니다"
    else
        log_warning "$failed_tasks개의 작업이 실패했습니다"
    fi
}

# ==============================================
# 안전한 파일 작업 함수들
# ==============================================

# 안전한 파일/디렉토리 삭제
safe_remove() {
    local target_path="$1"
    local confirmation_required="${2:-true}"
    local dry_run="${3:-false}"
    
    # 입력 검증
    if [[ -z "$target_path" ]]; then
        handle_error "safe_remove: 경로가 지정되지 않았습니다"
        return 1
    fi
    
    # 경로 정규화
    target_path=$(realpath "$target_path" 2>/dev/null || echo "$target_path")
    
    # 중요 디렉토리 보호
    local protected_paths=(
        "/"
        "/usr"
        "/bin"
        "/sbin"
        "/etc"
        "/var"
        "/System"
        "/Applications"
        "/Library"
        "$HOME"
        "$HOME/Documents"
        "$HOME/Desktop"
        "$HOME/Downloads"
    )
    
    for protected in "${protected_paths[@]}"; do
        if [[ "$target_path" == "$protected" ]] || [[ "$target_path" == "$protected/"* ]]; then
            handle_error "safe_remove: 보호된 경로입니다: $target_path"
            return 1
        fi
    done
    
    # 존재 여부 확인
    if [[ ! -e "$target_path" ]]; then
        log_info "safe_remove: 경로가 존재하지 않습니다: $target_path"
        return 0
    fi
    
    # DRY RUN 모드
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: 삭제 예정 - $target_path"
        return 0
    fi
    
    # 확인 요청
    if [[ "$confirmation_required" == "true" ]]; then
        if [[ -d "$target_path" ]]; then
            if ! confirm_action "디렉토리를 삭제하시겠습니까: $target_path" "n"; then
                log_info "사용자가 삭제를 취소했습니다: $target_path"
                return 1
            fi
        else
            if ! confirm_action "파일을 삭제하시겠습니까: $target_path" "n"; then
                log_info "사용자가 삭제를 취소했습니다: $target_path"
                return 1
            fi
        fi
    fi
    
    # 안전한 삭제 실행
    log_info "삭제 중: $target_path"
    if rm -rf "$target_path" 2>/dev/null; then
        log_success "삭제 완료: $target_path"
        return 0
    else
        handle_error "삭제 실패: $target_path"
        return 1
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
        file_count=$(find "$cache_path" -type f -mtime +$max_age_days 2>/dev/null | wc -l)
        log_info "DRY RUN: $file_count개의 파일이 삭제 예정입니다"
        return 0
    fi
    
    # 안전한 캐시 정리 실행
    local deleted_count=0
    while IFS= read -r -d '' file; do
        if rm -f "$file" 2>/dev/null; then
            ((deleted_count++))
        fi
    done < <(find "$cache_path" -type f -mtime +$max_age_days -print0 2>/dev/null)
    
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
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    if [[ ! -e "$source_path" ]]; then
        log_warning "백업할 경로가 존재하지 않습니다: $source_path"
        return 1
    fi
    
    # 백업 디렉토리 생성
    mkdir -p "$backup_dir" || {
        handle_error "백업 디렉토리 생성 실패: $backup_dir"
        return 1
    }
    
    local backup_name="$(basename "$source_path")_backup_$timestamp"
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