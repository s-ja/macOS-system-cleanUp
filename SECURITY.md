# Security Policy 보안 정책

[English](#english) | [한국어](#korean)

<a id="english"></a>

## English

### Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

### Reporting a Vulnerability

1. **DO NOT** open a public issue
2. Email security concerns to [security@your-domain.com]
3. Include detailed steps to reproduce
4. Wait for response within 48 hours

### Security Considerations

#### File System Operations

- Scripts avoid modifying system files
- User confirmation required for sensitive operations
- Proper permission checks before operations
- Safe cleanup procedures

#### Elevated Privileges

- Minimal use of sudo
- Clear documentation of sudo usage
- Proper permission handling
- Secure temporary file management

#### Data Safety

- Backup recommendations
- Safe cleanup procedures
- Data integrity checks
- Error recovery mechanisms

### Best Practices

#### For Users

1. Always review scripts before running
2. Keep backups before major operations
3. Use `--dry-run` option first
4. Follow security advisories

#### For Contributors

1. Use shellcheck for security analysis
2. Follow secure coding guidelines
3. Document security implications
4. Test thoroughly before PR

### Security Features

- Secure temporary file handling
- Permission validation
- Error recovery mechanisms
- Audit logging
- Dry run support

### Updates

Security updates will be released as needed with:

- Clear documentation
- Migration guides
- Version bumps
- Changelog entries

---

<a id="korean"></a>

## 한국어

### 지원 버전

| 버전  | 지원 여부          |
| ----- | ------------------ |
| 2.x.x | :white_check_mark: |
| 1.x.x | :x:                |

### 취약점 보고

1. 공개 이슈를 **열지 마세요**
2. 보안 관련 문제는 [security@your-domain.com]으로 이메일을 보내주세요
3. 재현 단계를 상세히 포함해주세요
4. 48시간 이내에 응답을 기다려주세요

### 보안 고려사항

#### 파일 시스템 작업

- 스크립트는 시스템 파일 수정을 피합니다
- 민감한 작업에는 사용자 확인이 필요합니다
- 작업 전 적절한 권한 검사를 수행합니다
- 안전한 정리 절차를 따릅니다

#### 권한 상승

- sudo 사용을 최소화합니다
- sudo 사용에 대해 명확히 문서화합니다
- 적절한 권한 처리를 수행합니다
- 임시 파일을 안전하게 관리합니다

#### 데이터 안전성

- 백업 권장사항 제공
- 안전한 정리 절차
- 데이터 무결성 검사
- 오류 복구 메커니즘

### 모범 사례

#### 사용자를 위한 안내

1. 실행 전 항상 스크립트를 검토하세요
2. 주요 작업 전 백업을 유지하세요
3. 먼저 `--dry-run` 옵션을 사용하세요
4. 보안 권고사항을 따르세요

#### 기여자를 위한 안내

1. 보안 분석을 위해 shellcheck를 사용하세요
2. 보안 코딩 가이드라인을 따르세요
3. 보안 영향을 문서화하세요
4. PR 전 철저히 테스트하세요

### 보안 기능

- 안전한 임시 파일 처리
- 권한 검증
- 오류 복구 메커니즘
- 감사 로깅
- 드라이 런 지원

### 업데이트

보안 업데이트는 필요에 따라 다음과 함께 릴리스됩니다:

- 명확한 문서화
- 마이그레이션 가이드
- 버전 업데이트
- 변경 이력 항목
