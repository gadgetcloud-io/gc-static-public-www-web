# S3 Bucket for Production
resource "aws_s3_bucket" "production" {
  bucket = var.production_domain
  tags = merge(var.tags, {
    Name        = "GadgetCloud Production Website"
    Environment = "production"
  })
}

resource "aws_s3_bucket_public_access_block" "production" {
  bucket = aws_s3_bucket.production.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "production" {
  bucket = aws_s3_bucket.production.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "production" {
  bucket = aws_s3_bucket.production.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "production" {
  bucket = aws_s3_bucket.production.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.production.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.production.arn
          }
        }
      }
    ]
  })
}

# S3 Bucket for Staging
resource "aws_s3_bucket" "staging" {
  bucket = var.staging_domain
  tags = merge(var.tags, {
    Name        = "GadgetCloud Staging Website"
    Environment = "staging"
  })
}

resource "aws_s3_bucket_public_access_block" "staging" {
  bucket = aws_s3_bucket.staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "staging" {
  bucket = aws_s3_bucket.staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.staging.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.staging.arn
          }
        }
      }
    ]
  })
}

# S3 Bucket for Apex Domain Redirect (gadgetcloud.io -> www.gadgetcloud.io)
# Using apex.gadgetcloud.io as bucket name since gadgetcloud.io is globally taken
resource "aws_s3_bucket" "redirect" {
  bucket = "apex.gadgetcloud.io"
  tags = merge(var.tags, {
    Name        = "GadgetCloud Apex Domain Redirect"
    Environment = "production"
  })
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  redirect_all_requests_to {
    host_name = var.production_domain
    protocol  = "https"
  }
}

resource "aws_s3_bucket_policy" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.redirect.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.redirect.arn
          }
        }
      }
    ]
  })
}
