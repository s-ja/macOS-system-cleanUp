#!/bin/bash

# system_restore.sh - macOS System Restore Utility
# v1.0 - 2025-01-XX
#
# 이 스크립트는 완전 포맷 후 클린 상태에서의 모든 앱 재설치 기능을 제공합니다.
# 시스템 백업에서 Homebrew, npm, 앱 설정, Android Studio 등을 복원합니다.

# 에러 발생 시 스크립트 중단
set -e

# 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 스크립트 설정
SCRIPT_NAME="system_restore"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_DIR="$HOME/.macos_utility_backups"
LOG_FILE=""

# 명령줄 옵션
DRY_RUN=false
AUTO_YES=false
BACKUP_ONLY=false
RESTORE_ONLY=false
RESTORE_FROM=""
SKIP_BREW=false
SKIP_NPM=false
SKIP_PREFS=false
SKIP_ANDROID=false

# 도움말 표시
show_help() {
    echo "macOS System Restore Utility v1.0 - 시스템 복원 도구"
    echo "사용법: $0 [옵션]"
    echo
    echo "주요 기능:"
    echo "  --backup-only        시스템 백업만 실행 (포맷 전)"
    echo "  --restore-only       시스템 복원만 실행 (포맷 후)"
    echo "  --restore-from=DIR   특정 백업 디렉토리에서 복원"
    echo
    echo "백업 옵션:"
    echo "  --auto-yes          모든 확인 프롬프트에 자동으로 'y' 응답"
    echo "  --dry-run           실제 작업 없이 실행할 내용만 표시"
    echo
    echo "복원 옵션 (복원 시 사용):"
    echo "  --no-brew           Homebrew 패키지 복원 건너뛰기"
    echo "  --no-npm            npm 전역 패키지 복원 건너뛰기"
    echo "  --no-prefs          앱 설정 복원 건너뛰기"
    echo "  --no-android        Android Studio 설정 복원 건너뛰기"
    echo
    echo "예시:"
    echo "  $0 --backup-only                    # 포맷 전 시스템 백업"
    echo "  $0 --restore-only                   # 포맷 후 시스템 복원"
    echo "  $0 --restore-from=/path/to/backup   # 특정 백업에서 복원"
    echo "  $0 --restore-only --no-brew         # Homebrew 제외하고 복원"
    echo
    echo "백업 위치: $BACKUP_DIR"
    echo "로그 위치: $LOG_DIR"
    exit 0
}

# 명령줄 인수 처리
process_arguments() {
    for arg in "$@"; do
        case $arg in
            --help)
                show_help
                ;;
            --backup-only)
                BACKUP_ONLY=true
                ;;
            --restore-only)
                RESTORE_ONLY=true
                ;;
            --restore-from=*)
                RESTORE_FROM="${arg#*=}"
                ;;
            --auto-yes)
                AUTO_YES=true
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
            --no-prefs)
                SKIP_PREFS=true
                ;;
            --no-android)
                SKIP_ANDROID=true
                ;;
            *)
                echo "알 수 없는 옵션: $arg"
                show_help
                ;;
        esac
    done
    
    # 옵션 검증
    if [[ "$BACKUP_ONLY" == true && "$RESTORE_ONLY" == true ]]; then
        echo "❌ --backup-only과 --restore-only는 동시에 사용할 수 없습니다"
        exit 1
    fi
    
    if [[ "$RESTORE_ONLY" == true && -z "$RESTORE_FROM" ]]; then
        echo "❌ --restore-only 사용 시 --restore-from 옵션이 필요합니다"
        echo "또는 $BACKUP_DIR에서 자동으로 최신 백업을 찾습니다"
    fi
}

# 사용자 확인 프롬프트
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$AUTO_YES" == true ]]; then
        echo "$message (자동 확인: y)"
        return 0
    fi
    
    local prompt="$message (y/n)"
    if [[ "$default" == "y" ]]; then
        prompt="$message (Y/n)"
    elif [[ "$default" == "n" ]]; then
        prompt="$message (y/N)"
    fi
    
    while true; do
        read -p "$prompt: " -r response
        case $response in
            [Yy]|"")
                if [[ "$default" == "y" || "$default" == "" ]]; then
                    return 0
                fi
                ;;
            [Nn])
                if [[ "$default" == "n" || "$default" == "" ]]; then
                    return 1
                fi
                ;;
        esac
        echo "y 또는 n을 입력하세요"
    done
}

# 최신 백업 디렉토리 찾기
find_latest_backup() {
    if [[ -n "$RESTORE_FROM" ]]; then
        if [[ -d "$RESTORE_FROM" ]]; then
            echo "$RESTORE_FROM"
            return 0
        else
            handle_error "지정된 백업 디렉토리를 찾을 수 없습니다: $RESTORE_FROM" "true"
        fi
    fi
    
    # 백업 디렉토리에서 최신 full_system 백업 찾기
    if [[ -d "$BACKUP_DIR" ]]; then
        local latest_backup
        latest_backup=$(find "$BACKUP_DIR" -type d -name "full_system_*" -exec basename {} \; | sort | tail -n 1)
        
        if [[ -n "$latest_backup" ]]; then
            echo "$BACKUP_DIR/$latest_backup"
            return 0
        fi
    fi
    
    handle_error "복원할 백업을 찾을 수 없습니다. 먼저 --backup-only로 백업을 생성하세요" "true"
}

# 시스템 백업 실행
run_system_backup() {
    log_message "========================================="
    log_message "시스템 백업 프로세스 시작"
    log_message "========================================="
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "DRY RUN: 시스템 백업을 시뮬레이션합니다"
        log_message "백업 위치: $BACKUP_DIR"
        return 0
    fi
    
    # 백업 디렉토리 확인
    if ! confirm_action "시스템 백업을 시작하시겠습니까?" "y"; then
        log_message "백업이 취소되었습니다"
        return 0
    fi
    
    # 공통 함수에서 백업 실행
    if backup_path=$(backup_full_system "$BACKUP_DIR"); then
        log_message "========================================="
        log_message "✅ 시스템 백업 완료!"
        log_message "백업 위치: $backup_path"
        log_message "========================================="
        
        # 백업 요약 표시
        local summary_file="$backup_path/backup_summary.txt"
        if [[ -f "$summary_file" ]]; then
            echo ""
            echo "📋 백업 요약:"
            cat "$summary_file"
        fi
        
        return 0
    else
        handle_error "시스템 백업 실패" "true"
    fi
}

# 시스템 복원 실행
run_system_restore() {
    local backup_path="$1"
    
    log_message "========================================="
    log_message "시스템 복원 프로세스 시작"
    log_message "========================================="
    log_message "백업 위치: $backup_path"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "DRY RUN: 시스템 복원을 시뮬레이션합니다"
        return 0
    fi
    
    # 복원 확인
    if ! confirm_action "백업에서 시스템을 복원하시겠습니까? 이 작업은 기존 설정을 덮어씁니다" "n"; then
        log_message "복원이 취소되었습니다"
        return 0
    fi
    
    # 백업 유효성 검사
    if [[ ! -d "$backup_path" ]]; then
        handle_error "백업 디렉토리를 찾을 수 없습니다: $backup_path" "true"
    fi
    
    local summary_file="$backup_path/backup_summary.txt"
    if [[ -f "$summary_file" ]]; then
        log_message "📋 백업 정보:"
        cat "$summary_file" | tee -a "$LOG_FILE"
        echo ""
    fi
    
    # 복원 전 시스템 상태 확인
    log_message "시스템 상태 확인 중..."
    
    # Homebrew 상태 확인
    if [[ "$SKIP_BREW" != true ]]; then
        if ! command -v brew &>/dev/null; then
            log_message "⚠️ Homebrew가 설치되어 있지 않습니다. 먼저 설치하세요:"
            log_message "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            if ! confirm_action "계속 진행하시겠습니까?" "n"; then
                return 1
            fi
        fi
    fi
    
    # npm 상태 확인
    if [[ "$SKIP_NPM" != true ]]; then
        if ! command -v npm &>/dev/null; then
            log_message "⚠️ npm이 설치되어 있지 않습니다. Node.js를 먼저 설치하세요"
            if ! confirm_action "계속 진행하시겠습니까?" "n"; then
                return 1
            fi
        fi
    fi
    
    # 복원 실행
    log_message "복원 시작..."
    
    local restored_count=0
    
    # Homebrew Bundle 복원
    if [[ "$SKIP_BREW" != true ]]; then
        for bundle_file in "$backup_path"/Brewfile_*; do
            if [[ -f "$bundle_file" ]]; then
                log_message "🔄 Homebrew Bundle 복원 중..."
                if restore_homebrew_bundle "$bundle_file"; then
                    ((restored_count++))
                    log_message "✅ Homebrew Bundle 복원 완료"
                else
                    log_message "⚠️ Homebrew Bundle 복원 실패"
                fi
                break
            fi
        done
    else
        log_message "⏭️ Homebrew 복원 건너뛰기"
    fi
    
    # npm 전역 패키지 복원
    if [[ "$SKIP_NPM" != true ]]; then
        for npm_file in "$backup_path"/npm_globals_*; do
            if [[ -f "$npm_file" ]]; then
                log_message "🔄 npm 전역 패키지 복원 중..."
                if restore_npm_globals "$npm_file"; then
                    ((restored_count++))
                    log_message "✅ npm 전역 패키지 복원 완료"
                else
                    log_message "⚠️ npm 전역 패키지 복원 실패"
                fi
                break
            fi
        done
    else
        log_message "⏭️ npm 복원 건너뛰기"
    fi
    
    # 앱 설정 복원
    if [[ "$SKIP_PREFS" != true ]]; then
        for prefs_dir in "$backup_path"/preferences_*; do
            if [[ -d "$prefs_dir" ]]; then
                log_message "🔄 앱 설정 복원 중..."
                if restore_app_preferences "$prefs_dir"; then
                    ((restored_count++))
                    log_message "✅ 앱 설정 복원 완료"
                else
                    log_message "⚠️ 앱 설정 복원 실패"
                fi
                break
            fi
        done
    else
        log_message "⏭️ 앱 설정 복원 건너뛰기"
    fi
    
    # Android Studio 설정 복원
    if [[ "$SKIP_ANDROID" != true ]]; then
        for android_dir in "$backup_path"/android_studio_*; do
            if [[ -d "$android_dir" ]]; then
                log_message "🔄 Android Studio 설정 복원 중..."
                if restore_android_studio "$android_dir"; then
                    ((restored_count++))
                    log_message "✅ Android Studio 설정 복원 완료"
                else
                    log_message "⚠️ Android Studio 설정 복원 실패"
                fi
                break
            fi
        done
    else
        log_message "⏭️ Android Studio 복원 건너뛰기"
    fi
    
    # 복원 완료 요약
    log_message "========================================="
    log_message "✅ 시스템 복원 완료!"
    log_message "복원된 구성 요소: $restored_count개"
    log_message "========================================="
    
    # 후속 작업 안내
    echo ""
    echo "🎉 시스템 복원이 완료되었습니다!"
    echo ""
    echo "📋 다음 단계:"
    echo "1. 시스템 재부팅 권장"
    echo "2. 앱들이 정상적으로 작동하는지 확인"
    echo "3. 필요한 경우 개별 앱 설정 조정"
    echo "4. 로그 파일 확인: $LOG_FILE"
    
    return 0
}

# 메인 함수
main() {
    # 명령줄 인수 처리
    process_arguments "$@"
    
    # 공통 시스템 초기화
    if ! init_common "$SCRIPT_NAME"; then
        echo "🛑 공통 시스템 초기화 실패"
        exit 1
    fi
    
    # 로그 파일 경로 설정
    LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +"%Y%m%d_%H%M%S").log"
    
    # 시작 로그
    log_message "========================================="
    log_message "macOS System Restore Utility 시작"
    log_message "========================================="
    log_message "스크립트: $0"
    log_message "로그 파일: $LOG_FILE"
    log_message "백업 디렉토리: $BACKUP_DIR"
    
    # 옵션 상태 로그
    log_message "옵션 상태:"
    log_message "  DRY_RUN: $DRY_RUN"
    log_message "  AUTO_YES: $AUTO_YES"
    log_message "  BACKUP_ONLY: $BACKUP_ONLY"
    log_message "  RESTORE_ONLY: $RESTORE_ONLY"
    log_message "  SKIP_BREW: $SKIP_BREW"
    log_message "  SKIP_NPM: $SKIP_NPM"
    log_message "  SKIP_PREFS: $SKIP_PREFS"
    log_message "  SKIP_ANDROID: $SKIP_ANDROID"
    
    # 작업 실행
    if [[ "$BACKUP_ONLY" == true ]]; then
        # 백업만 실행
        run_system_backup
    elif [[ "$RESTORE_ONLY" == true ]]; then
        # 복원만 실행
        local backup_path
        backup_path=$(find_latest_backup)
        run_system_restore "$backup_path"
    else
        # 기본: 백업 후 복원 (테스트용)
        log_message "기본 모드: 백업 후 복원 테스트"
        run_system_backup
        echo ""
        if confirm_action "백업이 완료되었습니다. 복원을 테스트하시겠습니까?" "n"; then
            local backup_path
            backup_path=$(find_latest_backup)
            run_system_restore "$backup_path"
        fi
    fi
    
    # 완료 로그
    log_message "========================================="
    log_message "macOS System Restore Utility 완료"
    log_message "========================================="
    
    return 0
}

# 스크립트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
