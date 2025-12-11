# Production Outputs
output "production_bucket_name" {
  description = "Name of the production S3 bucket"
  value       = aws_s3_bucket.production.id
}

output "production_bucket_arn" {
  description = "ARN of the production S3 bucket"
  value       = aws_s3_bucket.production.arn
}

output "production_cloudfront_id" {
  description = "ID of the production CloudFront distribution"
  value       = aws_cloudfront_distribution.production.id
}

output "production_cloudfront_domain" {
  description = "Domain name of the production CloudFront distribution"
  value       = aws_cloudfront_distribution.production.domain_name
}

output "production_cloudfront_arn" {
  description = "ARN of the production CloudFront distribution"
  value       = aws_cloudfront_distribution.production.arn
}

# Staging Outputs
output "staging_bucket_name" {
  description = "Name of the staging S3 bucket"
  value       = aws_s3_bucket.staging.id
}

output "staging_bucket_arn" {
  description = "ARN of the staging S3 bucket"
  value       = aws_s3_bucket.staging.arn
}

output "staging_cloudfront_id" {
  description = "ID of the staging CloudFront distribution"
  value       = aws_cloudfront_distribution.staging.id
}

output "staging_cloudfront_domain" {
  description = "Domain name of the staging CloudFront distribution"
  value       = aws_cloudfront_distribution.staging.domain_name
}

output "staging_cloudfront_arn" {
  description = "ARN of the staging CloudFront distribution"
  value       = aws_cloudfront_distribution.staging.arn
}

# Redirect Outputs
output "redirect_bucket_name" {
  description = "Name of the redirect S3 bucket"
  value       = aws_s3_bucket.redirect.id
}

output "redirect_bucket_arn" {
  description = "ARN of the redirect S3 bucket"
  value       = aws_s3_bucket.redirect.arn
}

output "redirect_cloudfront_id" {
  description = "ID of the redirect CloudFront distribution"
  value       = aws_cloudfront_distribution.redirect.id
}

output "redirect_cloudfront_domain" {
  description = "Domain name of the redirect CloudFront distribution"
  value       = aws_cloudfront_distribution.redirect.domain_name
}

output "redirect_cloudfront_arn" {
  description = "ARN of the redirect CloudFront distribution"
  value       = aws_cloudfront_distribution.redirect.arn
}

# DNS Configuration Instructions
output "dns_configuration" {
  description = "DNS configuration instructions"
  value = {
    production = {
      domain = var.production_domain
      type   = "CNAME"
      value  = aws_cloudfront_distribution.production.domain_name
    }
    staging = {
      domain = var.staging_domain
      type   = "CNAME"
      value  = aws_cloudfront_distribution.staging.domain_name
    }
    redirect = {
      domain = "gadgetcloud.io"
      type   = "A/AAAA (Alias)"
      value  = aws_cloudfront_distribution.redirect.domain_name
    }
  }
}
