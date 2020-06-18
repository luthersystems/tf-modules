module "luthername_site" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=v23.1.1"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "api"
  subcomponent   = "site"
  resource       = "cf"
  id             = "157d"
}

data "aws_route53_zone" "site" {
  name         = "${var.app_naked_domain}."
  private_zone = false
}

resource "aws_acm_certificate" "site" {
  provider          = aws.us-east-1
  domain_name       = var.app_target_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "site_validation" {
  name    = aws_acm_certificate.site.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.site.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.site.zone_id
  records = [aws_acm_certificate.site.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [aws_route53_record.site_validation.fqdn]
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = var.app_target_domain
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.site.domain_name]
}

resource "aws_cloudfront_distribution" "site" {
  enabled      = true
  price_class  = "PriceClass_200"
  http_version = "http1.1"

  origin {
    origin_id   = "origin-site"
    domain_name = var.origin_url

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1"]
    }

    custom_header {
      name  = "User-Agent"
      value = var.duplicate_content_penalty_secret
    }
  }

  default_root_object = "index.html"

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]
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
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  aliases = [var.app_target_domain]

  tags = module.luthername_site.tags
}
