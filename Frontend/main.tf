terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"

    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # profile = "iamadmin-general"
  region  = "us-east-1"
  alias   = "us-east-1"
}

# ------------------- ACM -------------------- #
resource "aws_acm_certificate" "DNS-cert" {
  provider          = aws.us-east-1
  domain_name       = "*.ojowilliamsdaniel.online"
  validation_method = "DNS"
}

# Create Resume Bucket
resource "aws_s3_bucket" "subdomain_bucket" {
  bucket = "www.ojowilliamsdaniel.online"

  force_destroy = true

  tags = {
    Name        = "Resume Bucket"
    Environment = "Prod"
  }
}
data "aws_iam_policy_document" "allow_access" {
  policy_id = "PolicyForCloudFrontPrivateContent"
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.subdomain_bucket.arn}/*"]
    actions   = ["s3:GetObject"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.s3_distribution.arn}"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }

}

resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.subdomain_bucket.id
  policy = data.aws_iam_policy_document.allow_access.json
}

# Create static website hosting bucket
resource "aws_s3_bucket" "domain_bucket" {
  bucket = "ojowilliamsdaniel.online"

  tags = {
    Name = "Domain Bucket"
  }
}
resource "aws_s3_bucket_website_configuration" "domain_static_site" {
  bucket = aws_s3_bucket.domain_bucket.id

  redirect_all_requests_to {
    host_name = aws_s3_bucket.subdomain_bucket.id
    protocol  = "https"
  }
}

# Make bucket not public
resource "aws_s3_bucket_public_access_block" "bucket_not_public" {
  bucket = aws_s3_bucket.subdomain_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_acl" "make_private" {
  bucket = aws_s3_bucket.subdomain_bucket.id
  acl    = "private"
}

# ------------ HTTPS infrasturcture ----------------- #
# Cloudfront
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.subdomain_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.origin_access_control.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  aliases = ["${aws_s3_bucket.subdomain_bucket.bucket}"]

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate_validation.cert-val.certificate_arn
    ssl_support_method             = "sni-only"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }



}
resource "aws_cloudfront_origin_access_control" "origin_access_control" {
  name                              = "www.ojowilliamsdaniel.com"
  description                       = "send authenticated request to s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.s3_distribution.arn
}

# ------------------ Route53 -------------------- #
resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.DNS-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}
resource "aws_acm_certificate_validation" "cert-val" {

  certificate_arn         = aws_acm_certificate.DNS-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}

data "aws_route53_zone" "hosted_zone" {
  name = "ojowilliamsdaniel.online"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [
    aws_cloudfront_distribution.s3_distribution
  ]
}

output "domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}








