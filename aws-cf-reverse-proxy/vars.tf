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
  type    = string
  default = "luthersystems"
}

variable "origin_url" {
  type = string
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
