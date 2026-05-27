variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "app_target_domain" {
  type = string
}

variable "duplicate_content_penalty_secret" {
  type = string
  # Static-site era SEO trick: CloudFront injects this string as the
  # `User-Agent` header on every origin request so the origin can detect
  # CF-routed traffic and serve `X-Robots-Tag: noindex` to avoid Google
  # duplicate-content penalties when both the CF domain and origin domain
  # were publicly indexable.
  #
  # Set to "" to skip the injection. Required for API/JSON origins where
  # the override destroys the real caller's User-Agent header and breaks
  # downstream observability (server logs show "luthersystems" for every
  # request regardless of who actually called).
  default = "luthersystems"
}

variable "origin_url" {
  type    = string
  default = ""
}

variable "use_302" {
  type    = bool
  default = false
}

variable "random_identifier" {
  type    = string
  default = ""
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "List of allowed origins for CORS"
  default     = []
}

variable "app_route53_zone_name" {
  type        = string
  description = "The exact Route53 zone name (e.g., app.luthersystems.com) to use for DNS validation and record creation"
  default     = ""
}

variable "app_naked_domain" {
  type        = string
  description = "Renamed to `app_route53_zone`"
  default     = ""
}

variable "origin_routes" {
  type        = map(string)
  description = "Optional map of path_pattern => origin_url. Overrides origin_url if set."
  default     = {}
}

variable "grpc_routes" {
  type        = map(string)
  default     = {}
  description = "Path-pattern => origin URL map for gRPC cache behaviors. Each entry registers an ordered_cache_behavior with grpc_config { enabled = true }. When non-empty, distribution http_version is automatically promoted to http2and3 (gRPC requires HTTP/2)."
}

variable "extra_forwarded_headers" {
  type        = list(string)
  default     = []
  description = "Additional request headers to whitelist in the cache policy — included in the cache key and forwarded to origin. Appended to the module defaults (Origin, Authorization, Accept, Content-Type, User-Agent). Use for custom headers like X-A2A-Task-Secret that downstream services depend on."
}

variable "use_cors" {
  type    = bool
  default = false
}

variable "cache_min_ttl" {
  type    = number
  default = 0
}

variable "cache_max_ttl" {
  type    = number
  default = 300
}

variable "cache_default_ttl" {
  type    = number
  default = 60
}

variable "origin_read_timeout" {
  description = "How long CloudFront should wait for a response from the origin (in seconds)"
  type        = number
  default     = 60
}

variable "web_acl_id" {
  type        = string
  default     = null
  description = "Optional WAFv2 Web ACL ARN to attach to the CloudFront distribution. Must be CLOUDFRONT-scope (created in us-east-1). Default null leaves the distribution un-WAFed (existing behaviour)."
}
