#!/bin/bash

# 에러 발생 시 스크립트 중단
set -e

# 임시 파일 경로 설정
TEMP_DIR="/tmp/brew_replace"
INSTALLED_APPS="$TEMP_DIR/apps_installed.txt"
AVAILABLE_CASKS="$TEMP_DIR/casks_available.txt"
LOG_FILE="$TEMP_DIR/upgrade.log"

# 로깅 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 에러 처리 함수
handle_error() {
    log "에러 발생: $1"
    exit 1
}

# 임시 디렉토리 생성
if ! mkdir -p "$TEMP_DIR"; then
    handle_error "임시 디렉토리 생성 실패"
fi

# 로그 파일 초기화
> "$LOG_FILE"

# Homebrew 업데이트
log "Homebrew 업데이트를 시작합니다..."
if ! brew update; then
    handle_error "Homebrew 업데이트 실패"
fi

# Homebrew Cask 업데이트
log "Homebrew Cask 업데이트를 시작합니다..."
if ! brew cu -a; then
    handle_error "Homebrew Cask 업데이트 실패"
fi

# topgrade 설치 및 실행
log "topgrade를 실행하여 모든 패키지와 앱을 업데이트합니다..."
if ! command -v topgrade &> /dev/null; then
    log "topgrade가 설치되어 있지 않습니다. 설치를 시작합니다..."
    if ! brew install topgrade; then
        handle_error "topgrade 설치 실패"
    fi
fi

# topgrade 실행 (자동 모드)
if ! topgrade --yes; then
    handle_error "topgrade 실행 실패"
fi

# /Applications 디렉토리로 이동
cd /Applications || handle_error "Applications 디렉토리 접근 실패"

log "Homebrew Cask로 설치 가능한 앱을 검색합니다..."

# 현재 설치된 Cask 목록 저장
if ! brew list --cask > "$INSTALLED_APPS"; then
    handle_error "설치된 Cask 목록 저장 실패"
fi

# 설치 가능한 Cask 목록 저장 (최적화된 검색)
if ! brew search --casks "" | grep -v "No Cask found" > "$AVAILABLE_CASKS"; then
    handle_error "사용 가능한 Cask 목록 저장 실패"
fi

# 발견된 앱을 저장할 배열
declare -a found_apps

# 각 .app 파일에 대해 확인 (성능 최적화)
find . -maxdepth 1 -name "*.app" -print0 | while IFS= read -r -d '' app; do
    app_name="${app#./}"
    app_name="${app_name%.app}"
    cask_name="${app_name// /-}"

    # 설치 가능한 Cask 목록에 있는지 확인
    if grep -Fxq "$cask_name" "$AVAILABLE_CASKS"; then
        # 이미 설치된 Cask 목록에 없는 경우
        if ! grep -Fxq "$cask_name" "$INSTALLED_APPS"; then
            # 앱 버전 확인
            app_version=$(mdls -name kMDItemVersion "$app" | awk -F'"' '{print $2}')
            log "Homebrew Cask로 설치 가능한 앱 발견: $app_name (현재 버전: $app_version)"
            found_apps+=("$cask_name")
        fi
    fi
done

# 발견된 앱이 있는 경우
if [ ${#found_apps[@]} -gt 0 ]; then
    log "다음 앱들을 Homebrew Cask로 설치하시겠습니까? (y/n)"
    for app in "${found_apps[@]}"; do
        echo "- $app"
    done
    
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log "설치를 시작합니다..."
        for app in "${found_apps[@]}"; do
            log "Installing $app..."
            if ! brew install --cask --force "$app"; then
                log "경고: $app 설치 실패"
            fi
        done
        log "설치가 완료되었습니다."
    else
        log "설치가 취소되었습니다."
    fi
else
    log "Homebrew Cask로 설치 가능한 새로운 앱이 없습니다."
fi

# 임시 파일 정리
rm -rf "$TEMP_DIR"

log "모든 업데이트가 완료되었습니다."