# Pins the origin request policy for headers that do not fit in the cache
# policy (luthersystems/ui-infrastructure#624: X-A2A-Task-Kind did not fit,
# so CloudFront dropped it).

mock_provider "aws" {}
mock_provider "aws" {
  alias = "us-east-1"
  # As in cache.tftest.hcl: the validation records' for_each needs known keys.
  override_resource {
    target          = aws_acm_certificate.site
    override_during = plan
    values = {
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
}

run "no_policy_by_default" {
  command = plan

  assert {
    condition     = length(aws_cloudfront_origin_request_policy.extra_headers) == 0
    error_message = "no origin request policy without origin_request_headers"
  }

  assert {
    condition     = aws_cloudfront_distribution.site.default_cache_behavior[0].origin_request_policy_id == null
    error_message = "behaviors must have no origin request policy by default"
  }
}

run "policy_forwards_extra_headers" {
  command = plan

  variables {
    origin_request_headers = ["X-A2A-Task-Kind"]
  }

  assert {
    condition     = aws_cloudfront_origin_request_policy.extra_headers[0].headers_config[0].headers[0].items == toset(["X-A2A-Task-Kind"])
    error_message = "the policy must forward exactly origin_request_headers"
  }

  assert {
    condition     = !contains(aws_cloudfront_cache_policy.respect_origin_headers.parameters_in_cache_key_and_forwarded_to_origin[0].headers_config[0].headers[0].items, "X-A2A-Task-Kind")
    error_message = "origin_request_headers must stay out of the cache key"
  }
}

run "rejects_authorization" {
  command = plan

  variables {
    origin_request_headers = ["Authorization"]
  }

  expect_failures = [var.origin_request_headers]
}

run "rejects_cache_policy_duplicate" {
  command = plan

  variables {
    extra_forwarded_headers = ["X-A2A-Task-Secret"]
    origin_request_headers  = ["x-a2a-task-secret"]
  }

  expect_failures = [aws_cloudfront_origin_request_policy.extra_headers]
}
