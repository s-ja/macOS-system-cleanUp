# 설치 가이드

[View in English](INSTALLATION.md)

## 필수 조건

- macOS 운영 체제
- Bash 쉘
- Homebrew 패키지 관리자
- 인터넷 연결

## 기본 설치

1. 저장소 클론:

   ```bash
   git clone https://github.com/your-username/macos-system-cleanup.git
   cd macos-system-cleanup
   ```

2. 스크립트 실행 권한 부여:

   ```bash
   chmod +x src/cleanup/system_cleanup.sh
   chmod +x src/upgrade/system_upgrade.sh
   ```

3. (선택 사항) 시스템 전체에서 접근 가능하도록 심볼릭 링크 생성:
   ```bash
   sudo ln -s $(pwd)/src/cleanup/system_cleanup.sh /usr/local/bin/system_cleanup
   sudo ln -s $(pwd)/src/upgrade/system_upgrade.sh /usr/local/bin/system_upgrade
   ```

## 권한 설정

다음 디렉토리에 대한 적절한 권한을 확인하세요:

- Homebrew 디렉토리
- 시스템 캐시 디렉토리
- 임시 디렉토리

## 환경 설정

1. Homebrew 설치 확인:

   ```bash
   brew doctor
   ```

2. 필수 의존성 설치:

   ```bash
   brew install ruby
   ```

3. 쉘 환경 설정:
   ```bash
   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

## 설치 확인

1. 스크립트 실행 테스트:

   ```bash
   # 시스템 정리 유틸리티 테스트
   ./src/cleanup/system_cleanup.sh --dry-run

   # 시스템 업그레이드 유틸리티 테스트
   ./src/upgrade/system_upgrade.sh --check-only
   ```

2. 로그 디렉토리 확인:
   ```bash
   ls -la ~/logs
   ```

## 문제 해결

설치 중 문제가 발생하면 다음을 확인하세요:

1. Homebrew 권한:

   ```bash
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```

2. Ruby 버전:

   ```bash
   ruby -v  # 3.2.0 이상 필요
   ```

3. 로그 디렉토리 권한:
   ```bash
   mkdir -p ~/logs
   chmod 755 ~/logs
   ```

자세한 문제 해결은 각 유틸리티의 문제 해결 가이드를 참조하세요:

- [시스템 정리 유틸리티 문제 해결](../cleanup/TROUBLESHOOTING.kr.md)
- [시스템 업그레이드 유틸리티 문제 해결](../upgrade/TROUBLESHOOTING.kr.md)
