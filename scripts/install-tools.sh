#!/bin/bash
# ==============================================================================
# Install DevSecOps Tools on Jenkins Server
# Run this script on the Jenkins server to install required tools
# ==============================================================================

set -e

echo "======================================"
echo "  DevSecOps Tools Installation"
echo "======================================"

# 1. Install Java 17
echo "[1/7] Installing Java 17..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" | sudo tee -a /etc/environment

# 2. Install Maven
echo "[2/7] Installing Maven..."
sudo apt-get install -y maven
mvn --version

# 3. Install Docker
echo "[3/7] Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker jenkins

# 4. Install Trivy
echo "[4/7] Installing Trivy..."
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy
trivy --version

# 5. Install kubectl
echo "[5/7] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

# 6. Install SonarQube Scanner
echo "[6/7] Installing SonarQube Scanner..."
SONAR_VERSION="5.0.1.3006"
wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip"
sudo unzip -o sonar-scanner-cli-${SONAR_VERSION}-linux.zip -d /opt/
sudo ln -sf /opt/sonar-scanner-${SONAR_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
rm sonar-scanner-cli-${SONAR_VERSION}-linux.zip

# 7. Install OWASP Dependency Check
echo "[7/7] Installing OWASP Dependency Check..."
DC_VERSION="9.2.0"
wget -q "https://github.com/jeremylong/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip"
sudo unzip -o dependency-check-${DC_VERSION}-release.zip -d /opt/
sudo ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
rm dependency-check-${DC_VERSION}-release.zip

echo ""
echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "  Installed Tools:"
echo "  - Java 17"
echo "  - Maven"
echo "  - Docker"
echo "  - Trivy"
echo "  - kubectl"
echo "  - SonarQube Scanner"
echo "  - OWASP Dependency Check"
echo ""
echo "  NOTE: Restart Jenkins for Docker group changes to take effect:"
echo "  sudo systemctl restart jenkins"
echo "======================================"
