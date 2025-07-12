#!/bin/bash
# Script to validate that required GitHub Actions secrets are set
# Usage: bash .github/scripts/validate-secrets.sh [release|debug]

set -e

BUILD_TYPE="${1:-debug}"

echo "=== Validating GitHub Actions Secrets for $BUILD_TYPE build ==="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any errors found
ERRORS=0
WARNINGS=0

# Function to check if secret is set
check_secret() {
    local secret_name=$1
    local required=$2
    local description=$3
    
    if [ -z "${!secret_name}" ]; then
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ ERROR: $secret_name is not set${NC}"
            echo "   Description: $description"
            echo
            ((ERRORS++))
        else
            echo -e "${YELLOW}⚠️  WARNING: $secret_name is not set (optional)${NC}"
            echo "   Description: $description"
            echo
            ((WARNINGS++))
        fi
    else
        echo -e "${GREEN}✅ $secret_name is set${NC}"
    fi
}

echo "Checking common secrets..."
echo "=========================="

# Common secrets (optional)
check_secret "GITHUB_TOKEN" "false" "GitHub token (usually automatic)"
check_secret "PYTHON_VERSION" "false" "Python version override"

if [ "$BUILD_TYPE" = "release" ]; then
    echo
    echo "Checking macOS release secrets..."
    echo "================================="
    
    # macOS release requirements
    check_secret "MACOS_CERTIFICATE_NAME" "true" "macOS code signing certificate name"
    check_secret "PROD_MACOS_NOTARIZATION_APPLE_ID" "true" "Apple ID for notarization"
    check_secret "PROD_MACOS_NOTARIZATION_TEAM_ID" "true" "Apple Developer Team ID"
    check_secret "PROD_MACOS_NOTARIZATION_PWD" "true" "App-specific password for notarization"
    
    echo
    echo "Checking Windows release secrets..."
    echo "==================================="
    
    # Windows release (optional)
    check_secret "WINDOWS_CERTIFICATE_NAME" "false" "Windows code signing certificate"
    check_secret "WINDOWS_CERTIFICATE_PFX_BASE64" "false" "Windows certificate PFX (base64)"
    check_secret "WINDOWS_CERTIFICATE_PASSWORD" "false" "Windows certificate password"
fi

echo
echo "Checking optional integration secrets..."
echo "========================================"

# Optional integrations
check_secret "GCS_SERVICE_ACCOUNT_KEY" "false" "Google Cloud Storage service account"
check_secret "GCS_BUCKET_NAME" "false" "GCS bucket for build artifacts"
check_secret "GCS_PROJECT_ID" "false" "GCP project ID"
check_secret "SLACK_WEBHOOK_URL" "false" "Slack webhook for notifications"
check_secret "SPARKLE_UPDATE_URL" "false" "Auto-update server URL"
check_secret "SPARKLE_SIGNING_KEY" "false" "Update signing key"

echo
echo "========================================"
echo "Summary:"
echo "========================================"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Found $ERRORS required secrets missing!${NC}"
    echo "Please set these secrets in your GitHub repository:"
    echo "Settings > Secrets and variables > Actions > New repository secret"
    exit 1
else
    echo -e "${GREEN}All required secrets are set!${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Found $WARNINGS optional secrets not set.${NC}"
    echo "These are not required but may enable additional features."
fi

echo
echo "For more information, see gh-action-example.env"