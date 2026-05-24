# Reverse proxy using cloudfront

Quick and dirty reverse proxy with CF.

It also supports hosting on a URL that simply does 302 redirects.

## Optional WAFv2

Set `web_acl_id` to a CLOUDFRONT-scope WAFv2 Web ACL ARN (must be created in
`us-east-1`) to attach edge protection (IP denylist, rate limiting, AWS managed
rule sets, etc.). The variable defaults to `null` — when unset the distribution
stays un-WAFed, matching the pre-existing behaviour for all callers.

```hcl
module "cf_reverse_proxy" {
  source = "github.com/luthersystems/tf-modules.git//aws-cf-reverse-proxy?ref=v55.20.0"

  # ... existing inputs ...

  web_acl_id = aws_wafv2_web_acl.app_domain.arn
}
```
