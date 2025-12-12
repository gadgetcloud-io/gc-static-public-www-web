# GadgetCloud Static Website

**www.gadgetcloud.io** - A static marketing website for GadgetCloud's gadget inventory and management platform.

📘 **[CI/CD Pipeline Documentation](CICD.md)** - Complete deployment workflows, testing strategies, and GitHub Actions integration.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Development](#development)
- [Deployment](#deployment)
- [Testing](#testing)
- [Configuration](#configuration)
- [Scripts](#scripts)
- [Infrastructure](#infrastructure)
- [Troubleshooting](#troubleshooting)

## Overview

Pure static HTML/CSS/JavaScript website deployed to AWS (S3 + CloudFront) with environment-specific configurations for staging and production.

### Key Features

- **Pure Static**: No build step, no frameworks - works directly in browsers
- **AWS Deployment**: S3 hosting with CloudFront CDN
- **Security**: CSP headers, HTTPS-only, secure form submission
- **Responsive**: Mobile-first design with hamburger navigation
- **Contact Form**: Integrated with REST API backend, displays submission ID confirmation
- **Environment-Aware**: Separate staging and production configurations
- **Infrastructure as Code**: Terraform for AWS resources

## Architecture

```
Browser  →  CloudFront  →  S3 Bucket
              (CDN)         (Static)

    Form Submit
        ↓
   REST API
   Backend
```

### Technology Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Hosting**: AWS S3 (static website hosting) - ap-south-1
- **CDN**: AWS CloudFront (global)
- **SSL**: ACM Certificates (us-east-1, required for CloudFront)
- **IaC**: Terraform
- **Deployment**: Bash scripts
- **Testing**: Playwright (E2E)
- **Config Management**: YAML (yq)

## Prerequisites

### Required Tools

```bash
# Terraform
terraform --version  # Required for infrastructure
brew install terraform  # macOS

# AWS CLI
aws --version  # Required for deployment
brew install awscli  # macOS

# yq - YAML processor
yq --version   # Required for config parsing
brew install yq  # macOS

# jq - JSON processor
jq --version   # Required for JSON parsing
brew install jq  # macOS

# Node.js & npm (for testing only)
node --version   # Optional, for Playwright tests
npm --version
```

### AWS Credentials

Configure AWS CLI with the "gc" profile:

```bash
aws configure --profile gc
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: ap-south-1
```

## Quick Start

### 1. Clone Repository

```bash
git clone <repository-url>
cd gc-static-www-web
```

### 2. Review Configuration

```bash
# Review Terraform variables for both environments
cat environments/stg/terraform.tfvars
cat environments/prd/terraform.tfvars

# Review environment configurations
cat environments/stg/config.yaml
cat environments/prd/config.yaml
```

### 3. Deploy Infrastructure (First Time)

```bash
# Validate Terraform configuration
./scripts/01_tf_validate.sh

# Plan infrastructure changes
./scripts/02_tf_deploy_env.sh plan

# Review the plan, then apply
./scripts/02_tf_deploy_env.sh apply

# Test deployed infrastructure
./scripts/03_tf_test_env.sh stg    # Test staging
./scripts/03_tf_test_env.sh prd    # Test production
```

### 4. Validate and Deploy Website Content

After infrastructure is deployed:

```bash
# Validate manifest and HTML files
./scripts/04_html_apply_manifest.sh

# Apply version and build info to HTML footers
./scripts/04_html_apply_manifest.sh --apply

# Run HTML validation tests
./scripts/05_html_test.sh

# Deploy to staging
./scripts/06_html_deploy.sh stg

# Run E2E tests against staging
./scripts/07_html_playwright_tests.sh stg

# Deploy to production (after staging validation)
./scripts/06_html_deploy.sh prd
```

## Project Structure

```
.
├── src/                          # Static website files
│   ├── *.html                   # Page templates
│   ├── css/styles.css           # All styles
│   ├── js/main.js               # Navigation, form handling
│   └── images/                  # SVG assets
│       ├── logos/               # Brand logos
│       └── illustrations/       # Page illustrations
├── scripts/                      # Deployment & testing scripts
│   ├── 01_tf_validate.sh        # Terraform validation
│   ├── 02_tf_deploy_env.sh      # Terraform deployment
│   ├── 03_tf_test_env.sh        # Infrastructure testing
│   ├── 04_html_apply_manifest.sh # Manifest validation & version injection
│   ├── 05_html_test.sh          # HTML validation tests
│   ├── 06_html_deploy.sh        # Website deployment to S3/CloudFront
│   └── 07_html_playwright_tests.sh # Playwright E2E test runner
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Provider configuration
│   ├── s3.tf                    # S3 buckets
│   ├── cloudfront.tf            # CloudFront distributions
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   └── README.md                # Terraform documentation
├── environments/                 # Environment configurations
│   ├── stg/
│   │   ├── config.yaml          # Staging config
│   │   ├── terraform.tfvars     # Staging Terraform vars
│   │   └── backend.tfvars       # Staging backend config
│   └── prd/
│       ├── config.yaml          # Production config
│       ├── terraform.tfvars     # Production Terraform vars
│       └── backend.tfvars       # Production backend config
├── tests/                        # E2E tests
│   ├── pages.spec.ts            # Page loading tests
│   ├── navigation.spec.ts       # Navigation tests
│   └── contact-form.spec.ts     # Form submission tests
├── manifest.yaml                 # Site metadata (source of truth)
├── VERSION                       # Semantic version number
├── CLAUDE.md                     # AI assistant instructions
└── README.md                     # This file
```

## Development

### Local Development

Since this is a pure static site, you can:

1. **Open directly in browser**:
   ```bash
   open src/index.html
   ```

2. **Use a local server** (recommended):
   ```bash
   # Python 3
   cd src && python3 -m http.server 8000

   # Node.js
   npx http-server src -p 8000
   ```

3. **Access at**: http://localhost:8000

### Making Changes

1. **Edit HTML/CSS/JS** in `src/` directory
2. **Update manifest.yaml** for site metadata
3. **Test locally** using a local server
4. **Deploy to staging** for testing
5. **Deploy to production** after validation

### CSS Architecture

- **Variables**: CSS custom properties for theming
- **Mobile-first**: Responsive design with media queries
- **Animations**: fadeInUp, slideInRight, float, shimmer, pulse-glow
- **Utility classes**: `.btn-*`, `.card-*`, `.container`

### JavaScript Features

- **Navigation**: Mobile hamburger menu with smooth scrolling
- **Form Handling**: Rate limiting, source tracking, API submission
- **Error Handling**: Comprehensive try-catch blocks
- **Security**: Honeypot field, CSP compliance

## Deployment

### Infrastructure Deployment

```bash
# Validate Terraform configuration
./scripts/01_tf_validate.sh

# Plan changes (always run first)
./scripts/02_tf_deploy_env.sh plan

# Apply changes
./scripts/02_tf_deploy_env.sh apply

# Or apply with auto-approve (use with caution)
./scripts/02_tf_deploy_env.sh apply --auto-approve

# Test infrastructure
./scripts/03_tf_test_env.sh stg
./scripts/03_tf_test_env.sh prd
```

### Content Deployment

After infrastructure is ready:

```bash
# Sync all files with 1-year cache
aws s3 sync src/ s3://<bucket-name>/ --profile gc --cache-control max-age=31536000

# Override HTML files with 5-minute cache
aws s3 cp src/ s3://<bucket-name>/ --recursive --exclude "*" --include "*.html" --cache-control max-age=300 --profile gc

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id <cloudfront-id> --paths "/*" --profile gc
```

### Cache Strategy

| File Type | Cache Duration | Reason |
|-----------|---------------|---------|
| HTML files | 5 minutes (300s) | Quick content updates |
| CSS/JS/Images | 1 year (31536000s) | Maximum performance |

### CloudFront Invalidation

- Automatic invalidation needed after content updates
- Path: `/*` (all files)
- Typical completion time: 10-15 minutes
- Check status: `aws cloudfront get-invalidation --id <ID> --distribution-id <DIST_ID> --profile gc`

## Testing

### Infrastructure Tests

```bash
# Test staging infrastructure
./scripts/03_tf_test_env.sh stg

# Test production infrastructure
./scripts/03_tf_test_env.sh prd
```

Tests performed:
- S3 bucket accessibility
- Bucket versioning enabled
- Bucket website configuration
- Public access block configured
- CloudFront distribution status
- CloudFront domain accessibility
- Environment config synchronization

### E2E Tests (Playwright)

```bash
# Run all tests
npx playwright test

# Run with browser visible
npx playwright test --headed

# Run specific test file
npx playwright test contact-form

# Run in UI mode
npx playwright test --ui
```

## Configuration

### manifest.yaml (Source of Truth)

Central configuration for site-wide settings:

```yaml
site_title: GadgetCloud
header: "Your Gadgets, Your Cloud."
footer: "© 2025 GadgetCloud. All rights reserved."

menu_items:
  - text: Home
    link: index.html
    title: Home - GadgetCloud
    description: "Welcome to GadgetCloud..."

social_links:
  - platform: Twitter
    url: "https://twitter.com/gadgetcloud"
```

### Environment Configs

**environments/stg/config.yaml**:
```yaml
hostName: stg.gadgetcloud.io
path: /
AWS_PROFILE: gc
AWS_REGION: ap-south-1
S3_BUCKET: stg.gadgetcloud.io
CLOUDFRONT_ID: PENDING_TERRAFORM_APPLY
CACHE_HTML_SECONDS: 300
CACHE_ASSETS_SECONDS: 31536000
```

**environments/prd/config.yaml**:
```yaml
hostName: www.gadgetcloud.io
path: /
AWS_PROFILE: gc
AWS_REGION: ap-south-1
S3_BUCKET: www.gadgetcloud.io
CLOUDFRONT_ID: PENDING_TERRAFORM_APPLY
CACHE_HTML_SECONDS: 300
CACHE_ASSETS_SECONDS: 31536000
```

### Terraform Variables

**environments/{stg,prd}/terraform.tfvars**:
```hcl
aws_profile = "gc"
environment = "stg"  # or "prd"
domain_name = "gadgetcloud.io"
bucket_name = "stg.gadgetcloud.io"  # or "www.gadgetcloud.io"
cloudfront_certificate_arn = "arn:aws:acm:us-east-1:..."
```

## Scripts

All scripts use `yq` for YAML parsing and `jq` for JSON parsing. They support both `stg` and `prd` environments.

### Infrastructure Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `01_tf_validate.sh` | Validate Terraform config | `./scripts/01_tf_validate.sh` |
| `02_tf_deploy_env.sh` | Deploy/update infrastructure | `./scripts/02_tf_deploy_env.sh [plan\|apply\|destroy]` |
| `03_tf_test_env.sh` | Test deployed infrastructure | `./scripts/03_tf_test_env.sh [stg\|prd]` |

### HTML Deployment Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `04_html_apply_manifest.sh` | Validate HTML against manifest, apply version info | `./scripts/04_html_apply_manifest.sh [--apply]` |
| `05_html_test.sh` | Comprehensive HTML validation tests | `./scripts/05_html_test.sh` |
| `06_html_deploy.sh` | Deploy website to S3/CloudFront | `./scripts/06_html_deploy.sh [stg\|prd] [--skip-tests]` |
| `07_html_playwright_tests.sh` | Run Playwright E2E tests | `./scripts/07_html_playwright_tests.sh [stg\|prd] [--headed\|--debug\|--ui]` |

### Script Details

**01_tf_validate.sh**:
- Checks prerequisites (terraform, aws, jq, yq)
- Validates AWS credentials
- Checks Terraform configuration files
- Verifies terraform.tfvars
- Validates Terraform syntax

**02_tf_deploy_env.sh**:
- Supports: `plan`, `apply`, `destroy`
- Optional `--auto-approve` flag
- Safety confirmations for destructive operations
- Shows infrastructure summary after apply

**03_tf_test_env.sh**:
- Tests S3 bucket configuration
- Validates CloudFront distribution
- Checks bucket versioning
- Tests accessibility
- Verifies config synchronization

**04_html_apply_manifest.sh**:
- Validates HTML files against manifest.yaml
- Checks meta descriptions, titles, social links
- Tests navigation consistency
- Applies version and build information to HTML footers (with `--apply`)
- Generates version string: `v{VERSION} | Build {TIMESTAMP} | {GIT_COMMIT}`

**05_html_test.sh**:
- Tests HTML structure (DOCTYPE, tags, meta)
- Validates CSS/JS references
- Checks navigation links
- Tests contact form fields
- Verifies CSP compliance
- Checks security headers
- 103 comprehensive validation tests

**06_html_deploy.sh**:
- Deploys website content to S3
- Applies proper cache headers (HTML: 5min, Assets: 1yr)
- Creates CloudFront invalidation
- Runs HTML tests before deployment (optional with `--skip-tests`)
- Production deployment requires confirmation

**07_html_playwright_tests.sh**:
- Runs Playwright E2E tests against deployed environments
- Supports multiple modes: `--headed`, `--debug`, `--ui`
- Checks site accessibility before running tests
- Automatic dependency installation
- Generates HTML test reports

## Infrastructure

### AWS Resources (Terraform)

#### Staging (stg)
- **S3 Bucket**: `stg.gadgetcloud.io` (ap-south-1)
- **CloudFront Distribution**: `EOIMARPNX4A3E` (Global CDN)
- **CloudFront Domain**: dbmr65efdpyk8.cloudfront.net
- **Domain**: stg.gadgetcloud.io
- **Route53**: A record (alias to CloudFront)
- **ACM Certificate**: us-east-1 (CloudFront requirement)

#### Production (prd)
- **S3 Bucket**: `www.gadgetcloud.io` (ap-south-1)
- **CloudFront Distribution**: `E1ISO98SXE9Q6G` (Global CDN)
- **CloudFront Domain**: d1qxi81dkpyib0.cloudfront.net
- **Domain**: www.gadgetcloud.io
- **Route53**: A record (alias to CloudFront)
- **ACM Certificate**: us-east-1 (CloudFront requirement)

#### Apex Domain Redirect
- **S3 Bucket**: `apex.gadgetcloud.io` (redirect only)
- **CloudFront Distribution**: `E3DFNUCXAGBHT7` (Global CDN)
- **CloudFront Domain**: d3jnwu5d123hec.cloudfront.net
- **Domain**: gadgetcloud.io
- **Route53**: A record (alias to CloudFront)
- **Redirect Target**: www.gadgetcloud.io (HTTPS)
- **Purpose**: Redirects apex domain to www subdomain

### Terraform Workflow

```bash
cd terraform

# Initialize (first time)
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output

# Destroy (careful!)
terraform destroy
```

### Important Notes

- **S3 Buckets**: Created in ap-south-1
- **CloudFront**: Global distribution (edge locations worldwide)
- **ACM Certificates**: Must be in us-east-1 (CloudFront requirement)
- **Versioning**: Enabled on all S3 buckets
- **Public Access**: Blocked (CloudFront-only access via OAC)
- **Security Headers**: CSP, HSTS, X-Frame-Options configured

## Security

### Security Audit Status

**Last Audit**: 2025-12-11
**Security Score**: 98/100
**Status**: ✅ Production Ready - No Critical Vulnerabilities

### Security Features

**Web Application Security:**
- ✅ Content Security Policy (CSP) headers
- ✅ X-Frame-Options: DENY (clickjacking protection)
- ✅ X-Content-Type-Options: nosniff
- ✅ HTTPS-only (redirect-to-https)
- ✅ Modern TLS 1.2+ (TLSv1.2_2021)
- ✅ No inline scripts or styles (CSP compliant)
- ✅ XSS prevention (safe DOM manipulation)
- ✅ Honeypot field for spam protection

**Infrastructure Security:**
- ✅ S3 buckets: All public access blocked
- ✅ S3 access: CloudFront-only via Origin Access Control (OAC)
- ✅ Bucket versioning: Enabled for rollback capability
- ✅ IAM-based authentication for deployments
- ✅ No hardcoded credentials in code or configs
- ✅ Profile-based AWS CLI authentication only

**Application Security:**
- ✅ Client-side rate limiting (10 submissions/hour)
- ✅ Server-side rate limiting at API
- ✅ Input validation (HTML5 + server-side)
- ✅ Form data sanitization (.trim())
- ✅ No eval() or dangerous JavaScript patterns
- ✅ Safe localStorage usage (timestamps only)

**Deployment Security:**
- ✅ Production deployments require manual confirmation
- ✅ Staging validation before production
- ✅ Terraform state stored securely
- ✅ No secrets in version control
- ✅ Automated validation tests

### Security Headers

All HTML pages include:
```html
Content-Security-Policy: default-src 'self';
  script-src 'self';
  style-src 'self' https://fonts.googleapis.com;
  connect-src 'self' https://rest.gadgetcloud.io;
  frame-ancestors 'none';

X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

### Optional Security Enhancements

**For Production Consideration:**
1. **CloudFront Logging**: Enable access logs to S3 bucket
2. **AWS WAF**: Add Web Application Firewall for DDoS protection
3. **S3 Encryption**: Explicit SSE-S3 or SSE-KMS configuration
4. **Subresource Integrity**: Add SRI hashes for external fonts

## Troubleshooting

### Common Issues

**"Terraform not initialized"**:
```bash
cd terraform
terraform init
```

**"yq not installed"**:
```bash
brew install yq  # macOS
# OR download from https://github.com/mikefarah/yq
```

**"AWS credentials not configured"**:
```bash
aws configure --profile gc
```

**"CloudFront ID not configured"**:
```bash
# Run Terraform first to create infrastructure
./scripts/02_tf_deploy_env.sh apply

# Then test to verify CLOUDFRONT_ID is populated
./scripts/03_tf_test_env.sh stg
```

**"Terraform state not found"**:
```bash
# You need to run Terraform apply first
./scripts/02_tf_deploy_env.sh plan
./scripts/02_tf_deploy_env.sh apply
```

**Form submission failing**:
- Check API endpoint is accessible: `https://rest.gadgetcloud.io/forms`
- Verify rate limiting (10/hour localStorage limit)
- Check browser console for errors
- Test mode: add `isTest: true` to prevent email sending

**CloudFront not updating**:
- Invalidation takes 10-15 minutes
- Check invalidation status in AWS Console
- HTML files cache for 5 minutes (wait or invalidate)
- Assets cache for 1 year (change filename to update)

### Validation Commands

```bash
# Validate Terraform
./scripts/01_tf_validate.sh

# Check AWS credentials
aws sts get-caller-identity --profile gc

# Check Terraform state
cd terraform && terraform state list

# Test infrastructure
./scripts/03_tf_test_env.sh stg
./scripts/03_tf_test_env.sh prd
```

## CI/CD Pipeline (TeamCity)

### Overview

The project uses TeamCity for continuous integration and deployment. The pipeline automates infrastructure provisioning, website deployment, and testing across staging and production environments.

### TeamCity Build Configuration

#### Prerequisites

**Agent Requirements:**
- Terraform 1.5.7+
- AWS CLI 2.x
- Node.js 18+ (for E2E tests)
- yq 4.x (YAML processor)
- jq 1.6+ (JSON processor)

**Environment Variables:**
```bash
AWS_PROFILE=gc
AWS_REGION=ap-south-1
TF_VAR_aws_profile=gc
TF_VAR_aws_region=ap-south-1
```

**AWS Credentials:**
- Configure AWS credentials in TeamCity with IAM user: `terraform-user`
- Required permissions: S3 full access, CloudFront full access, IAM read

### Build Steps

#### 1. Validate Terraform Configuration

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%
./scripts/01_tf_validate.sh
```

**Purpose**: Validates Terraform syntax, prerequisites, and AWS credentials
**Failure**: Stops the build if validation fails

#### 2. Plan Infrastructure Changes

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%
./scripts/02_tf_deploy_env.sh plan
```

**Purpose**: Shows what infrastructure changes will be made
**Artifacts**: Saves `terraform/tfplan` for review

#### 3. Deploy Infrastructure (Manual Approval)

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%
./scripts/02_tf_deploy_env.sh apply --auto-approve
```

**Purpose**: Applies infrastructure changes
**Trigger**: Manual approval required (TeamCity dependency)
**Duration**: ~5-10 minutes (CloudFront deployment)

#### 4. Test Infrastructure

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%

# Test staging
./scripts/03_tf_test_env.sh stg

# Test production
./scripts/03_tf_test_env.sh prd
```

**Purpose**: Validates deployed infrastructure
**Tests**: S3 buckets, CloudFront distributions, configurations

#### 5. Deploy Website Content (Staging)

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%

# Get configuration
STG_BUCKET=$(yq eval '.S3_BUCKET' environments/stg/config.yaml)
STG_CF_ID=$(yq eval '.CLOUDFRONT_ID' environments/stg/config.yaml)

# Sync website files
aws s3 sync src/ s3://$STG_BUCKET/ \
  --profile gc \
  --cache-control max-age=31536000 \
  --exclude "*.html"

# Upload HTML with short cache
aws s3 sync src/ s3://$STG_BUCKET/ \
  --profile gc \
  --cache-control max-age=300 \
  --exclude "*" \
  --include "*.html"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $STG_CF_ID \
  --paths "/*" \
  --profile gc
```

**Purpose**: Deploys website to staging environment
**Cache**: Assets (1 year), HTML (5 minutes)

#### 6. Run E2E Tests (Staging)

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%

# Install dependencies
npm ci

# Run Playwright tests against staging
BASE_URL=https://stg.gadgetcloud.io npx playwright test
```

**Purpose**: Validates staging deployment
**Artifacts**: Test reports, screenshots, videos

#### 7. Deploy Website Content (Production - Manual Approval)

```bash
#!/bin/bash
cd %teamcity.build.checkoutDir%

# Get configuration
PRD_BUCKET=$(yq eval '.S3_BUCKET' environments/prd/config.yaml)
PRD_CF_ID=$(yq eval '.CLOUDFRONT_ID' environments/prd/config.yaml)

# Sync website files
aws s3 sync src/ s3://$PRD_BUCKET/ \
  --profile gc \
  --cache-control max-age=31536000 \
  --exclude "*.html"

# Upload HTML with short cache
aws s3 sync src/ s3://$PRD_BUCKET/ \
  --profile gc \
  --cache-control max-age=300 \
  --exclude "*" \
  --include "*.html"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $PRD_CF_ID \
  --paths "/*" \
  --profile gc
```

**Purpose**: Deploys website to production
**Trigger**: Manual approval required
**Cache**: Assets (1 year), HTML (5 minutes)

### Build Triggers

**VCS Trigger:**
- Branch: `main`
- Trigger: On commit/push
- Quiet period: 60 seconds

**Schedule Trigger (Optional):**
- Daily infrastructure validation at 2 AM UTC
- Purpose: Detect configuration drift

### Artifact Paths

```
terraform/tfplan => terraform-plans/
test-results/ => test-reports/
playwright-report/ => e2e-reports/
```

### Build Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `env.AWS_PROFILE` | `gc` | AWS CLI profile |
| `env.AWS_REGION` | `ap-south-1` | Primary AWS region |
| `env.TF_IN_AUTOMATION` | `true` | Terraform CI mode |

### Notifications

**Success:**
- Slack: `#deployments`
- Email: `team@gadgetcloud.io`

**Failure:**
- Slack: `#alerts`
- Email: `ops@gadgetcloud.io`
- Include: Build log, error summary

### Rollback Procedure

If production deployment fails:

```bash
# 1. Identify last good deployment
aws s3 ls s3://www.gadgetcloud.io --profile gc --recursive | grep index.html

# 2. List object versions
aws s3api list-object-versions --bucket www.gadgetcloud.io --profile gc

# 3. Restore previous version
aws s3api copy-object \
  --copy-source www.gadgetcloud.io/index.html?versionId=<VERSION_ID> \
  --bucket www.gadgetcloud.io \
  --key index.html \
  --profile gc

# 4. Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id ETYXRKWP58UZ5 \
  --paths "/*" \
  --profile gc
```

### Security Considerations

- AWS credentials stored in TeamCity credentials store
- Terraform state stored in S3: `s3://tf-state.gadgetcloud.io`
- State locking via DynamoDB
- No secrets in version control
- ACM certificates managed outside Terraform

### Monitoring

**Build Metrics:**
- Average build time: ~15 minutes
- Success rate target: >95%
- Infrastructure deployment: ~5 minutes
- Content deployment: ~2 minutes
- E2E tests: ~3 minutes

**Post-Deployment:**
- CloudFront logs → S3
- Website monitoring via CloudWatch
- Form API monitoring separate

## Important Constraints

- **No build step**: All HTML/CSS/JS must work directly in browsers
- **No runtime dependencies**: Playwright is dev-only
- **CSP compliance**: No inline scripts allowed
- **Mobile-first**: All features must work on mobile viewports
- **API rate limits**: Client (10/hr) and server-side rate limiting
- **Region requirements**: S3 in ap-south-1, ACM/CloudFront in us-east-1

## Documentation

- **CI/CD Pipeline**: [CICD.md](CICD.md) - Complete deployment and testing workflows
- **Terraform**: [terraform/README.md](terraform/README.md)
- **AI Instructions**: [CLAUDE.md](CLAUDE.md)
- **Manifest Audit**: [MANIFEST_AUDIT.md](MANIFEST_AUDIT.md)

## Support

For issues or questions:
1. Check this README and linked documentation
2. Review script output for detailed error messages
3. Verify prerequisites are installed
4. Validate AWS credentials and permissions
5. Check Terraform state matches deployed infrastructure
6. Run validation script: `./scripts/01_tf_validate.sh`
7. Run infrastructure tests: `./scripts/03_tf_test_env.sh [stg|prd]`

---

**Version**: 1.0.0
**Last Updated**: 2025-12-11
**Security Audit**: 2025-12-11 (Score: 98/100)
**Maintained By**: GadgetCloud Team
**Repository**: https://github.com/gadgetcloud-io/gc-static-public-www-web
