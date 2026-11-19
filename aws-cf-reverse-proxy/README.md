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
| `error_caching_min_ttl` | `0` | A 4xx or 5xx without `Cache-Control` is not cached. CloudFront's own default is 10 s, and a cached error goes to every caller with the same cache key. |

The policy respects origin headers: a response (also an error) that sends
`Cache-Control: max-age` or `Expires` is cached for that time, at most
`cache_max_ttl` (default 300 s). So an API or auth origin must send
`Cache-Control: no-store` on per-user responses, as lutherauth does. A static
origin that wants caching sends its own `Cache-Control`.

**Upgrade note:** before this change the default TTL was 60 s. A static origin
that sends no `Cache-Control` is no longer cached; set `cache_default_ttl` to
keep the old behaviour. A caller with `cache_min_ttl` above 0 must also raise
`cache_default_ttl`, or the plan fails its precondition.

## Forwarded headers

The cache policy forwards the module's five headers (`Origin`,
`Authorization`, `Accept`, `Content-Type`, `User-Agent`) and
`extra_forwarded_headers` to the origin, and puts them all in the cache key.
CloudFront allows 10 headers per cache policy by default, so the list can
fill up.

`origin_request_headers` forwards more headers through an origin request
policy, without putting them in the cache key. luthersystems/ui-infrastructure#624
needed this: the cache policy was full, so CloudFront dropped
`X-A2A-Task-Kind` and insideout-mcp's `ListTasks` ignored its kind filter.

Requests that differ only in an `origin_request_headers` header share a
cached response. So the module requires `cache_min_ttl = 0` and
`cache_default_ttl = 0` with it: then only a response that sends
`Cache-Control` max-age or s-maxage, or `Expires`, is cached. Put a header
that changes a cacheable response in `extra_forwarded_headers` (at most 5). `Authorization` must stay in
the cache policy (CloudFront refuses it in an origin request policy).
