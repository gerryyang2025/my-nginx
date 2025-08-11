# Security Policy

## Supported Versions

We actively maintain and provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 1. **DO NOT** create a public GitHub issue
Security vulnerabilities should not be disclosed publicly until they are resolved.

### 2. **DO** report privately
Send a detailed report to: [security@gerryyang.com](mailto:security@gerryyang.com)

### 3. Include in your report:
- **Description**: Clear description of the vulnerability
- **Impact**: Potential impact if exploited
- **Steps to reproduce**: Detailed steps to reproduce the issue
- **Affected versions**: Which versions are affected
- **Suggested fix**: If you have a solution in mind

### 4. What happens next:
- We will acknowledge receipt within 48 hours
- We will investigate and provide updates
- We will work on a fix and coordinate disclosure
- We will credit you in the security advisory (if desired)

## Security Best Practices

### For Users
- Always run scripts with minimal required privileges
- Keep your system and Nginx updated
- Use strong passwords and SSH keys
- Regularly backup your configurations
- Monitor logs for suspicious activity

### For Contributors
- Follow secure coding practices
- Validate all user inputs
- Use parameterized commands to prevent injection
- Test security implications of changes
- Document security considerations

## Security Features

This project includes several security measures:

- **Privilege escalation protection**: Scripts check for proper permissions
- **Input validation**: Configuration parameters are validated
- **Secure defaults**: Non-secure configurations are avoided
- **Error handling**: Sensitive information is not exposed in error messages
- **Backup procedures**: Original configurations are preserved

## Disclosure Policy

When a security vulnerability is confirmed:

1. **Immediate**: We will work on a fix
2. **Within 72 hours**: Security advisory will be published
3. **Patch release**: Fixed version will be released
4. **Documentation**: Security notes will be updated

## Responsible Disclosure

We appreciate security researchers who:
- Report vulnerabilities privately first
- Allow reasonable time for fixes
- Work with us to coordinate disclosure
- Follow responsible disclosure practices

## Contact

For security-related issues:
- **Email**: [security@gerryyang.com](mailto:security@gerryyang.com)
- **PGP Key**: Available upon request
- **Response Time**: Within 48 hours

Thank you for helping keep this project secure!
