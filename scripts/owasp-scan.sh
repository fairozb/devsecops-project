#!/bin/bash
# ==============================================================================
# OWASP Dependency Check Script
# Scans project dependencies for known vulnerabilities (CVEs)
# ==============================================================================

set -e

echo "======================================"
echo "  OWASP Dependency Check"
echo "======================================"
echo ""

# Run OWASP Dependency Check via Maven
mvn org.owasp:dependency-check-maven:check \
    -DfailBuildOnCVSS=7 \
    -Dformat=ALL \
    -DprettyPrint=true \
    -DsuppressionFile=security/owasp-suppressions.xml

echo ""
echo "======================================"
echo "  OWASP Scan Complete!"
echo "======================================"
echo "  Reports available at:"
echo "  - target/dependency-check-report.html"
echo "  - target/dependency-check-report.json"
echo "  - target/dependency-check-report.xml"
echo "======================================"

# Check if build should fail
if [ $? -ne 0 ]; then
    echo ""
    echo "CRITICAL: Vulnerabilities with CVSS >= 7 detected!"
    echo "Review the report and fix or suppress known false positives."
    exit 1
fi
