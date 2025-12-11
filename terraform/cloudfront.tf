# Origin Access Control for Production
resource "aws_cloudfront_origin_access_control" "production" {
  name                              = "gc-production-oac"
  description                       = "OAC for GadgetCloud production S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Origin Access Control for Staging
resource "aws_cloudfront_origin_access_control" "staging" {
  name                              = "gc-staging-oac"
  description                       = "OAC for GadgetCloud staging S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Cache Policy for HTML files (5 minutes)
resource "aws_cloudfront_cache_policy" "html_cache" {
  name        = "gc-html-cache-policy"
  comment     = "Cache policy for HTML files with 5 minute TTL"
  default_ttl = 300
  max_ttl     = 300
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Cache Policy for Assets (1 year)
resource "aws_cloudfront_cache_policy" "assets_cache" {
  name        = "gc-assets-cache-policy"
  comment     = "Cache policy for static assets with 1 year TTL"
  default_ttl = 31536000
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Response Headers Policy for Security Headers
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "gc-security-headers"
  comment = "Security headers for GadgetCloud site"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }

  custom_headers_config {
    items {
      header   = "X-Custom-Header"
      value    = "GadgetCloud"
      override = true
    }
  }
}

# CloudFront Distribution for Production
resource "aws_cloudfront_distribution" "production" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.production_domain]
  price_class         = "PriceClass_100"
  comment             = "GadgetCloud Production Website"

  origin {
    domain_name              = aws_s3_bucket.production.bucket_regional_domain_name
    origin_id                = "S3-${var.production_domain}"
    origin_access_control_id = aws_cloudfront_origin_access_control.production.id
  }

  # Default behavior for HTML files
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.production_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.html_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for CSS files
  ordered_cache_behavior {
    path_pattern               = "css/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.production_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for JS files
  ordered_cache_behavior {
    path_pattern               = "js/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.production_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern               = "images/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.production_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.production_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name        = "GadgetCloud Production"
    Environment = "production"
  })
}

# CloudFront Distribution for Staging
resource "aws_cloudfront_distribution" "staging" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.staging_domain]
  price_class         = "PriceClass_100"
  comment             = "GadgetCloud Staging Website"

  origin {
    domain_name              = aws_s3_bucket.staging.bucket_regional_domain_name
    origin_id                = "S3-${var.staging_domain}"
    origin_access_control_id = aws_cloudfront_origin_access_control.staging.id
  }

  # Default behavior for HTML files
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.staging_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.html_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for CSS files
  ordered_cache_behavior {
    path_pattern               = "css/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.staging_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for JS files
  ordered_cache_behavior {
    path_pattern               = "js/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.staging_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern               = "images/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.staging_domain}"
    cache_policy_id            = aws_cloudfront_cache_policy.assets_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.staging_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name        = "GadgetCloud Staging"
    Environment = "staging"
  })
}

# CloudFront Origin Access Control for Apex Domain Redirect
resource "aws_cloudfront_origin_access_control" "redirect" {
  name                              = "gc-redirect-oac"
  description                       = "OAC for GadgetCloud apex domain redirect bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for Apex Domain Redirect (gadgetcloud.io -> www.gadgetcloud.io)
resource "aws_cloudfront_distribution" "redirect" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "GadgetCloud Apex Domain Redirect"
  aliases             = ["gadgetcloud.io"]
  price_class         = "PriceClass_100"
  http_version        = "http2"
  wait_for_deployment = true

  origin {
    domain_name              = aws_s3_bucket.redirect.bucket_regional_domain_name
    origin_id                = "S3-gadgetcloud.io"
    origin_access_control_id = aws_cloudfront_origin_access_control.redirect.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-gadgetcloud.io"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.html_cache.id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.redirect_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name        = "GadgetCloud Apex Redirect"
    Environment = "production"
  })
}
