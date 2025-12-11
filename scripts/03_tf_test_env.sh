#!/bin/bash
# Terraform Infrastructure Testing Script
# Tests deployed Terraform infrastructure
# Usage: ./scripts/03_tf_test_env.sh [stg|prd]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
section() { echo -e "\n${CYAN}▶ $1${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/terraform"

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() { success "$1"; TESTS_PASSED=$((TESTS_PASSED+1)); }
test_fail() { error "$1"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Parse arguments
ENV="${1:-prd}"

# Normalize environment
case "$ENV" in
    staging|stg) ENV="stg"; ENV_NAME="Staging" ;;
    production|prd|prod) ENV="prd"; ENV_NAME="Production" ;;
    *) ENV="prd"; ENV_NAME="Production" ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Terraform Infrastructure Test"
echo "  Environment: $ENV_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
command -v terraform &>/dev/null || { error "Terraform not installed"; exit 1; }
command -v aws &>/dev/null || { error "AWS CLI not installed"; exit 1; }
command -v jq &>/dev/null || { error "jq not installed"; exit 1; }

# Verify AWS credentials
aws sts get-caller-identity --profile gc &>/dev/null || { error "AWS credentials not configured"; exit 1; }

# Check Terraform state
cd "$TF_DIR"

if ! terraform state list &>/dev/null; then
    error "No Terraform state found - infrastructure not deployed"
    exit 1
fi

section "Fetching Terraform Outputs"

# Get outputs
if [ "$ENV" = "stg" ]; then
    BUCKET_NAME=$(terraform output -raw staging_bucket_name 2>/dev/null || echo "")
    CF_ID=$(terraform output -raw staging_cloudfront_id 2>/dev/null || echo "")
    CF_DOMAIN=$(terraform output -raw staging_cloudfront_domain 2>/dev/null || echo "")
else
    BUCKET_NAME=$(terraform output -raw production_bucket_name 2>/dev/null || echo "")
    CF_ID=$(terraform output -raw production_cloudfront_id 2>/dev/null || echo "")
    CF_DOMAIN=$(terraform output -raw production_cloudfront_domain 2>/dev/null || echo "")
fi

if [ -z "$BUCKET_NAME" ] || [ -z "$CF_ID" ]; then
    error "Failed to retrieve Terraform outputs for $ENV_NAME"
    exit 1
fi

info "S3 Bucket: $BUCKET_NAME"
info "CloudFront ID: $CF_ID"
info "CloudFront Domain: $CF_DOMAIN"

section "Testing S3 Bucket"

# Test S3 bucket exists
if aws s3 ls "s3://$BUCKET_NAME" --profile gc &>/dev/null; then
    test_pass "S3 bucket exists and is accessible"
else
    test_fail "S3 bucket not accessible"
fi

# Check bucket configuration
BUCKET_WEBSITE=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --profile gc 2>/dev/null || echo "")
if [ -n "$BUCKET_WEBSITE" ]; then
    test_pass "S3 bucket website configuration enabled"
else
    test_fail "S3 bucket website configuration not found"
fi

# Check bucket versioning
VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --profile gc --query Status --output text 2>/dev/null || echo "")
if [ "$VERSIONING" = "Enabled" ]; then
    test_pass "S3 bucket versioning enabled"
else
    test_fail "S3 bucket versioning not enabled"
fi

# Check public access block
PUBLIC_ACCESS=$(aws s3api get-public-access-block --bucket "$BUCKET_NAME" --profile gc 2>/dev/null || echo "")
if [ -n "$PUBLIC_ACCESS" ]; then
    test_pass "S3 bucket public access block configured"
else
    warn "S3 bucket public access block not found"
fi

section "Testing CloudFront Distribution"

# Get CloudFront distribution details
CF_STATUS=$(aws cloudfront get-distribution --id "$CF_ID" --profile gc --query 'Distribution.Status' --output text 2>/dev/null || echo "")

if [ -n "$CF_STATUS" ]; then
    test_pass "CloudFront distribution exists"
    info "Status: $CF_STATUS"

    if [ "$CF_STATUS" = "Deployed" ]; then
        test_pass "CloudFront distribution is deployed"
    else
        warn "CloudFront distribution status: $CF_STATUS (not Deployed yet)"
    fi
else
    test_fail "CloudFront distribution not found"
fi

# Check CloudFront enabled
CF_ENABLED=$(aws cloudfront get-distribution --id "$CF_ID" --profile gc --query 'Distribution.DistributionConfig.Enabled' --output text 2>/dev/null || echo "")
if [ "$CF_ENABLED" = "True" ]; then
    test_pass "CloudFront distribution is enabled"
else
    test_fail "CloudFront distribution is not enabled"
fi

# Test CloudFront domain accessibility
section "Testing CloudFront Accessibility"

info "Testing: https://$CF_DOMAIN"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$CF_DOMAIN" --max-time 10 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    test_pass "CloudFront domain is accessible (HTTP $HTTP_STATUS)"
elif [ "$HTTP_STATUS" = "403" ]; then
    warn "CloudFront accessible but no content deployed yet (HTTP 403)"
    info "This is normal if you haven't deployed website files yet"
else
    test_fail "CloudFront domain not accessible (HTTP $HTTP_STATUS)"
fi

section "Checking Environment Configuration"

CONFIG_FILE="$ROOT_DIR/environments/$ENV/config.yaml"

if [ -f "$CONFIG_FILE" ]; then
    test_pass "Environment config file exists"

    # Check if values are synced
    if command -v yq &>/dev/null; then
        CONFIG_CF_ID=$(yq eval '.CLOUDFRONT_ID' "$CONFIG_FILE" 2>/dev/null || echo "")

        if [ "$CONFIG_CF_ID" = "$CF_ID" ]; then
            test_pass "CloudFront ID synced in config"
        else
            warn "CloudFront ID not synced in config"
            info "Run: ./scripts/tf_sync-outputs.sh"
        fi
    fi
else
    test_fail "Environment config file not found"
fi

# Summary
section "Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo "Environment: $ENV_NAME"
echo "Tests Run: $TOTAL_TESTS"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    success "All infrastructure tests passed!"
    echo ""
    info "Infrastructure is ready for deployment"
    info "Next steps:"
    echo "  1. Deploy website: ./scripts/deploy-env.sh $ENV"
    echo "  2. Test website: ./scripts/test-all.sh $ENV"
    echo ""
    exit 0
else
    error "Some infrastructure tests failed"
    echo ""
    info "Fix the issues above before proceeding"
    echo ""
    exit 1
fi
