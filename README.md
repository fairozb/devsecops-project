# DevSecOps Project

A comprehensive DevSecOps pipeline demonstrating security-first practices integrated into every stage of the software development lifecycle.

## Overview

This project showcases how to embed security into CI/CD pipelines, leveraging automated scanning, infrastructure as code, and container security best practices.

## Architecture

```
+-------------------+     +-------------------+     +-------------------+
|   Code Commit     | --> |   CI Pipeline     | --> |   CD Pipeline     |
+-------------------+     +-------------------+     +-------------------+
        |                         |                         |
        v                         v                         v
+-------------------+     +-------------------+     +-------------------+
|  Secret Scanning  |     |  SAST / SCA /     |     |  Container Scan   |
|  Pre-commit Hooks |     |  License Check    |     |  IaC Validation   |
+-------------------+     +-------------------+     +-------------------+
```

## Project Structure

```
devsecops-project/
├── .github/workflows/      # CI/CD pipeline definitions
├── src/                    # Application source code
├── tests/                  # Unit and integration tests
├── security/               # Security scanning configurations
├── infrastructure/
│   └── terraform/          # Infrastructure as Code
├── docker/                 # Dockerfiles and container configs
├── docs/                   # Documentation
└── scripts/                # Utility scripts
```

## Security Tools Integrated

| Tool | Purpose | Stage |
|------|---------|-------|
| **Trivy** | Container & filesystem vulnerability scanning | CI |
| **Bandit** | Python SAST (Static Application Security Testing) | CI |
| **Safety** | Python dependency vulnerability checking (SCA) | CI |
| **Checkov** | Infrastructure as Code security scanning | CI |
| **Gitleaks** | Secret detection in source code | Pre-commit & CI |
| **Hadolint** | Dockerfile linting and best practices | CI |

## Getting Started

### Prerequisites

- Python 3.11+
- Docker
- Terraform (for IaC)
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/fairozb/devsecops-project.git
cd devsecops-project

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run the application
python src/main.py

# Run tests
pytest tests/
```

### Running Security Scans Locally

```bash
# Secret scanning
gitleaks detect --source . --verbose

# Python SAST
bandit -r src/ -f json -o security/bandit-report.json

# Dependency vulnerability check
safety check -r requirements.txt

# Dockerfile linting
hadolint docker/Dockerfile

# IaC scanning
checkov -d infrastructure/terraform/
```

## CI/CD Pipeline

The GitHub Actions pipeline runs the following stages:

1. **Lint & Format** - Code quality checks
2. **Unit Tests** - Automated testing with coverage
3. **SAST** - Static Application Security Testing (Bandit)
4. **SCA** - Software Composition Analysis (Safety)
5. **Secret Scan** - Detect leaked credentials (Gitleaks)
6. **Container Build & Scan** - Build image and scan with Trivy
7. **IaC Scan** - Validate Terraform with Checkov
8. **Deploy** - Deploy to staging/production (on main branch)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all security scans pass locally
4. Commit your changes (`git commit -m 'Add my feature'`)
5. Push to the branch (`git push origin feature/my-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
