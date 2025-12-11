# CI/CD Pipeline Documentation

Complete deployment and testing workflow for GadgetCloud static website.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Scripts](#deployment-scripts)
- [Testing Scripts](#testing-scripts)
- [Complete Workflows](#complete-workflows)
- [GitHub Actions Integration](#github-actions-integration)
- [Troubleshooting](#troubleshooting)

## Overview

The GadgetCloud website uses a comprehensive set of scripts for infrastructure management, validation, deployment, and testing. All scripts are located in the `scripts/` directory and follow a numbered sequence for easy workflow execution.

### Script Sequence

| Script | Name | Purpose | Environment |
|--------|------|---------|-------------|
| 01 | `01_tf_validate.sh` | Terraform validation | All |
| 02 | `02_tf_deploy_env.sh` | Infrastructure deployment | All |
| 03 | `03_tf_test_env.sh` | Infrastructure testing | Staging/Production |
| 04 | `04_html_apply_manifest.sh` | Manifest & version sync | Local |
| 05 | `05_html_test.sh` | HTML validation | Local |
| 06 | `06_html_deploy.sh` | Website deployment | Staging/Production |
| 07 | `07_html_playwright_tests.sh` | E2E testing | Local/Staging/Production |

## Prerequisites

### Required Tools

```bash
# Check all prerequisites
terraform version     # >= 1.0
aws --version        # AWS CLI v2
node --version       # >= 18.x
npm --version        # >= 9.x
yq --version         # >= 4.x
python3 --version    # >= 3.8 (for local server)
```

### AWS Configuration

```bash
# Set up AWS profile
aws configure --profile gc
# Required: AWS Access Key ID, Secret Access Key, Default region: ap-south-1

# Verify credentials
aws sts get-caller-identity --profile gc
```

### Environment Files

Ensure these configuration files exist:

- `environments/stg/config.yaml` - Staging configuration
- `environments/prd/config.yaml` - Production configuration
- `manifest.yaml` - Site metadata
- `VERSION` - Semantic version number
- `terraform/terraform.tfvars` - Terraform variables (Route53 hosted zone ID)

## Deployment Scripts

### 01. Terraform Validation

Validates Terraform configuration syntax and consistency.

```bash
./scripts/01_tf_validate.sh
```

**What it does:**
- Validates Terraform syntax
- Checks for formatting issues
- Validates configuration consistency
- Runs initialization if needed

**When to run:**
- Before infrastructure changes
- After modifying Terraform files
- As part of CI/CD pipeline

### 02. Infrastructure Deployment

Deploys or updates AWS infrastructure (S3, CloudFront, Route53).

```bash
# Plan changes
./scripts/02_tf_deploy_env.sh plan

# Apply changes
./scripts/02_tf_deploy_env.sh apply

# Destroy infrastructure (use with caution!)
./scripts/02_tf_deploy_env.sh destroy
```

**What it does:**
- Initializes Terraform
- Plans infrastructure changes
- Creates/updates S3 buckets
- Configures CloudFront distributions
- Sets up Route53 DNS records

**Resources Created:**
- S3 buckets: `stg.gadgetcloud.io`, `www.gadgetcloud.io`, `apex.gadgetcloud.io`
- CloudFront distributions for each environment
- Route53 A records (aliases to CloudFront)

### 03. Infrastructure Testing

Tests deployed infrastructure to ensure it's accessible and configured correctly.

```bash
# Test staging
./scripts/03_tf_test_env.sh stg

# Test production
./scripts/03_tf_test_env.sh prd
```

**What it does:**
- Checks S3 bucket accessibility
- Verifies CloudFront distribution status
- Tests DNS resolution
- Validates HTTPS configuration
- Checks redirect configuration (apex → www)

### 04. HTML Manifest Validation

Validates HTML against manifest.yaml and applies version/build information.

```bash
# Validation only (dry run)
./scripts/04_html_apply_manifest.sh

# Apply version and build info
./scripts/04_html_apply_manifest.sh --apply
```

**What it does:**
- Validates HTML meta descriptions match manifest
- Checks navigation consistency
- Verifies social links
- Injects version/build info into HTML footers
- Creates build timestamp and git commit reference

**Output Format:**
```
v1.0.0 | Build 20251211180850 | a7bc05b
```

### 05. HTML Validation

Comprehensive HTML validation testing.

```bash
./scripts/05_html_test.sh
```

**What it does:**
- Validates HTML structure (DOCTYPE, meta tags)
- Checks CSS/JS references
- Validates navigation links
- Tests contact form elements
- Verifies security headers (CSP)
- Checks image references
- Validates favicon

**Test Coverage:**
- 103 total tests
- ~94 passing (warnings for missing JS in head, intentional)

### 06. Website Deployment

Deploys website files to S3 and invalidates CloudFront cache.

```bash
# Deploy to staging
./scripts/06_html_deploy.sh stg

# Deploy to staging without tests
./scripts/06_html_deploy.sh stg --skip-tests

# Deploy to production (requires confirmation)
./scripts/06_html_deploy.sh prd

# Deploy to production without tests
./scripts/06_html_deploy.sh prd --skip-tests
```

**What it does:**
- Runs HTML validation tests (unless skipped)
- Syncs assets to S3 with long cache (1 year)
- Syncs HTML files to S3 with short cache (5 minutes)
- Creates CloudFront invalidation
- Provides deployment summary

**Cache Strategy:**
- HTML: 300 seconds (5 minutes)
- Assets (CSS/JS/images): 31536000 seconds (1 year)

**Production Confirmation:**
- Requires typing "deploy" to confirm
- Prevents accidental production deployments

### 07. Playwright E2E Testing

Runs end-to-end tests using Playwright on local or deployed environments.

```bash
# Test local (auto-starts server on port 8000)
./scripts/07_html_playwright_tests.sh local

# Test staging
./scripts/07_html_playwright_tests.sh stg

# Test production
./scripts/07_html_playwright_tests.sh prd

# Additional options
./scripts/07_html_playwright_tests.sh local --headed          # Show browser
./scripts/07_html_playwright_tests.sh stg --ui               # UI mode
./scripts/07_html_playwright_tests.sh prd --debug            # Debug mode
./scripts/07_html_playwright_tests.sh local --grep="Visual"  # Specific tests
./scripts/07_html_playwright_tests.sh stg --project=chromium # Single browser
```

**What it does:**
- Installs dependencies if needed
- Installs Playwright browsers if needed
- Starts local HTTP server (for local testing)
- Checks site accessibility
- Runs all Playwright tests
- Generates HTML report
- Cleans up local server on exit

**Test Suites:**
- `pages.spec.ts` - Page loading and navigation
- `navigation.spec.ts` - Navigation and CTA links
- `contact-form.spec.ts` - Contact form validation and submission
- `visual-enhancements.spec.ts` - Visual elements, images, accessibility (34 tests)

## Testing Scripts

### Running Specific Test Suites

```bash
# Run only visual enhancement tests
./scripts/07_html_playwright_tests.sh local visual-enhancements

# Run only contact form tests
./scripts/07_html_playwright_tests.sh stg contact-form

# Run only navigation tests
./scripts/07_html_playwright_tests.sh prd navigation
```

### Test Reports

After running tests:

```bash
# View HTML report
npx playwright show-report

# Reports are saved to:
# - playwright-report/ (HTML report)
# - test-results/ (screenshots, videos)
```

## Complete Workflows

### Initial Setup Workflow

For first-time setup or new environment:

```bash
# 1. Validate Terraform
./scripts/01_tf_validate.sh

# 2. Deploy infrastructure
./scripts/02_tf_deploy_env.sh plan
./scripts/02_tf_deploy_env.sh apply

# 3. Test infrastructure
./scripts/03_tf_test_env.sh stg
./scripts/03_tf_test_env.sh prd

# 4. Prepare HTML (apply version info)
./scripts/04_html_apply_manifest.sh --apply

# 5. Validate HTML
./scripts/05_html_test.sh

# 6. Deploy to staging
./scripts/06_html_deploy.sh stg

# 7. Test staging
./scripts/07_html_playwright_tests.sh stg

# 8. Deploy to production
./scripts/06_html_deploy.sh prd

# 9. Test production
./scripts/07_html_playwright_tests.sh prd
```

### Development Workflow

For regular development and testing:

```bash
# 1. Make changes to HTML/CSS/JS

# 2. Apply manifest updates
./scripts/04_html_apply_manifest.sh --apply

# 3. Validate HTML
./scripts/05_html_test.sh

# 4. Test locally
./scripts/07_html_playwright_tests.sh local

# 5. Deploy to staging
./scripts/06_html_deploy.sh stg

# 6. Test staging
./scripts/07_html_playwright_tests.sh stg

# 7. If tests pass, deploy to production
./scripts/06_html_deploy.sh prd

# 8. Test production
./scripts/07_html_playwright_tests.sh prd
```

### Hotfix Workflow

For urgent production fixes:

```bash
# 1. Make fix to HTML/CSS/JS

# 2. Quick validation
./scripts/05_html_test.sh

# 3. Test locally
./scripts/07_html_playwright_tests.sh local

# 4. Deploy directly to production (with caution)
./scripts/06_html_deploy.sh prd

# 5. Test production
./scripts/07_html_playwright_tests.sh prd

# 6. Update staging to match
./scripts/06_html_deploy.sh stg
```

### Version Update Workflow

When bumping version number:

```bash
# 1. Update VERSION file
echo "1.1.0" > VERSION

# 2. Apply new version to HTML
./scripts/04_html_apply_manifest.sh --apply

# 3. Commit version changes
git add VERSION src/
git commit -m "Bump version to 1.1.0"

# 4. Deploy to environments
./scripts/06_html_deploy.sh stg
./scripts/06_html_deploy.sh prd
```

## GitHub Actions Integration

### Sample Workflow: Staging Deployment

Create `.github/workflows/deploy-staging.yml`:

```yaml
name: Deploy to Staging

on:
  push:
    branches: [main, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-south-1

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install yq
        run: |
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq

      - name: Install Playwright
        run: npm install && npx playwright install --with-deps chromium

      - name: Apply Manifest
        run: ./scripts/04_html_apply_manifest.sh --apply

      - name: Validate HTML
        run: ./scripts/05_html_test.sh

      - name: Deploy to Staging
        run: ./scripts/06_html_deploy.sh stg --skip-tests

      - name: Run E2E Tests
        run: ./scripts/07_html_playwright_tests.sh stg --project=chromium

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

### Sample Workflow: Production Deployment

Create `.github/workflows/deploy-production.yml`:

```yaml
name: Deploy to Production

on:
  release:
    types: [published]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-south-1

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install yq
        run: |
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq

      - name: Install Playwright
        run: npm install && npx playwright install --with-deps chromium

      - name: Apply Manifest
        run: ./scripts/04_html_apply_manifest.sh --apply

      - name: Validate HTML
        run: ./scripts/05_html_test.sh

      - name: Test Staging First
        run: ./scripts/07_html_playwright_tests.sh stg --project=chromium

      - name: Deploy to Production
        run: echo "deploy" | ./scripts/06_html_deploy.sh prd --skip-tests

      - name: Run E2E Tests on Production
        run: ./scripts/07_html_playwright_tests.sh prd --project=chromium

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report-production
          path: playwright-report/
          retention-days: 30
```

### Sample Workflow: Nightly Tests

Create `.github/workflows/nightly-tests.yml`:

```yaml
name: Nightly E2E Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM UTC daily
  workflow_dispatch:

jobs:
  test-all-environments:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        environment: [stg, prd]

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install yq
        run: |
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq

      - name: Install Playwright
        run: npm install && npx playwright install --with-deps

      - name: Run Tests - ${{ matrix.environment }}
        run: ./scripts/07_html_playwright_tests.sh ${{ matrix.environment }}

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.environment }}
          path: |
            playwright-report/
            test-results/
          retention-days: 7
```

## Troubleshooting

### Common Issues

#### 1. CloudFront Invalidation Taking Too Long

**Problem:** Changes not visible immediately after deployment.

**Solution:**
```bash
# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id EOIMARPNX4A3E \
  --id <INVALIDATION_ID> \
  --profile gc

# Typical completion time: 10-15 minutes
# Use CloudFront domain for immediate access:
# https://dbmr65efdpyk8.cloudfront.net (staging)
# https://d1qxi81dkpyib0.cloudfront.net (production)
```

#### 2. S3 Bucket Versioning Prevents Deletion

**Problem:** `terraform destroy` fails with "BucketNotEmpty" error.

**Solution:**
```bash
# Empty versioned buckets first
./scripts/empty-versioned-bucket.sh stg.gadgetcloud.io gc
./scripts/empty-versioned-bucket.sh www.gadgetcloud.io gc

# Then destroy
cd terraform && terraform destroy -auto-approve
```

#### 3. Playwright Tests Fail on Staging/Production

**Problem:** Tests pass locally but fail on deployed environments.

**Solution:**
```bash
# Wait for CloudFront invalidation to complete
sleep 600  # Wait 10 minutes

# Or check specific CloudFront URL
curl -I https://dbmr65efdpyk8.cloudfront.net

# Verify cache-control headers
curl -I https://stg.gadgetcloud.io | grep -i cache-control
```

#### 4. Local Server Port Already in Use

**Problem:** Port 8000 is already occupied.

**Solution:**
```bash
# Find process using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use a different port
# (requires modifying LOCAL_PORT in script)
```

#### 5. AWS Credentials Not Found

**Problem:** Scripts fail with "Unable to locate credentials".

**Solution:**
```bash
# Configure AWS profile
aws configure --profile gc

# Or export credentials
export AWS_PROFILE=gc
export AWS_DEFAULT_REGION=ap-south-1

# Verify
aws sts get-caller-identity --profile gc
```

### Debug Mode

Enable verbose output for scripts:

```bash
# Bash debug mode
bash -x ./scripts/06_html_deploy.sh stg

# Playwright debug mode
./scripts/07_html_playwright_tests.sh local --debug

# Terraform debug
export TF_LOG=DEBUG
./scripts/02_tf_deploy_env.sh plan
```

### Logs and Reports

```bash
# Playwright HTML report
npx playwright show-report

# CloudFront logs (if enabled)
aws s3 ls s3://your-log-bucket/cloudfront/ --profile gc

# Check recent deployments
aws s3api list-object-versions \
  --bucket stg.gadgetcloud.io \
  --prefix index.html \
  --max-items 5 \
  --profile gc
```

## Best Practices

### 1. Version Management

- Always update `VERSION` file when making significant changes
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Run `04_html_apply_manifest.sh --apply` after version updates

### 2. Testing Strategy

- Test locally before deploying to staging
- Always test staging before production
- Run full test suite after deployments
- Monitor test reports for flaky tests

### 3. Deployment Safety

- Use staging to test changes first
- Production deployments require explicit confirmation
- Never skip tests for production deployments
- Keep CloudFront invalidations tracked

### 4. Infrastructure Changes

- Always run `terraform plan` before `apply`
- Review infrastructure changes carefully
- Keep terraform state backed up
- Document infrastructure modifications

### 5. Rollback Strategy

```bash
# Rollback HTML deployment (use previous version)
aws s3 cp s3://www.gadgetcloud.io/index.html s3://www.gadgetcloud.io/index.html.backup --profile gc
# ... restore other files

# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id E1ISO98SXE9Q6G \
  --paths "/*" \
  --profile gc
```

## Support and Maintenance

- **Scripts Location**: `scripts/`
- **Test Files**: `tests/`
- **Configuration**: `environments/{stg,prd}/config.yaml`
- **Infrastructure**: `terraform/`

For issues or questions, refer to:
- `CLAUDE.md` - Project documentation
- `README.md` - Project overview
- GitHub Issues - Bug reports and feature requests
