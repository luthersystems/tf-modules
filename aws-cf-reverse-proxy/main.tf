resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  # Default route from origin_url if origin_routes not provided
  base_routes = length(var.origin_url) > 0 ? {
    "/*" = var.origin_url
  } : {}

  merged_origin_routes = merge(local.base_routes, var.origin_routes)

  origin_configs = {
    for path, url in local.merged_origin_routes :
    path => {
      origin_id     = "origin-${path == "/*" ? "site" : replace(trim(path, "/*"), "[^a-zA-Z0-9]", "-")}"
      origin_domain = regex("^https?://([^/]+)", url)[0]
      origin_path   = try(regex("^https?://[^/]+(/.*)", url)[0], null)
    }
  }

  random_id = var.random_identifier == "" ? random_string.id[0].result : var.random_identifier

  app_route53_zone_name = var.app_route53_zone_name != "" ? var.app_route53_zone_name : var.app_naked_domain

  target_record_name = (
    var.app_target_domain == local.app_route53_zone_name
    ? ""
    : replace(var.app_target_domain, ".${local.app_route53_zone_name}", "")
  )

  use_cors = var.use_cors && length(var.cors_allowed_origins) > 0
}

module "luthername_site" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "api"
  subcomponent   = "site"
  resource       = "cf"
  id             = local.random_id
}

data "aws_route53_zone" "site" {
  name         = "${local.app_route53_zone_name}."
  private_zone = false
}

resource "aws_acm_certificate" "site" {
  # ACM certs for CloudFront must be in us-east-1:
  # https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html
  provider          = aws.us-east-1
  domain_name       = var.app_target_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "site_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.site.zone_id
}

resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.site_validation : record.fqdn]
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = local.target_record_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled      = true
  price_class  = "PriceClass_200"
  http_version = "http2"

  dynamic "origin" {
    for_each = local.origin_configs
    content {
      origin_id   = origin.value.origin_id
      domain_name = origin.value.origin_domain
      origin_path = origin.value.origin_path

      custom_origin_config {
        origin_protocol_policy = "https-only"
        http_port              = 80
        https_port             = 443
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      custom_header {
        name  = "User-Agent"
        value = var.duplicate_content_penalty_secret
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = {
      for k, v in local.origin_configs : k => v if k != "/*"
    }

    content {
      path_pattern           = ordered_cache_behavior.key
      target_origin_id       = ordered_cache_behavior.value.origin_id
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      compress = true

      cache_policy_id = aws_cloudfront_cache_policy.respect_origin_headers.id

      response_headers_policy_id = local.use_cors ? aws_cloudfront_response_headers_policy.allow_specified_origins[0].id : null
    }
  }

  default_cache_behavior {
    target_origin_id       = "origin-site"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    cache_policy_id = aws_cloudfront_cache_policy.respect_origin_headers.id

    response_headers_policy_id = local.use_cors ? aws_cloudfront_response_headers_policy.allow_specified_origins[0].id : null

    dynamic "lambda_function_association" {
      for_each = var.use_302 ? [1] : []
      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_function[0].qualified_arn
        include_body = false
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  aliases = [var.app_target_domain]

  logging_config {
    include_cookies = true
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  tags = module.luthername_site.tags
}

resource "aws_cloudfront_response_headers_policy" "allow_specified_origins" {
  count = length(var.cors_allowed_origins) > 0 ? 1 : 0

  name = "allow-specified-cors-origins"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = var.cors_allowed_origins
    }

    origin_override = true
  }

  security_headers_config {
    content_type_options {
      override = true
    }
  }
}

resource "aws_s3_bucket" "cf_logs" {
  bucket        = "${module.luthername_site.name}-cf-logs"
  force_destroy = true

  tags = module.luthername_site.tags
}

data "aws_caller_identity" "current" {}


resource "aws_s3_bucket_policy" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.cf_logs.arn}/cloudfront/*",
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid : "AllowBucketACLForCloudFront",
        Effect : "Allow",
        Principal : {
          Service : "cloudfront.amazonaws.com"
        },
        Action : "s3:PutObjectAcl",
        Resource : "${aws_s3_bucket.cf_logs.arn}/cloudfront/*",
        Condition : {
          StringEquals : {
            "AWS:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

output "origin_configs" {
  value = local.origin_configs
}

resource "aws_cloudfront_cache_policy" "respect_origin_headers" {
  name = "${module.luthername_site.name}-default-policy"

  # omitting these should use origin cache settings
  # https://github.com/hashicorp/terraform-provider-aws/issues/19382
  #min_ttl     = 0
  #default_ttl = 300
  #max_ttl     = 1200

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Authorization", "Accept", "Content-Type", "User-Agent"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
