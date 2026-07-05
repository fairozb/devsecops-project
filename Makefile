.PHONY: help install dev test lint security docker clean

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install production dependencies
	pip install --upgrade pip
	pip install -r requirements.txt

dev: ## Install all dependencies (including dev)
	pip install --upgrade pip
	pip install -r requirements.txt
	pip install -r requirements-dev.txt
	pre-commit install

test: ## Run tests with coverage
	pytest tests/ --cov=src --cov-report=term-missing --cov-report=html

lint: ## Run linters
	flake8 src/ tests/ --max-line-length=120
	black --check src/ tests/
	isort --check-only src/ tests/
	mypy src/

format: ## Format code
	black src/ tests/
	isort src/ tests/

security: ## Run all security scans
	@echo "=== Running Bandit (SAST) ==="
	bandit -r src/ -ll
	@echo ""
	@echo "=== Running Safety (SCA) ==="
	safety check -r requirements.txt
	@echo ""
	@echo "=== Running Gitleaks (Secret Detection) ==="
	gitleaks detect --source . --verbose

docker-build: ## Build Docker image
	docker build -t devsecops-app:latest -f docker/Dockerfile .

docker-scan: ## Scan Docker image for vulnerabilities
	trivy image devsecops-app:latest --severity HIGH,CRITICAL

docker-run: ## Run Docker container locally
	docker run -p 8000:8000 --rm --read-only --tmpfs /tmp devsecops-app:latest

run: ## Run application locally
	uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

clean: ## Remove generated files
	rm -rf __pycache__ .pytest_cache htmlcov .coverage
	rm -rf security/bandit-report.json security/safety-report.json
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
