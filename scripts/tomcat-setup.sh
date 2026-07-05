#!/bin/bash
# ==============================================================================
# Tomcat Server Setup Script
# Installs and configures Apache Tomcat 9 for DevSecOps deployment
# Run on the target deployment server
# ==============================================================================

set -e

TOMCAT_VERSION="9.0.89"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"

echo "======================================"
echo "  Tomcat Server Setup"
echo "======================================"

# Install Java 17
echo "[1/6] Installing Java 17..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk curl wget

# Verify Java installation
java -version

# Create Tomcat user
echo "[2/6] Creating Tomcat user..."
sudo useradd -r -m -U -d ${TOMCAT_HOME} -s /bin/false ${TOMCAT_USER} 2>/dev/null || true

# Download and install Tomcat
echo "[3/6] Downloading Tomcat ${TOMCAT_VERSION}..."
cd /tmp
wget -q "https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
sudo tar xf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/
sudo mv /opt/apache-tomcat-${TOMCAT_VERSION}/* ${TOMCAT_HOME}/ 2>/dev/null || true
sudo rm -rf /opt/apache-tomcat-${TOMCAT_VERSION}
rm -f /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Configure Tomcat Manager
echo "[4/6] Configuring Tomcat Manager..."
sudo tee ${TOMCAT_HOME}/conf/tomcat-users.xml > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <role rolename="admin-gui"/>
    <user username="admin" password="admin" roles="manager-gui,manager-script,admin-gui"/>
</tomcat-users>
EOF

# Allow remote access to Manager (for Jenkins deployment)
sudo mkdir -p ${TOMCAT_HOME}/webapps/manager/META-INF/
sudo tee ${TOMCAT_HOME}/webapps/manager/META-INF/context.xml > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve"
           allow=".*" />
</Context>
EOF

# Set permissions
echo "[5/6] Setting permissions..."
sudo chown -R ${TOMCAT_USER}:${TOMCAT_USER} ${TOMCAT_HOME}
sudo chmod +x ${TOMCAT_HOME}/bin/*.sh

# Create systemd service
echo "[6/6] Creating systemd service..."
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=${TOMCAT_USER}
Group=${TOMCAT_USER}

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_PID=${TOMCAT_HOME}/temp/tomcat.pid"
Environment="CATALINA_HOME=${TOMCAT_HOME}"
Environment="CATALINA_BASE=${TOMCAT_HOME}"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Tomcat
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo ""
echo "======================================"
echo "  Tomcat Setup Complete!"
echo "======================================"
echo "  URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "  Manager: http://$(hostname -I | awk '{print $1}'):8080/manager"
echo "  Username: admin"
echo "  Password: admin"
echo "======================================"
