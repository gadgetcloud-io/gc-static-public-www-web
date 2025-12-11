#!/bin/bash
# Terraform Validation Script
# Validates Terraform configuration, checks prerequisites, and syntax
# Usage: ./scripts/01_tf_validate.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/terraform"

CHECKS_PASSED=0
CHECKS_FAILED=0

check_pass() { success "$1"; CHECKS_PASSED=$((CHECKS_PASSED+1)); }
check_fail() { error "$1"; CHECKS_FAILED=$((CHECKS_FAILED+1)); }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Terraform Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
info "Checking prerequisites..."
echo ""

if command -v terraform &>/dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    check_pass "Terraform installed (v${TERRAFORM_VERSION})"
else
    check_fail "Terraform not installed"
fi

if command -v aws &>/dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    check_pass "AWS CLI installed (v${AWS_VERSION})"
else
    check_fail "AWS CLI not installed"
fi

if command -v jq &>/dev/null; then
    check_pass "jq installed"
else
    check_fail "jq not installed"
fi

if command -v yq &>/dev/null; then
    check_pass "yq installed"
else
    check_fail "yq not installed"
fi

echo ""
info "Checking AWS credentials..."
echo ""

if aws sts get-caller-identity --profile gc &>/dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --profile gc --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --profile gc --query Arn --output text)
    check_pass "AWS credentials valid (Account: ${ACCOUNT_ID})"
    info "User: ${USER_ARN}"
else
    check_fail "AWS credentials not configured for profile 'gc'"
fi

echo ""
info "Checking Terraform directory..."
echo ""

if [ -d "$TF_DIR" ]; then
    check_pass "Terraform directory exists: $TF_DIR"
else
    check_fail "Terraform directory not found: $TF_DIR"
fi

# Check Terraform files
cd "$TF_DIR"

REQUIRED_FILES=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file not found"
    fi
done

echo ""
info "Checking Terraform initialization..."
echo ""

if [ -d ".terraform" ]; then
    check_pass "Terraform initialized (.terraform directory exists)"
else
    warn "Terraform not initialized - run 'terraform init'"
    info "Initializing Terraform..."
    if terraform init; then
        check_pass "Terraform initialization successful"
    else
        check_fail "Terraform initialization failed"
    fi
fi

echo ""
info "Validating Terraform configuration..."
echo ""

if terraform validate; then
    check_pass "Terraform configuration is valid"
else
    check_fail "Terraform configuration validation failed"
fi

echo ""
info "Checking for terraform.tfvars..."
echo ""

if [ -f "terraform.tfvars" ]; then
    check_pass "terraform.tfvars exists"

    # Check for required variables
    if grep -q "production_certificate_arn" terraform.tfvars && \
       grep -q "staging_certificate_arn" terraform.tfvars; then
        check_pass "Certificate ARNs configured"
    else
        warn "Certificate ARNs may not be configured in terraform.tfvars"
    fi
else
    warn "terraform.tfvars not found"
    info "Copy terraform.tfvars.example to terraform.tfvars and configure values"
fi

echo ""
info "Formatting check..."
echo ""

# Check if formatting is correct
if terraform fmt -check -recursive; then
    check_pass "Terraform files are properly formatted"
else
    warn "Some files need formatting - run 'terraform fmt -recursive'"
fi

echo ""
info "Checking Terraform state..."
echo ""

if terraform state list &>/dev/null; then
    RESOURCE_COUNT=$(terraform state list | wc -l | tr -d ' ')
    check_pass "Terraform state exists (${RESOURCE_COUNT} resources)"
else
    warn "No Terraform state found - infrastructure not deployed yet"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    success "All validation checks passed! (${CHECKS_PASSED} passed)"
    echo ""
    info "Ready to proceed with Terraform operations"
    info "Next step: ./scripts/02_tf_deploy_env.sh [stg|prd]"
    echo ""
    exit 0
else
    error "${CHECKS_FAILED} validation check(s) failed"
    echo ""
    exit 1
fi
