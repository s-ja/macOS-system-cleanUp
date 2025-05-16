# Security Policy

[한국어 문서 보기](SECURITY.kr.md)

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

## Reporting a Vulnerability

1. **DO NOT** open a public issue
2. Email security concerns to [security@your-domain.com]
3. Include detailed steps to reproduce
4. Wait for response within 48 hours

## Security Considerations

### File System Operations

- Scripts avoid modifying system files
- User confirmation required for sensitive operations
- Proper permission checks before operations
- Safe cleanup procedures

### Elevated Privileges

- Minimal use of sudo
- Clear documentation of sudo usage
- Proper permission handling
- Secure temporary file management

### Data Safety

- Backup recommendations
- Safe cleanup procedures
- Data integrity checks
- Error recovery mechanisms

## Best Practices

### For Users

1. Always review scripts before running
2. Keep backups before major operations
3. Use `--dry-run` option first
4. Follow security advisories

### For Contributors

1. Use shellcheck for security analysis
2. Follow secure coding guidelines
3. Document security implications
4. Test thoroughly before PR

## Security Features

- Secure temporary file handling
- Permission validation
- Error recovery mechanisms
- Audit logging
- Dry run support

## Updates

Security updates will be released as needed with:

- Clear documentation
- Migration guides
- Version bumps
- Changelog entries
