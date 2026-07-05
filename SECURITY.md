# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow responsible disclosure practices.

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email security findings to: security@your-org.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix Timeline**: Based on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

### Security Practices in This Project

- All dependencies are regularly scanned for known vulnerabilities
- Static analysis runs on every pull request
- Container images are scanned before deployment
- Infrastructure code is validated against security benchmarks
- Secrets are never stored in source code
- All data in transit and at rest is encrypted

## Security Tools

- **Bandit** - Python SAST
- **Safety** - Dependency vulnerability scanning
- **Gitleaks** - Secret detection
- **Trivy** - Container vulnerability scanning
- **Checkov** - Infrastructure as Code security
- **Hadolint** - Dockerfile best practices
