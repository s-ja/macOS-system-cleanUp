#!/bin/bash

# 임시 파일 경로 설정
TEMP_DIR="/tmp/brew_replace"
INSTALLED_APPS="$TEMP_DIR/apps_installed.txt"
AVAILABLE_CASKS="$TEMP_DIR/casks_available.txt"

# 임시 디렉토리 생성
mkdir -p "$TEMP_DIR"

# Homebrew 업데이트
echo "Homebrew 업데이트를 시작합니다..."
brew update

# Homebrew Cask 업데이트
echo -e "\nHomebrew Cask 업데이트를 시작합니다..."
brew cu -a --cleanup

# topgrade 실행
echo -e "\ntopgrade를 실행하여 모든 패키지와 앱을 업데이트합니다..."
if ! command -v topgrade &> /dev/null; then
    echo "topgrade가 설치되어 있지 않습니다. 설치를 시작합니다..."
    brew install topgrade
fi

# topgrade 실행 (자동 모드)
topgrade --yes

# /Applications 디렉토리로 이동
cd /Applications

echo -e "\nHomebrew Cask로 설치 가능한 앱을 검색합니다..."

# 현재 설치된 Cask 목록 저장
brew list --cask > "$INSTALLED_APPS"

# 설치 가능한 Cask 목록 저장 (모든 cask 검색)
brew search --casks "" > "$AVAILABLE_CASKS"

# 발견된 앱을 저장할 배열
declare -a found_apps

# 각 .app 파일에 대해 확인
for app in *.app; do
  # 앱 이름에서 .app 제거 및 공백을 하이픈으로 변경
  app_name="${app%.app}"
  cask_name="${app_name// /-}"

  # 설치 가능한 Cask 목록에 있는지 확인
  if grep -Fxq "$cask_name" "$AVAILABLE_CASKS"; then
    # 이미 설치된 Cask 목록에 없는 경우
    if ! grep -Fxq "$cask_name" "$INSTALLED_APPS"; then
      # 앱 버전 확인
      app_version=$(mdls -name kMDItemVersion "$app" | awk -F'"' '{print $2}')
      echo "Homebrew Cask로 설치 가능한 앱 발견: $app_name (현재 버전: $app_version)"
      found_apps+=("$cask_name")
    fi
  fi
done

# 발견된 앱이 있는 경우
if [ ${#found_apps[@]} -gt 0 ]; then
  echo -e "\n다음 앱들을 Homebrew Cask로 설치하시겠습니까? (y/n)"
  for app in "${found_apps[@]}"; do
    echo "- $app"
  done
  
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "\n설치를 시작합니다..."
    for app in "${found_apps[@]}"; do
      echo "Installing $app..."
      brew install --cask --force "$app"
    done
    echo -e "\n설치가 완료되었습니다."
  else
    echo "설치가 취소되었습니다."
  fi
else
  echo "Homebrew Cask로 설치 가능한 새로운 앱이 없습니다."
fi

# 임시 파일 정리
rm -rf "$TEMP_DIR"

echo -e "\n모든 업데이트가 완료되었습니다."