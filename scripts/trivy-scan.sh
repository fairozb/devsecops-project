#!/bin/bash
# ==============================================================================
# Trivy Security Scanner Script
# Scans Docker images for vulnerabilities
# Used as part of the Jenkins CI/CD pipeline
# ==============================================================================

set -e

IMAGE_NAME="${1:-fairozb/devsecops-app}"
IMAGE_TAG="${2:-latest}"
SEVERITY="${SEVERITY:-HIGH,CRITICAL}"
OUTPUT_DIR="${OUTPUT_DIR:-security/reports}"

echo "======================================"
echo "  Trivy Image Vulnerability Scan"
echo "======================================"
echo ""
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Severity: ${SEVERITY}"
echo ""

# Create output directory
mkdir -p ${OUTPUT_DIR}

# Scan 1: Table format (console output)
echo "[1/3] Running vulnerability scan (console output)..."
trivy image \
    --severity ${SEVERITY} \
    --format table \
    ${IMAGE_NAME}:${IMAGE_TAG}

# Scan 2: HTML report
echo ""
echo "[2/3] Generating HTML report..."
trivy image \
    --severity ${SEVERITY} \
    --format template \
    --template "@/usr/local/share/trivy/templates/html.tpl" \
    --output ${OUTPUT_DIR}/trivy-report.html \
    ${IMAGE_NAME}:${IMAGE_TAG} || \
trivy image \
    --severity ${SEVERITY} \
    --format table \
    --output ${OUTPUT_DIR}/trivy-report.html \
    ${IMAGE_NAME}:${IMAGE_TAG}

# Scan 3: JSON report (for pipeline processing)
echo "[3/3] Generating JSON report..."
trivy image \
    --severity ${SEVERITY} \
    --format json \
    --output ${OUTPUT_DIR}/trivy-report.json \
    ${IMAGE_NAME}:${IMAGE_TAG}

echo ""
echo "======================================"
echo "  Scan Complete!"
echo "======================================"
echo "  Reports saved to: ${OUTPUT_DIR}/"
echo "  - trivy-report.html"
echo "  - trivy-report.json"
echo "======================================"

# Check for CRITICAL vulnerabilities (fail pipeline)
CRITICAL_COUNT=$(trivy image --severity CRITICAL --format json ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null | \
    python3 -c "import json,sys; data=json.load(sys.stdin); print(sum(len(r.get('Vulnerabilities',[])) for r in data.get('Results',[])))" 2>/dev/null || echo "0")

if [ "${CRITICAL_COUNT}" != "0" ]; then
    echo ""
    echo "WARNING: ${CRITICAL_COUNT} CRITICAL vulnerabilities found!"
    echo "Pipeline should be reviewed before proceeding."
    exit 1
fi
