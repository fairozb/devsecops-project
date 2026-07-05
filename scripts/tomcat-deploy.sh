#!/bin/bash
# ==============================================================================
# Tomcat Deployment Script
# Deploys the WAR file to a remote Tomcat server
# ==============================================================================

set -e

# Configuration
TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat}"
TOMCAT_USER="${TOMCAT_USER:-admin}"
TOMCAT_PASSWORD="${TOMCAT_PASSWORD:-admin}"
TOMCAT_URL="${TOMCAT_URL:-http://localhost:8080}"
WAR_FILE="${WAR_FILE:-target/devsecops-app.war}"
APP_CONTEXT="${APP_CONTEXT:-devsecops-app}"

echo "======================================"
echo "  DevSecOps - Tomcat Deployment"
echo "======================================"
echo ""
echo "Tomcat URL: ${TOMCAT_URL}"
echo "WAR File: ${WAR_FILE}"
echo "Context: ${APP_CONTEXT}"
echo ""

# Check if WAR file exists
if [ ! -f "${WAR_FILE}" ]; then
    echo "ERROR: WAR file not found at ${WAR_FILE}"
    echo "Run 'mvn clean package' first."
    exit 1
fi

# Method 1: Deploy using curl (Tomcat Manager API)
echo "[1/3] Undeploying existing application..."
curl -s -u "${TOMCAT_USER}:${TOMCAT_PASSWORD}" \
    "${TOMCAT_URL}/manager/text/undeploy?path=/${APP_CONTEXT}" || true

echo "[2/3] Deploying new WAR file..."
curl -s -u "${TOMCAT_USER}:${TOMCAT_PASSWORD}" \
    -T "${WAR_FILE}" \
    "${TOMCAT_URL}/manager/text/deploy?path=/${APP_CONTEXT}&update=true"

echo "[3/3] Verifying deployment..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${TOMCAT_URL}/${APP_CONTEXT}/health")

if [ "$RESPONSE" = "200" ]; then
    echo ""
    echo "SUCCESS: Application deployed and responding at ${TOMCAT_URL}/${APP_CONTEXT}"
    echo ""
else
    echo ""
    echo "WARNING: Application deployed but health check returned HTTP ${RESPONSE}"
    echo "Check Tomcat logs for details."
    echo ""
fi
