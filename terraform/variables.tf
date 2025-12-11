variable "aws_region" {
  description = "AWS region for resources (S3 buckets will be created here)"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "gc"
}

variable "production_domain" {
  description = "Production domain name"
  type        = string
  default     = "www.gadgetcloud.io"
}

variable "staging_domain" {
  description = "Staging domain name"
  type        = string
  default     = "stg.gadgetcloud.io"
}

variable "production_certificate_arn" {
  description = "ACM certificate ARN for production domain (must be in us-east-1)"
  type        = string
}

variable "staging_certificate_arn" {
  description = "ACM certificate ARN for staging domain (must be in us-east-1)"
  type        = string
}

variable "redirect_certificate_arn" {
  description = "ACM certificate ARN for apex domain redirect (must be in us-east-1)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "GadgetCloud"
    ManagedBy  = "Terraform"
    Repository = "gc-static-www-web"
  }
}
