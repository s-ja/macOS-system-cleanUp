# Contributing Guidelines

[한국어 문서 보기](CONTRIBUTING.kr.md)

## Code of Conduct

- Be respectful of others
- Use inclusive language
- Accept constructive criticism
- Focus on what is best for the community

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Development Setup

1. Install dependencies:

   ```bash
   brew install ruby
   brew install shellcheck  # for shell script linting
   ```

2. Set up pre-commit hooks:
   ```bash
   cp hooks/pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit
   ```

## Coding Standards

### Shell Scripts

- Use shellcheck for linting
- Follow Google's Shell Style Guide
- Add comments for complex logic
- Use meaningful variable names

### Documentation

- Keep README files up to date
- Document all new features
- Include examples where appropriate
- Maintain both English and Korean versions

## Testing

- Add tests for new features
- Ensure all tests pass before submitting PR
- Include both unit and integration tests
- Test on different macOS versions if possible

## Pull Request Process

1. Update documentation
2. Update CHANGELOG.md
3. Update version numbers
4. Get review from maintainers

## Commit Messages

Follow the conventional commits specification:

```
type(scope): description

[optional body]

[optional footer]
```

Types:

- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Adding tests
- chore: Maintenance

## Questions?

Feel free to open an issue for any questions or concerns.
