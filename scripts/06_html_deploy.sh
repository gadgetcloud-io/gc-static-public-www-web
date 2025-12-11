#!/bin/bash
# HTML Deployment Script
# Deploys website content to S3 and invalidates CloudFront
# Usage: ./scripts/06_html_deploy.sh [stg|prd] [--skip-tests]

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
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}▶ $1${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT_DIR/src"

# Parse arguments
ENV="${1:-prd}"
SKIP_TESTS=false

if [[ "$2" == "--skip-tests" ]] || [[ "$1" == "--skip-tests" ]]; then
    SKIP_TESTS=true
fi

# Normalize environment
case "$ENV" in
    staging|stg) ENV="stg"; ENV_NAME="Staging" ;;
    production|prd|prod) ENV="prd"; ENV_NAME="Production" ;;
    *) ENV="prd"; ENV_NAME="Production" ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Website Deployment"
echo "  Environment: $ENV_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
section "Checking Prerequisites"

command -v aws &>/dev/null || error "AWS CLI not installed"
command -v yq &>/dev/null || error "yq not installed"

CONFIG_FILE="$ROOT_DIR/environments/$ENV/config.yaml"
[ -f "$CONFIG_FILE" ] || error "Config file not found: $CONFIG_FILE"

[ -d "$SRC_DIR" ] || error "Source directory not found: $SRC_DIR"

success "All prerequisites met"

# Read configuration
section "Reading Configuration"

AWS_PROFILE=$(yq eval '.AWS_PROFILE' "$CONFIG_FILE")
AWS_REGION=$(yq eval '.AWS_REGION' "$CONFIG_FILE")
S3_BUCKET=$(yq eval '.S3_BUCKET' "$CONFIG_FILE")
CLOUDFRONT_ID=$(yq eval '.CLOUDFRONT_ID' "$CONFIG_FILE")
HOSTNAME=$(yq eval '.hostName' "$CONFIG_FILE")
CACHE_HTML=$(yq eval '.CACHE_HTML_SECONDS' "$CONFIG_FILE")
CACHE_ASSETS=$(yq eval '.CACHE_ASSETS_SECONDS' "$CONFIG_FILE")

info "AWS Profile: $AWS_PROFILE"
info "AWS Region: $AWS_REGION"
info "S3 Bucket: $S3_BUCKET"
info "CloudFront ID: $CLOUDFRONT_ID"
info "Hostname: $HOSTNAME"
info "HTML Cache: ${CACHE_HTML}s"
info "Assets Cache: ${CACHE_ASSETS}s"

# Verify AWS credentials
aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null || error "AWS credentials not valid for profile: $AWS_PROFILE"
success "AWS credentials validated"

# Check if bucket exists
aws s3 ls "s3://$S3_BUCKET" --profile "$AWS_PROFILE" &>/dev/null || error "S3 bucket not accessible: $S3_BUCKET"
success "S3 bucket accessible"

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ]; then
    section "Running HTML Tests"

    if [ -x "$SCRIPT_DIR/05_html_test.sh" ]; then
        "$SCRIPT_DIR/05_html_test.sh" || {
            warn "HTML tests failed"
            read -p "Continue with deployment anyway? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy](es)?$ ]]; then
                info "Deployment cancelled"
                exit 0
            fi
        }
    else
        warn "HTML test script not found or not executable"
    fi
else
    info "Skipping HTML tests (--skip-tests flag)"
fi

# Deployment confirmation for production
if [ "$ENV" = "prd" ]; then
    section "Production Deployment Confirmation"

    warn "You are about to deploy to PRODUCTION"
    echo ""
    echo "Target: $HOSTNAME"
    echo "Bucket: $S3_BUCKET"
    echo ""

    read -p "Type 'deploy' to confirm: " -r
    if [[ "$REPLY" != "deploy" ]]; then
        info "Deployment cancelled"
        exit 0
    fi
fi

# Sync assets (CSS, JS, images) with long cache
section "Deploying Assets (CSS, JS, Images)"

info "Uploading with ${CACHE_ASSETS}s cache..."

aws s3 sync "$SRC_DIR/" "s3://$S3_BUCKET/" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --cache-control "max-age=$CACHE_ASSETS" \
    --exclude "*.html" \
    --delete

success "Assets deployed"

# Count uploaded files
CSS_COUNT=$(find "$SRC_DIR" -name "*.css" | wc -l | tr -d ' ')
JS_COUNT=$(find "$SRC_DIR" -name "*.js" | wc -l | tr -d ' ')
IMAGE_COUNT=$(find "$SRC_DIR/images" -type f 2>/dev/null | wc -l | tr -d ' ')

info "Uploaded: $CSS_COUNT CSS, $JS_COUNT JS, $IMAGE_COUNT images"

# Sync HTML files with short cache
section "Deploying HTML Files"

info "Uploading with ${CACHE_HTML}s cache..."

aws s3 sync "$SRC_DIR/" "s3://$S3_BUCKET/" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --cache-control "max-age=$CACHE_HTML" \
    --exclude "*" \
    --include "*.html" \
    --delete

success "HTML files deployed"

# Count HTML files
HTML_COUNT=$(find "$SRC_DIR" -maxdepth 1 -name "*.html" | wc -l | tr -d ' ')
info "Uploaded: $HTML_COUNT HTML files"

# Create CloudFront invalidation
section "Invalidating CloudFront Cache"

info "Creating invalidation for all files..."

INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_ID" \
    --paths "/*" \
    --profile "$AWS_PROFILE" \
    --query 'Invalidation.Id' \
    --output text)

success "Invalidation created: $INVALIDATION_ID"

info "Invalidation typically takes 10-15 minutes to complete"

# Check invalidation status
INVALIDATION_STATUS=$(aws cloudfront get-invalidation \
    --distribution-id "$CLOUDFRONT_ID" \
    --id "$INVALIDATION_ID" \
    --profile "$AWS_PROFILE" \
    --query 'Invalidation.Status' \
    --output text)

info "Status: $INVALIDATION_STATUS"

# Get CloudFront domain
CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$CLOUDFRONT_ID" \
    --profile "$AWS_PROFILE" \
    --query 'Distribution.DomainName' \
    --output text)

# Deployment summary
section "Deployment Summary"

echo "Environment: $ENV_NAME"
echo "S3 Bucket: $S3_BUCKET"
echo "CloudFront: $CLOUDFRONT_ID"
echo "Domain: $HOSTNAME"
echo "CloudFront Domain: $CF_DOMAIN"
echo ""
echo "Files Deployed:"
echo "  - HTML: $HTML_COUNT files (${CACHE_HTML}s cache)"
echo "  - CSS: $CSS_COUNT files (${CACHE_ASSETS}s cache)"
echo "  - JS: $JS_COUNT files (${CACHE_ASSETS}s cache)"
echo "  - Images: $IMAGE_COUNT files (${CACHE_ASSETS}s cache)"
echo ""
echo "Invalidation: $INVALIDATION_ID ($INVALIDATION_STATUS)"
echo ""

success "Deployment completed successfully!"

section "Next Steps"

info "1. Wait for CloudFront invalidation to complete (~10-15 minutes)"
echo "   Check status: aws cloudfront get-invalidation --distribution-id $CLOUDFRONT_ID --id $INVALIDATION_ID --profile $AWS_PROFILE"

info "2. Test the website:"
echo "   https://$HOSTNAME"
echo "   https://$CF_DOMAIN"

info "3. Verify deployment:"
echo "   curl -I https://$HOSTNAME"

if [ "$ENV" = "stg" ]; then
    info "4. After staging validation, deploy to production:"
    echo "   ./scripts/06_html_deploy.sh prd"
fi

echo ""
exit 0
