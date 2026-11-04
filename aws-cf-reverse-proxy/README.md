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

## Caching

The default behavior and every `origin_routes` and `grpc_routes` behavior
share one cache policy. Two defaults keep per-user responses out of the cache:

| Input | Default | Why |
|---|---|---|
| `cache_default_ttl` | `0` | A response without `Cache-Control` or `Expires` is not cached. At `60` CloudFront cached lutherauth's `oauth_login` with its `Set-Cookie` headers, so every login in the window shared one OAuth state (luthersystems/ui-infrastructure#487). |
| `error_caching_min_ttl` | `0` | A 4xx or 5xx is not cached. CloudFront's own default is 10 s, and a cached error goes to every caller with the same cache key. |

An origin that wants caching (a static site) sends its own `Cache-Control`;
CloudFront keeps it for at most `cache_max_ttl` (default 300 s).
