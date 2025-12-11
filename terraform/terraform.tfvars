# Terraform Variables for GadgetCloud Static Website
# Deploys both staging and production environments

# AWS Configuration
aws_region  = "ap-south-1"
aws_profile = "gc"

# Domain Names
production_domain = "www.gadgetcloud.io"
staging_domain    = "stg.gadgetcloud.io"

# ACM Certificate ARNs (must be in us-east-1 for CloudFront)
# All environments use the same wildcard certificate
production_certificate_arn = "arn:aws:acm:us-east-1:860154085634:certificate/7f6bb0d4-267c-4916-b68e-dc66a5cb0056"
staging_certificate_arn    = "arn:aws:acm:us-east-1:860154085634:certificate/7f6bb0d4-267c-4916-b68e-dc66a5cb0056"
redirect_certificate_arn   = "arn:aws:acm:us-east-1:860154085634:certificate/7f6bb0d4-267c-4916-b68e-dc66a5cb0056"

# Common Tags
tags = {
  Project    = "GadgetCloud"
  ManagedBy  = "Terraform"
  Repository = "gc-static-www-web"
  Owner      = "GadgetCloud Team"
}
