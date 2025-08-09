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
    
    if [[ $before =~ ^[0-9]+$ ]] && [[ $after =~ ^[0-9]+$ ]]; then
        local saved=$((after - before))
        echo "$(format_disk_space $saved)"
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
} 