#!/bin/bash
# common/logging.sh - 공통 로깅 및 오류 처리 함수

# 로그 디렉토리 설정 함수
setup_logging() {
    local script_name="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$(dirname "$script_dir")")"
    local log_dir="$project_root/logs"
    local log_file="$log_dir/${script_name}_$(date +"%Y%m%d_%H%M%S").log"
    
    # 로그 디렉토리 생성
    mkdir -p "$log_dir"
    
    # 로그 파일 초기화
    touch "$log_file" || {
        echo "🛑 FATAL: 로그 파일 생성 실패. 권한 확인 필요"
        exit 1
<<<<<<< HEAD
    fi
    
    # 성공 시 로그 파일 경로 반환
    echo "$LOG_FILE"
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
=======
>>>>>>> origin/main
    }
    
    echo "$log_file"
}

# 메시지 로깅 함수
log_message() {
    local log_file="$1"
    local message="$2"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$log_file"
}

# 오류 처리 함수
handle_error() {
    local log_file="$1"
    local error_message="$2"
    echo "ERROR: $error_message" | tee -a "$log_file"
    echo "Continuing with next task..." | tee -a "$log_file"
    return 1
}

# 디스크 공간 포맷 함수
format_disk_space() {
    local space=$1
    if [ $space -ge 1073741824 ]; then
        echo "$(echo "scale=2; $space/1073741824" | bc)GB"
    elif [ $space -ge 1048576 ]; then
        echo "$(echo "scale=2; $space/1048576" | bc)MB"
    elif [ $space -ge 1024 ]; then
        echo "$(echo "scale=2; $space/1024" | bc)KB"
    else
        echo "${space}B"
    fi
}

# 공간 절약 계산 함수
calculate_space_saved() {
    local before=$1
    local after=$2
    
<<<<<<< HEAD
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
=======
    if [[ $before =~ ^[0-9]+$ ]] && [[ $after =~ ^[0-9]+$ ]]; then
        local saved=$((after - before))
        echo "$(format_disk_space $saved)"
>>>>>>> origin/main
    else
        echo "Unable to calculate"
    fi
}

# sudo 사용 가능 여부 확인 함수
check_sudo() {
    if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
<<<<<<< HEAD
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
=======
} 
>>>>>>> origin/main
