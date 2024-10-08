resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  random_id = var.random_identifier == "" ? random_string.id[0].result : var.random_identifier
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
  name         = "${var.app_naked_domain}."
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
  name    = var.app_target_domain
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.site.domain_name]
}

locals {
  origin_domain = replace(var.origin_url, "/(https?://)|(/)/", "")
}

resource "aws_cloudfront_distribution" "site" {
  enabled      = true
  price_class  = "PriceClass_200"
  http_version = "http2"

  origin {
    origin_id   = "origin-site"
    domain_name = local.origin_domain

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = var.duplicate_content_penalty_secret
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl          = "0"
    default_ttl      = "300"
    max_ttl          = "1200"
    target_origin_id = "origin-site"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

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

  tags = module.luthername_site.tags
}
