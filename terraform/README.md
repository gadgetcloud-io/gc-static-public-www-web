# GadgetCloud Infrastructure (Terraform)

This directory contains Terraform configuration for provisioning the AWS infrastructure for GadgetCloud's static website.

## Infrastructure Components

- **S3 Buckets**: Two buckets for production and staging
  - Versioning enabled
  - Public access blocked (CloudFront access only)
  - Website hosting configuration
- **CloudFront Distributions**: CDN distributions for both environments
  - Origin Access Control (OAC) for secure S3 access
  - Custom cache policies (5 min for HTML, 1 year for assets)
  - Security headers (CSP, HSTS, X-Frame-Options, etc.)
  - HTTPS redirect and TLS 1.2+
- **Cache Policies**: Optimized caching for HTML vs static assets
- **Response Headers Policy**: Security headers applied to all responses

## Prerequisites

1. **AWS CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **AWS Profile** named "gc" with appropriate permissions
4. **ACM Certificates** for both domains (must be in us-east-1)
5. **DNS Access** to create CNAME records

## Setup

### 1. Create ACM Certificates

Before running Terraform, create SSL certificates in AWS Certificate Manager:

```bash
# Using AWS Console or CLI, create certificates in us-east-1 for:
# - www.gadgetcloud.io
# - stg.gadgetcloud.io
```

Validate certificates via DNS (add CNAME records provided by ACM).

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your ACM certificate ARNs
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

## Usage

### Deploy to Production

After Terraform creates the infrastructure, update the production config:

```bash
# Update environments/prd/config.yaml with outputs:
# S3_BUCKET: [from terraform output production_bucket_name]
# CLOUDFRONT_ID: [from terraform output production_cloudfront_id]
```

Then deploy:

```bash
./scripts/deploy-env.sh prd
```

### Deploy to Staging

Update staging config similarly:

```bash
# Update environments/stg/config.yaml with outputs:
# S3_BUCKET: [from terraform output staging_bucket_name]
# CLOUDFRONT_ID: [from terraform output staging_cloudfront_id]
```

### View Outputs

```bash
terraform output
```

### Update Infrastructure

After making changes to Terraform files:

```bash
terraform plan
terraform apply
```

### Destroy Infrastructure

To tear down all resources:

```bash
terraform destroy
```

**Warning**: This will delete all S3 buckets and CloudFront distributions!

## DNS Configuration

After Terraform creates the CloudFront distributions, configure DNS:

1. Get CloudFront domain names:
   ```bash
   terraform output dns_configuration
   ```

2. Create CNAME records in your DNS provider:
   ```
   www.gadgetcloud.io -> CNAME -> [production CloudFront domain]
   stg.gadgetcloud.io -> CNAME -> [staging CloudFront domain]
   ```

## Files

- `main.tf` - Provider configuration and Terraform settings
- `s3.tf` - S3 bucket resources and policies
- `cloudfront.tf` - CloudFront distributions, cache policies, security headers
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output values (bucket names, CloudFront IDs, etc.)
- `terraform.tfvars.example` - Example variable values (copy to terraform.tfvars)

## State Management

**Important**: This configuration uses local state. For team collaboration, consider:

1. **S3 Backend**: Store state in S3 with DynamoDB locking
2. **Terraform Cloud**: Managed state and collaboration

Example S3 backend configuration (add to `main.tf`):

```hcl
terraform {
  backend "s3" {
    bucket         = "gadgetcloud-terraform-state"
    key            = "www/terraform.tfstate"
    region         = "us-east-1"
    profile        = "gc"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Cache Behavior

The CloudFront distributions use different cache policies:

- **HTML files** (default): 5 minute cache (max-age=300)
- **CSS/JS/Images**: 1 year cache (max-age=31536000)

This matches the cache headers set by `scripts/deploy-env.sh`.

## Security Features

- S3 buckets are private (no public access)
- CloudFront uses Origin Access Control (OAC)
- HTTPS redirect enforced
- Security headers: HSTS, X-Frame-Options, CSP, X-Content-Type-Options
- TLS 1.2+ only
- Brotli and Gzip compression enabled

## Troubleshooting

### Certificate Issues

- Ensure certificates are in **us-east-1** (CloudFront requirement)
- Verify certificates are fully validated (status: Issued)

### Permission Issues

- Ensure AWS profile has permissions for S3, CloudFront, IAM
- Required permissions: s3:*, cloudfront:*, iam:CreateServiceLinkedRole

### DNS Not Working

- Wait 24-48 hours for DNS propagation
- Verify CNAME records point to CloudFront domains
- Check CloudFront distribution status (must be "Deployed")

### Cache Issues

- CloudFront invalidations can take 10-15 minutes
- Use `aws cloudfront create-invalidation` for immediate updates
- HTML files cache for 5 minutes (wait or invalidate)
