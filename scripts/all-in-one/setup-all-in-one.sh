#!/bin/bash
# ==============================================================================
# ALL-IN-ONE DevSecOps Server Setup
# ==============================================================================
# 
# This script installs EVERYTHING on a single EC2 instance:
# - Jenkins (port 8080)
# - SonarQube (port 9000)
# - Tomcat (port 8090)
# - Docker
# - Trivy
# - Maven
# - kubectl + Minikube (optional K8s)
#
# EC2 Requirements:
#   - Instance Type: t2.large (minimum) or t2.xlarge (recommended)
#   - AMI: Ubuntu 22.04 LTS
#   - Storage: 30-40 GB gp3
#   - Security Group Ports: 22, 8080, 8085, 8090, 9000
#
# Estimated Cost: ~$35-45/month (t2.large, stop when not in use)
#
# Usage:
#   chmod +x setup-all-in-one.sh
#   sudo ./setup-all-in-one.sh
#
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Track timing
START_TIME=$(date +%s)

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ALL-IN-ONE DevSecOps Server Setup                   ║"
echo "║                                                              ║"
echo "║  Jenkins + SonarQube + Tomcat + Docker + Trivy + Maven      ║"
echo "║  + kubectl + Minikube (All on one server!)                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# STEP 1: System Update & Prerequisites
# ============================================================
print_header "STEP 1/9: System Update & Prerequisites"

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    curl wget git unzip gnupg lsb-release \
    apt-transport-https ca-certificates \
    software-properties-common net-tools

print_success "System updated and prerequisites installed"

# ============================================================
# STEP 2: Install Java 17
# ============================================================
print_header "STEP 2/9: Installing Java 17 (JDK)"

sudo apt install -y openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" | sudo tee -a /etc/environment

print_success "Java 17 installed: $(java -version 2>&1 | head -1)"

# ============================================================
# STEP 3: Install Jenkins
# ============================================================
print_header "STEP 3/9: Installing Jenkins"

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

print_success "Jenkins installed (port 8080)"

# ============================================================
# STEP 4: Install Maven
# ============================================================
print_header "STEP 4/9: Installing Maven"

sudo apt install -y maven

print_success "Maven installed: $(mvn --version 2>&1 | head -1)"

# ============================================================
# STEP 5: Install Docker
# ============================================================
print_header "STEP 5/9: Installing Docker"

sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add jenkins and current user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

print_success "Docker installed: $(docker --version)"

# ============================================================
# STEP 6: Install Trivy
# ============================================================
print_header "STEP 6/9: Installing Trivy"

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

print_success "Trivy installed: $(trivy --version 2>&1 | head -1)"

# ============================================================
# STEP 7: Install SonarQube (Docker container)
# ============================================================
print_header "STEP 7/9: Installing SonarQube (Docker)"

# Increase virtual memory for SonarQube (Elasticsearch requirement)
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Run SonarQube
sudo docker run -d \
    --name sonarqube \
    --restart unless-stopped \
    -p 9000:9000 \
    -v sonarqube_data:/opt/sonarqube/data \
    -v sonarqube_logs:/opt/sonarqube/logs \
    -v sonarqube_extensions:/opt/sonarqube/extensions \
    sonarqube:lts-community

print_success "SonarQube installed (port 9000) - takes ~2 min to start"

# ============================================================
# STEP 8: Install Tomcat 9
# ============================================================
print_header "STEP 8/9: Installing Tomcat 9 (port 8090)"

# Download Tomcat
cd /opt
sudo wget -q https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89.tar.gz
sudo tar xzf apache-tomcat-9.0.89.tar.gz
sudo mv apache-tomcat-9.0.89 tomcat
sudo rm apache-tomcat-9.0.89.tar.gz

# Change Tomcat port to 8090 (since Jenkins is on 8080)
sudo sed -i 's/port="8080"/port="8090"/g' /opt/tomcat/conf/server.xml

# Configure Tomcat users
sudo tee /opt/tomcat/conf/tomcat-users.xml > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users>
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <role rolename="admin-gui"/>
    <user username="admin" password="admin123" roles="manager-gui,manager-script,admin-gui"/>
</tomcat-users>
EOF

# Allow remote access to Manager
sudo mkdir -p /opt/tomcat/webapps/manager/META-INF/
sudo tee /opt/tomcat/webapps/manager/META-INF/context.xml > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve"
           allow=".*" />
</Context>
EOF

sudo mkdir -p /opt/tomcat/webapps/host-manager/META-INF/
sudo cp /opt/tomcat/webapps/manager/META-INF/context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml

# Start Tomcat
sudo /opt/tomcat/bin/startup.sh

print_success "Tomcat 9 installed (port 8090)"

# ============================================================
# STEP 9: Install kubectl + Minikube
# ============================================================
print_header "STEP 9/9: Installing kubectl & Minikube"

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

print_success "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -1)"
print_success "Minikube installed: $(minikube version --short 2>/dev/null || echo 'installed')"

# ============================================================
# FINAL: Summary & Next Steps
# ============================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<YOUR-EC2-PUBLIC-IP>")
JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "<check after Jenkins starts>")

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              SETUP COMPLETE! (${DURATION}s)                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  SERVICE          URL                          PORT          ║"
echo "║  ───────          ───                          ────          ║"
echo "║  Jenkins          http://${PUBLIC_IP}:8080     8080          ║"
echo "║  SonarQube        http://${PUBLIC_IP}:9000     9000          ║"
echo "║  Tomcat           http://${PUBLIC_IP}:8090     8090          ║"
echo "║  App (Docker)     http://${PUBLIC_IP}:8085     8085          ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  CREDENTIALS                                                 ║"
echo "║  ───────────                                                 ║"
echo "║  Jenkins Password: ${JENKINS_PASSWORD}                       ║"
echo "║  SonarQube Login:  admin / admin                             ║"
echo "║  Tomcat Manager:   admin / admin123                          ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  NEXT STEPS                                                  ║"
echo "║  ──────────                                                  ║"
echo "║  1. Open Jenkins → Install suggested plugins                 ║"
echo "║  2. Install additional plugins (see README)                  ║"
echo "║  3. Configure tools (Maven, Docker, SonarQube)               ║"
echo "║  4. Add credentials (GitHub, Docker Hub, SonarQube)          ║"
echo "║  5. Create Pipeline job → point to Jenkinsfile               ║"
echo "║  6. Build Now!                                               ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}⚠  IMPORTANT: Restart Jenkins for Docker permissions:${NC}"
echo "   sudo systemctl restart jenkins"
echo ""
echo -e "${YELLOW}⚠  SonarQube takes ~2 minutes to start. Wait before accessing.${NC}"
echo ""
echo -e "${YELLOW}⚠  To start Minikube (for Kubernetes stage):${NC}"
echo "   sudo -u jenkins minikube start --driver=docker"
echo ""
