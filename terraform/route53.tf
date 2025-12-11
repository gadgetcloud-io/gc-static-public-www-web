# Route53 DNS Records
# Uses existing hosted zone provided via terraform.tfvars (route53_zone_id variable)
# Does NOT create a new hosted zone - reuses existing zone with MX, DKIM, DMARC records

# Route53 A Record for Production (www.gadgetcloud.io) - Alias to CloudFront
resource "aws_route53_record" "production" {
  zone_id = var.route53_zone_id
  name    = var.production_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.production.domain_name
    zone_id                = aws_cloudfront_distribution.production.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 A Record for Staging (stg.gadgetcloud.io) - Alias to CloudFront
resource "aws_route53_record" "staging" {
  zone_id = var.route53_zone_id
  name    = var.staging_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.staging.domain_name
    zone_id                = aws_cloudfront_distribution.staging.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 A Record for Apex Domain (gadgetcloud.io) - Alias to CloudFront Redirect
resource "aws_route53_record" "redirect" {
  zone_id = var.route53_zone_id
  name    = "gadgetcloud.io"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
