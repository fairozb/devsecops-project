# Complete CI/CD DevSecOps Project

A production-ready DevSecOps pipeline integrating **GitHub, Jenkins, Maven, SonarQube, OWASP, Docker, Trivy, Tomcat, Kubernetes, and Email Notifications**.

## Architecture & Pipeline Flow

```
┌──────────┐     ┌──────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│Developer │────>│  GitHub  │────>│   Jenkins    │────>│Maven Compile│────>│  Maven Test  │
└──────────┘     └──────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                                                                                    │
                    ┌───────────────────────────────────────────────────────────────┘
                    │
                    v
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐     ┌────────────────────┐
│SonarQube Analysis│───>│ Quality Gate │────>│ Maven Build │────>│OWASP Dependency Chk│
└─────────────────┘     └──────────────┘     └─────────────┘     └────────────────────┘
                                                                            │
                    ┌───────────────────────────────────────────────────────┘
                    │
                    v
┌──────────────────┐     ┌────────────┐     ┌────────────────┐     ┌───────────────────┐
│Docker Build & Push│───>│Trivy Scan  │────>│Deploy to Tomcat│────>│Deploy to Kubernetes│
└──────────────────┘     └────────────┘     └────────────────┘     └───────────────────┘
                                                                            │
                    ┌───────────────────────────────────────────────────────┘
                    │
                    v
              ┌──────────────────┐
              │Email Notification│
              │(Success/Failure) │
              └──────────────────┘
```

## Pipeline Stages

| # | Stage | Tool | Duration | Description |
|---|-------|------|----------|-------------|
| 1 | Clean Workspace | Jenkins | ~1s | Remove previous build artifacts |
| 2 | Checkout from Git | Git | ~1s | Clone source code from GitHub |
| 3 | Maven Compile | Maven | ~11s | Compile Java source code |
| 4 | Maven Test | Maven/JUnit | ~33s | Run unit & integration tests |
| 5 | SonarQube Analysis | SonarQube | ~18s | Static code analysis & quality metrics |
| 6 | Quality Gate | SonarQube | ~1s | Pass/fail based on quality standards |
| 7 | Maven Build | Maven | ~27s | Package application as WAR |
| 8 | OWASP Dependency Check | OWASP DC | ~35s | Scan dependencies for CVEs |
| 9 | Docker Build & Push | Docker | ~18s | Build container image & push to registry |
| 10 | Trivy Scan | Trivy | ~22s | Scan image for vulnerabilities |
| 11 | Deploy to Tomcat | Tomcat | ~7s | Deploy WAR to Tomcat server |
| 12 | Deploy to Container | Docker | ~4s | Run container locally |
| 13 | Deploy to Kubernetes | kubectl | ~7s | Deploy to K8s cluster |
| 14 | Email Notification | Jenkins | ~1s | Send success/failure email |

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Java 17** | Application runtime |
| **Spring Boot 3.2** | Web framework |
| **Maven** | Build & dependency management |
| **Jenkins** | CI/CD orchestration |
| **SonarQube** | Code quality & SAST |
| **OWASP Dependency Check** | Software Composition Analysis (SCA) |
| **Docker** | Containerization |
| **Trivy** | Container vulnerability scanning |
| **Tomcat 9** | Application server (WAR deployment) |
| **Kubernetes** | Container orchestration |
| **JaCoCo** | Code coverage |
| **JUnit 5** | Unit testing |

## Project Structure

```
devsecops-project/
├── Jenkinsfile                          # Declarative pipeline (14 stages)
├── pom.xml                              # Maven build with security plugins
├── sonar-project.properties             # SonarQube configuration
├── docker/
│   ├── Dockerfile                       # Multi-stage (Maven build + Tomcat deploy)
│   └── .dockerignore
├── kubernetes/
│   ├── namespace.yaml                   # K8s namespace
│   ├── deployment.yaml                  # App deployment (2 replicas, probes)
│   ├── service.yaml                     # LoadBalancer service
│   ├── secret.yaml                      # Database credentials
│   └── hpa.yaml                         # Horizontal Pod Autoscaler
├── security/
│   ├── owasp-suppressions.xml           # OWASP false positive suppressions
│   └── trivy-config.yaml               # Trivy scanner configuration
├── scripts/
│   ├── install-tools.sh                 # Jenkins server tool setup
│   ├── tomcat-setup.sh                  # Tomcat server configuration
│   ├── tomcat-deploy.sh                 # WAR deployment script
│   ├── owasp-scan.sh                    # OWASP scan runner
│   ├── trivy-scan.sh                    # Trivy scan runner
│   └── email-templates/
│       ├── pipeline-success.html        # Success notification
│       ├── pipeline-failure.html        # Failure notification
│       └── trivy-report-email.html      # Security scan report
├── src/
│   ├── main/java/com/devsecops/
│   │   ├── DevSecOpsApplication.java    # Spring Boot main class
│   │   ├── controller/
│   │   │   ├── HomeController.java      # Health & info endpoints
│   │   │   └── TaskController.java      # REST API (CRUD)
│   │   ├── model/Task.java              # JPA entity with validation
│   │   ├── service/TaskService.java     # Business logic
│   │   ├── repository/TaskRepository.java
│   │   ├── config/SecurityHeadersFilter.java
│   │   └── exception/
│   │       ├── GlobalExceptionHandler.java
│   │       └── ResourceNotFoundException.java
│   ├── main/resources/
│   │   ├── application.properties       # Dev configuration
│   │   └── application-prod.properties  # Production configuration
│   ├── main/webapp/WEB-INF/web.xml      # Servlet configuration
│   └── test/java/com/devsecops/        # Unit & integration tests
├── .gitignore
├── LICENSE
└── README.md
```

## Prerequisites

### Jenkins Server
- Java 17
- Maven 3.9+
- Docker
- Trivy
- kubectl
- SonarQube Scanner
- OWASP Dependency Check

Run the setup script:
```bash
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

### Jenkins Plugins Required
- Pipeline
- Git
- Maven Integration
- SonarQube Scanner
- OWASP Dependency-Check
- Docker Pipeline
- Kubernetes CLI
- Deploy to Container (Tomcat)
- Email Extension
- JaCoCo

### Jenkins Credentials
| Credential ID | Type | Description |
|--------------|------|-------------|
| `github-credentials` | Username/Password | GitHub access |
| `docker-hub-credentials` | Username/Password | Docker Hub login |
| `sonar-token` | Secret text | SonarQube auth token |
| `tomcat-credentials` | Username/Password | Tomcat Manager access |
| `kubeconfig` | Secret file | Kubernetes config |

## Getting Started

### 1. Clone Repository
```bash
git clone https://github.com/fairozb/devsecops-project.git
cd devsecops-project
```

### 2. Local Build & Test
```bash
# Compile
mvn clean compile

# Run tests
mvn test

# Package WAR
mvn clean package -DskipTests

# Run locally
mvn spring-boot:run
```

### 3. Access Application
- App: http://localhost:8080
- Health: http://localhost:8080/health
- API: http://localhost:8080/api/tasks
- H2 Console: http://localhost:8080/h2-console

### 4. Run Security Scans Locally
```bash
# OWASP Dependency Check
mvn org.owasp:dependency-check-maven:check

# SonarQube (requires running SonarQube server)
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000

# Docker build & Trivy scan
docker build -t devsecops-app -f docker/Dockerfile .
trivy image devsecops-app --severity HIGH,CRITICAL
```

### 5. Jenkins Pipeline Setup
1. Create a new Pipeline job in Jenkins
2. Select "Pipeline script from SCM"
3. Set SCM to Git with repository URL
4. Set script path to `Jenkinsfile`
5. Configure required credentials
6. Build!

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Application info |
| GET | `/health` | Health check |
| GET | `/api/tasks` | List all tasks |
| GET | `/api/tasks/{id}` | Get task by ID |
| POST | `/api/tasks` | Create new task |
| PUT | `/api/tasks/{id}` | Update task |
| DELETE | `/api/tasks/{id}` | Delete task |
| GET | `/api/tasks/status/{status}` | Filter by status |
| GET | `/api/tasks/search?keyword=` | Search tasks |

## Security Features

- **SAST**: SonarQube static analysis with quality gate enforcement
- **SCA**: OWASP Dependency Check scanning all Maven dependencies for CVEs
- **Container Security**: Trivy scanning Docker images for OS & library vulnerabilities
- **Security Headers**: X-Content-Type-Options, X-Frame-Options, HSTS, CSP
- **Input Validation**: Jakarta Bean Validation on all request bodies
- **Non-root Container**: Docker runs as unprivileged user
- **K8s Security**: Resource limits, read-only probes, secrets management
- **Secure Sessions**: HTTP-only, secure cookies in production

## Email Notifications

The pipeline sends HTML email notifications:
- **Success**: Green banner with all stages passed, security scan summary
- **Failure**: Red banner with failed stage, common causes, console link
- **Trivy Report**: Attached vulnerability scan results

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
