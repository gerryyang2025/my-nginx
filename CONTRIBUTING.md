# Contributing to Nginx Reverse Proxy Setup

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Issues

Before creating bug reports, please check the existing issues to see if the problem has already been reported.

When creating a bug report, please include:

- **Operating System**: Linux distribution and version
- **Nginx Version**: Version of Nginx being used
- **Error Messages**: Complete error messages and logs
- **Steps to Reproduce**: Clear steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened

### Suggesting Enhancements

We welcome suggestions for new features and improvements. Please:

- Describe the enhancement clearly
- Explain why this enhancement would be useful
- Provide examples of how it would work
- Consider the impact on existing functionality

### Code Contributions

#### Prerequisites

- Basic knowledge of bash scripting
- Understanding of Nginx configuration
- Familiarity with Linux system administration

#### Development Setup

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear commit messages
7. Push to your fork and submit a pull request

#### Code Style Guidelines

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing code formatting
- Include error handling
- Test scripts on multiple Linux distributions

#### Testing

Before submitting a pull request:

- Test on at least two different Linux distributions
- Verify that all scripts run without errors
- Test both successful and error scenarios
- Ensure backward compatibility

### Pull Request Process

1. **Update Documentation**: Update README.md if your changes affect usage
2. **Add Tests**: Include tests for new functionality
3. **Update Changelog**: Document your changes in CHANGELOG.md
4. **Submit PR**: Create a pull request with a clear description

### Commit Message Format

Use clear, descriptive commit messages:

```
feat: add new diagnostic tool for connection issues
fix: resolve port conflict detection in Ubuntu systems
docs: update installation instructions for CentOS 8
style: improve error message formatting
```

## Getting Help

If you need help with contributing:

- Check existing documentation
- Search through issues and discussions
- Ask questions in the issues section
- Contact the maintainers

## Code of Conduct

This project is committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.
