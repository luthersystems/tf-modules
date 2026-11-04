# Pins that the CDN never caches a dynamic response the origin did not mark
# cacheable, and never caches an error. A default TTL of 60 s cached
# lutherauth's oauth_login with its Set-Cookie headers, so every login in
# the window shared one OAuth state and PKCE verifier
# (luthersystems/ui-infrastructure#487). CloudFront also caches a 4xx or
# 5xx for 10 s by default, so one failed login broke the next ones.

mock_provider "aws" {}
mock_provider "aws" {
  alias = "us-east-1"
  # The validation records' for_each needs known keys at plan time. A mock
  # leaves domain_validation_options unknown, the real provider does not.
  override_resource {
    target          = aws_acm_certificate.site
    override_during = plan
    values = {
      # The distribution checks that the certificate ARN is an ARN.
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
      domain_validation_options = [{
        domain_name           = "target.example.com"
        resource_record_name  = "_x.target.example.com"
        resource_record_type  = "CNAME"
        resource_record_value = "_y.acm-validations.aws"
      }]
    }
  }
}
mock_provider "random" {}
mock_provider "archive" {}

variables {
  luther_env            = "env"
  luther_project        = "project"
  app_target_domain     = "target.example.com"
  app_route53_zone_name = "app.example.com"
  origin_url            = "https://origin.example.com"
  use_302               = true
  cors_allowed_origins  = ["https://app.example.com"]
}

run "no_default_ttl" {
  command = plan

  assert {
    condition     = aws_cloudfront_cache_policy.respect_origin_headers.default_ttl == 0
    error_message = "a response without Cache-Control must not be cached"
  }
}

run "errors_not_cached" {
  command = plan

  assert {
    # The 4xx and 5xx codes CloudFront caches by default.
    condition = toset([for e in aws_cloudfront_distribution.site.custom_error_response : e.error_code if e.error_caching_min_ttl == 0]) == toset(
      [400, 403, 404, 405, 414, 416, 500, 501, 502, 503, 504],
    ) && length(aws_cloudfront_distribution.site.custom_error_response) == 11
    error_message = "every 4xx and 5xx code CloudFront caches must have error_caching_min_ttl = 0"
  }
}

run "min_ttl_above_default_fails" {
  command = plan
  variables {
    cache_min_ttl = 30
  }
  expect_failures = [aws_cloudfront_cache_policy.respect_origin_headers]
}
