#!/bin/bash
# Terraform Deployment Script
# Deploys or updates Terraform infrastructure
# Usage: ./scripts/02_tf_deploy_env.sh [plan|apply|destroy] [--auto-approve]

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
TF_DIR="$ROOT_DIR/terraform"

# Parse arguments
ACTION="${1:-plan}"
AUTO_APPROVE=false

if [[ "$2" == "--auto-approve" ]] || [[ "$1" == "--auto-approve" ]]; then
    AUTO_APPROVE=true
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    error "Invalid action: $ACTION. Use: plan, apply, or destroy"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Terraform Deployment"
echo "  Action: $ACTION"
if [ "$AUTO_APPROVE" = true ]; then
    echo "  Mode: Auto-approve"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
command -v terraform &>/dev/null || error "Terraform not installed"
command -v aws &>/dev/null || error "AWS CLI not installed"

# Verify AWS credentials
aws sts get-caller-identity --profile gc &>/dev/null || error "AWS credentials not configured for profile 'gc'"

ACCOUNT_ID=$(aws sts get-caller-identity --profile gc --query Account --output text)
info "AWS Account: $ACCOUNT_ID"

# Check Terraform directory
[ ! -d "$TF_DIR" ] && error "Terraform directory not found: $TF_DIR"

cd "$TF_DIR"

# Check initialization
if [ ! -d ".terraform" ]; then
    warn "Terraform not initialized"
    info "Initializing Terraform..."
    terraform init || error "Terraform initialization failed"
fi

# Check for terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    error "terraform.tfvars not found. Copy terraform.tfvars.example and configure values"
fi

echo ""

# Perform action
case "$ACTION" in
    plan)
        section "Running Terraform Plan"
        info "This will show what changes Terraform will make..."
        echo ""

        terraform plan -out=tfplan

        echo ""
        success "Terraform plan completed"
        info "Review the plan above"
        info "To apply: ./scripts/02_tf_deploy_env.sh apply"
        ;;

    apply)
        section "Applying Terraform Configuration"

        # Check if plan file exists
        if [ -f "tfplan" ]; then
            info "Using existing plan file..."
            warn "If this is old, cancel and run 'plan' first"
            echo ""

            if [ "$AUTO_APPROVE" = false ]; then
                read -p "Continue with this plan? (yes/no): " -r
                if [[ ! $REPLY =~ ^[Yy](es)?$ ]]; then
                    info "Cancelled"
                    exit 0
                fi
            fi

            terraform apply tfplan
            rm -f tfplan
        else
            warn "No plan file found, running apply directly..."
            echo ""

            if [ "$AUTO_APPROVE" = true ]; then
                terraform apply -auto-approve
            else
                terraform apply
            fi
        fi

        echo ""
        success "Terraform apply completed!"

        section "Infrastructure Summary"
        terraform output

        section "Next Steps"
        info "1. Sync Terraform outputs to environment configs:"
        echo "   ./scripts/tf_sync-outputs.sh"
        info "2. Test the infrastructure:"
        echo "   ./scripts/03_tf_test_env.sh [stg|prd]"
        ;;

    destroy)
        section "Destroying Terraform Infrastructure"

        warn "⚠️  WARNING: This will DESTROY all infrastructure!"
        warn "This includes S3 buckets, CloudFront distributions, and all data"
        echo ""

        if [ "$AUTO_APPROVE" = false ]; then
            read -p "Type 'destroy' to confirm: " -r
            if [[ "$REPLY" != "destroy" ]]; then
                info "Cancelled"
                exit 0
            fi

            read -p "Are you absolutely sure? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy](es)?$ ]]; then
                info "Cancelled"
                exit 0
            fi
        fi

        terraform destroy

        echo ""
        warn "Infrastructure destroyed"
        ;;
esac

echo ""
exit 0
