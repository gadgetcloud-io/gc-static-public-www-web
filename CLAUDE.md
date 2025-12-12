# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GadgetCloud static marketing website - a static HTML/CSS/JS site for www.gadgetcloud.io that showcases a gadget inventory and management platform. The site includes a contact form that submits to a REST API backend.

**For complete CI/CD pipeline documentation, deployment workflows, and GitHub Actions integration, see [CICD.md](CICD.md).**

## Architecture

**Multi-Environment Static Site with AWS Deployment**

- **Frontend**: Pure static HTML5/CSS3/JavaScript (no build step, no frameworks)
- **Backend Integration**: Contact form submits to `https://rest.gadgetcloud.io/forms` REST API
- **Configuration**: Environment-specific config files in `environments/` (stg/prd)
- **Deployment**: AWS S3 + CloudFront with different cache policies for HTML vs assets
- **Content Management**: Site metadata (navigation, social links, site info) defined in `manifest.yaml`

### Directory Structure

```
src/                    # Static website files
  ├── *.html           # Page templates (index, about_us, products, services, contact_us, error)
  ├── css/styles.css   # All styles with CSS variables, animations, responsive design
  ├── js/main.js       # Navigation, form submission, rate limiting, source tracking
  └── images/          # SVG logos, illustrations, favicon
scripts/               # Deployment and testing scripts
  ├── 01_tf_validate.sh        # Terraform validation
  ├── 02_tf_deploy_env.sh      # Terraform infrastructure deployment
  ├── 03_tf_test_env.sh        # Infrastructure testing
  ├── 04_html_apply_manifest.sh # Manifest validation & version injection
  ├── 05_html_test.sh          # HTML validation tests
  ├── 06_html_deploy.sh        # Website deployment to S3/CloudFront
  └── 07_html_playwright_tests.sh # Playwright E2E test runner
terraform/             # Infrastructure as Code
  ├── main.tf          # Provider configuration
  ├── s3.tf            # S3 buckets (stg, prd, redirect)
  ├── cloudfront.tf    # CloudFront distributions
  ├── route53.tf       # Route53 DNS records (A records with CloudFront aliases)
  ├── variables.tf     # Input variables
  └── outputs.tf       # Output values
environments/
  ├── stg/config.yaml  # Staging environment config (stg.gadgetcloud.io)
  └── prd/config.yaml  # Production environment config (www.gadgetcloud.io)
tests/                 # Playwright E2E tests
manifest.yaml          # Site-wide configuration (menu, social links, metadata, version)
```

## Development Commands

**Note:** For complete workflow documentation including CI/CD pipelines, see [CICD.md](CICD.md).

### Infrastructure Management
```bash
# Validate Terraform configuration
./scripts/01_tf_validate.sh

# Plan infrastructure changes
./scripts/02_tf_deploy_env.sh plan

# Apply infrastructure changes
./scripts/02_tf_deploy_env.sh apply

# Test deployed infrastructure
./scripts/03_tf_test_env.sh stg    # Test staging
./scripts/03_tf_test_env.sh prd    # Test production
```

### HTML Validation and Version Management
```bash
# Validate HTML against manifest (validation only)
./scripts/04_html_apply_manifest.sh

# Apply version and build info to HTML footers
./scripts/04_html_apply_manifest.sh --apply

# Run comprehensive HTML validation tests (103 tests)
./scripts/05_html_test.sh
```

### Website Deployment
```bash
# Deploy to staging
./scripts/06_html_deploy.sh stg

# Deploy to production (requires confirmation)
./scripts/06_html_deploy.sh prd

# Deploy without running tests first
./scripts/06_html_deploy.sh stg --skip-tests
```

### E2E Testing
```bash
# Run Playwright tests on local (auto-starts server)
./scripts/07_html_playwright_tests.sh local

# Run Playwright tests against staging
./scripts/07_html_playwright_tests.sh stg

# Run Playwright tests against production
./scripts/07_html_playwright_tests.sh prd

# Run with browser visible
./scripts/07_html_playwright_tests.sh local --headed

# Run in debug mode
./scripts/07_html_playwright_tests.sh stg --debug

# Run in UI mode
./scripts/07_html_playwright_tests.sh prd --ui

# Run specific tests
./scripts/07_html_playwright_tests.sh local --grep="Visual Enhancements"

# Or run directly with npx
npx playwright test                    # Run all tests
npx playwright test --headed          # Run with browser visible
npx playwright test contact-form      # Run specific test file
npx playwright test --ui              # Run in UI mode
```

## Key Implementation Details

### Contact Form Flow
1. **Client-side validation**: HTML5 required fields (firstName, lastName, email, subject, message), email format
2. **Honeypot field**: Hidden `_gotcha` input to catch bots
3. **Rate limiting**: localStorage-based (10 submissions per hour)
4. **Source tracking**: Captures UTM parameters, referrer, page URL
5. **Referral tracking**: Captures `referredBy` parameter from URL for affiliate/partner tracking
6. **API submission**: POST to `https://rest.gadgetcloud.io/forms?type=contacts` with JSON payload
7. **Success confirmation**: Displays submission ID (e.g., "Confirmation: FSM-UANG5VZ1QA") upon successful submission
8. **Test mode**: Playwright tests mock API responses to prevent actual email sending

### Form Data Structure
**Backend Integration:** gc-py-public-forms-svc (commit ac14776)

```javascript
// Query Parameter: ?type=contacts
// Request Body (flat structure):
{
  firstName: string,      // Required, min 2 chars, max 50 chars
  lastName: string,       // Required, min 2 chars, max 50 chars
  email: string,          // Required, email format, max 255 chars
  subject: string,        // Required, min 5 chars, max 100 chars
  message: string,        // Required, min 10 chars, max 1000 chars
  source: string,         // UTM source, referrer domain, or "direct"
  referrer: string,       // Full referrer URL or "direct"
  pageUrl: string,        // Submission page URL
  referredBy?: string     // Optional: Affiliate/partner identifier from URL parameter
}

// Success Response:
{
  success: true,
  submission_id: string,  // e.g., "FSM-UANG5VZ1QA" - Displayed to user as confirmation
  message: string
}

// Success Message Displayed to User:
// "Thank you for your message! We will get back to you soon. Confirmation: FSM-UANG5VZ1QA"

// Error Response:
{
  error: string,          // Error message
  message?: string        // Optional detailed message
}
```

### Referral Tracking

The contact form automatically captures the `referredBy` URL parameter for tracking affiliate and partner referrals.

**Usage Examples:**
```bash
# Affiliate link
https://www.gadgetcloud.io/contact_us.html?referredBy=affiliate-partner-123

# Partner campaign
https://www.gadgetcloud.io/contact_us.html?referredBy=tech-blog-promo

# Combined with other parameters
https://www.gadgetcloud.io/contact_us.html?utm_source=newsletter&referredBy=email-campaign-Q4
```

**Implementation:**
- Extracted from URL via `URLSearchParams`
- Only included in payload if present
- Stored in form submission for analytics and attribution
- Compatible with other tracking parameters (UTM, source, etc.)

### Navigation System
- Mobile-responsive hamburger menu (toggles `.active` class)
- Auto-closes on outside click or link click
- Active state styling on current page
- Smooth scroll for anchor links

### Security Headers
All HTML pages include:
- Content Security Policy (CSP) restricting script/style sources
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- Referrer-Policy: strict-origin-when-cross-origin

### CSS Architecture
- CSS custom properties (variables) for theming
- Mobile-first responsive design with media queries
- Animations: fadeInUp, slideInRight, float, shimmer, pulse-glow
- Utility classes: `.container`, `.section-decoration`, `.btn-*`, `.card-*`

## Testing

### Playwright Test Structure
- **pages.spec.ts**: Page loading and basic navigation
- **navigation.spec.ts**: Navigation links, active states, CTA buttons
- **contact-form.spec.ts**: Form validation, submission, API integration, error handling

### Test Patterns
- Mobile menu helper: `openMobileMenuIfNeeded()` for viewport-aware navigation
- API mocking: Tests intercept API calls to inject `isTest: true` flag
- Rate limit clearing: Each test clears localStorage before running
- Error scenarios: Network failures, API errors, validation errors

## Environment Configuration

### manifest.yaml
Central configuration for site-wide settings:
- Site metadata (name, title, header, footer, description)
- Address information
- Menu items (text, link, title, description)
- Social links (platform, URL)

### environments/{stg,prd}/config.yaml
Deployment-specific settings:
- `hostName`: Target domain
- `path`: Base path for staging environments
- `AWS_PROFILE`: AWS CLI profile name
- `S3_BUCKET`: S3 bucket name
- `CLOUDFRONT_ID`: CloudFront distribution ID

## Version Management

### Version Source
The `manifest.yaml` file contains the semantic version number in the `version` field (e.g., `version: 1.0.0`). This version is automatically injected into HTML page footers during deployment.

### Version Injection Process
```bash
# Script 04 reads version from manifest.yaml and generates build info:
VERSION=$(yq eval '.version' manifest.yaml)         # e.g., "1.0.0"
BUILD_TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")         # e.g., "20251211142736"
GIT_COMMIT=$(git rev-parse --short HEAD || echo "") # e.g., "a1b2c3d" or empty

# Creates version string:
# With git:    "v1.0.0 | Build 20251211142736 | a1b2c3d"
# Without git: "v1.0.0 | Build 20251211142736"
```

### Version Display
Version information appears in HTML footers with styling:
```html
<div class="version-info">v1.0.0 | Build 20251211142736</div>
```

CSS styling (src/css/styles.css:889-895):
- Center aligned
- Small text (0.75rem)
- 60% opacity
- Subtle gray color

### Updating Version
1. Edit `version` field in `manifest.yaml` with new semantic version
2. Run `./scripts/04_html_apply_manifest.sh --apply` to inject into HTML
3. Build timestamp and git commit are generated automatically

## Deployment Notes

### Cache Strategy
- **Assets** (CSS, JS, images): 1 year cache for performance
- **HTML pages**: 5 minute cache for quick content updates
- **CloudFront invalidation**: Issued on every deploy for immediate updates

### AWS Requirements
- S3 buckets in ap-south-1 (stg, prd, redirect)
- CloudFront distributions (global)
- ACM certificates in us-east-1 (CloudFront requirement)
- AWS CLI profile "gc" with permissions for S3 and CloudFront operations

### Infrastructure Resources
**Staging:**
- S3: stg.gadgetcloud.io
- CloudFront ID: E3HK7UXEK4XGS1
- Domain: stg.gadgetcloud.io
- Route53: A record (alias to CloudFront)

**Production:**
- S3: www.gadgetcloud.io
- CloudFront ID: ETYXRKWP58UZ5
- Domain: www.gadgetcloud.io
- Route53: A record (alias to CloudFront)

**Apex Redirect:**
- S3: apex.gadgetcloud.io
- CloudFront ID: E19OQ6L3JS9KJ5
- Domain: gadgetcloud.io → www.gadgetcloud.io
- Route53: A record (alias to CloudFront redirect)

**DNS Configuration:**
- Route53 Hosted Zone ID: Z0343056NAOP38G4LDLT (provided via terraform.tfvars)
- Uses existing hosted zone (does NOT create new zones)
- Includes MX, DKIM, DMARC, SPF records for email (managed outside Terraform)
- A records for stg, www, and apex domains managed by Terraform via route53.tf

## Common Tasks

### Adding a new page
1. Create `src/newpage.html` following existing page structure
2. Add menu item to `manifest.yaml` under `menu_items`
3. Update navigation in all HTML files if not using templating
4. Add Playwright test in `tests/pages.spec.ts`

### Modifying form behavior
All form logic is in `src/js/main.js`:
- Rate limiting: Lines 55-100
- Source tracking: Lines 102-145
- Form submission: Lines 147-224

### Updating styles
All styles in `src/css/styles.css`:
- CSS variables at top (lines 1-26)
- Animations follow (lines 28-120)
- Component styles organized by section

### Testing form API locally
Test the actual backend API with curl:
```bash
# Test staging environment
curl -X POST "https://rest-stg.gadgetcloud.io/forms?type=contacts" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "subject": "Test Subject",
    "message": "Test message content for API validation",
    "source": "direct",
    "referrer": "direct",
    "pageUrl": "http://localhost:8000/contact_us.html"
  }'

# Test production environment
curl -X POST "https://rest.gadgetcloud.io/forms?type=contacts" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "subject": "Test Subject",
    "message": "Test message for production API",
    "source": "direct",
    "referrer": "direct",
    "pageUrl": "https://www.gadgetcloud.io/contact_us.html"
  }'
```

## Security

### Security Audit Status
**Last Audit:** 2025-12-11
**Security Score:** 98/100
**Status:** ✅ Production Ready - No Critical Vulnerabilities

### Security Features
- ✅ Content Security Policy (CSP) headers
- ✅ X-Frame-Options: DENY (clickjacking protection)
- ✅ HTTPS-only (redirect-to-https everywhere)
- ✅ Modern TLS 1.2+ (TLSv1.2_2021)
- ✅ S3 buckets: All public access blocked
- ✅ CloudFront-only S3 access via OAC
- ✅ No hardcoded credentials anywhere
- ✅ Client-side rate limiting (10/hour)
- ✅ Honeypot field for spam protection
- ✅ XSS prevention (safe DOM manipulation)
- ✅ No eval() or dangerous JavaScript patterns

### Verified Safe
- No command injection in bash scripts
- No path traversal vulnerabilities
- No SQL injection points
- No exposed secrets in configs
- No inline scripts (CSP compliant)
- No sensitive files (.env, .pem, keys)
- Safe user input handling (read -r, regex validation)
- Proper AWS authentication (profile-based only)

## Terraform Destroy and Cleanup

When destroying infrastructure with `terraform destroy`, S3 buckets with versioning enabled require special handling:

### Standard Destroy (Will Fail)
```bash
terraform destroy -auto-approve  # Fails: BucketNotEmpty error
```

### Complete Cleanup Process
```bash
# 1. Empty all object versions and delete markers from buckets
# Create cleanup script
cat > /tmp/empty-versioned-bucket.sh << 'EOF'
#!/bin/bash
BUCKET=$1
PROFILE=$2
aws s3api list-object-versions --bucket "$BUCKET" --profile "$PROFILE" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | @json' | while read -r obj; do
  key=$(echo "$obj" | jq -r '.Key')
  version=$(echo "$obj" | jq -r '.VersionId')
  aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version" --profile "$PROFILE" > /dev/null
done
aws s3api list-object-versions --bucket "$BUCKET" --profile "$PROFILE" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | @json' | while read -r obj; do
  key=$(echo "$obj" | jq -r '.Key')
  version=$(echo "$obj" | jq -r '.VersionId')
  aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version" --profile "$PROFILE" > /dev/null
done
EOF
chmod +x /tmp/empty-versioned-bucket.sh

# 2. Empty all buckets
/tmp/empty-versioned-bucket.sh stg.gadgetcloud.io gc
/tmp/empty-versioned-bucket.sh www.gadgetcloud.io gc

# 3. Run terraform destroy
cd terraform && terraform destroy -auto-approve
```

### Cleaning Up Route53 Hosted Zones

Check for duplicate hosted zones (can occur from multiple terraform applies):
```bash
# List all hosted zones
aws route53 list-hosted-zones --profile gc

# Check which zone is active (domain nameservers)
nslookup -type=NS gadgetcloud.io 8.8.8.8

# Delete inactive zones (delete all records except NS/SOA first)
aws route53 delete-hosted-zone --id <ZONE_ID> --profile gc
```

## Important Constraints

- **No build step**: This is a pure static site - all HTML/CSS/JS must work directly in browsers
- **No dependencies**: No npm packages used at runtime (Playwright only for testing)
- **CSP compliance**: All scripts must be in external files (no inline scripts allowed by CSP)
- **Mobile-first**: All features must work on mobile viewports
- **API rate limits**: Contact form has both client-side (10/hour) and server-side rate limiting
- **AWS regions**: S3 in ap-south-1, ACM/CloudFront must be in us-east-1
- **Route53**: Uses existing hosted zone (Z0343056NAOP38G4LDLT) - does NOT create new zones
