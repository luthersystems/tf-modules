variable "aws_region" {
  default = "eu-west-2"
}

variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "app_naked_domain" {
  type = string
}

variable "app_target_domain" {
  type = string
}

variable "duplicate_content_penalty_secret" {
  default = "luthersystems"
}

variable "origin_url" {
  type = string
}

variable "use_302" {
  default = false
}

variable "random_identifier" {
  default = ""
}

variable "web_acl_id" {
  type        = string
  default     = null
  description = "Optional WAFv2 web ACL ARN to attach to the distribution. It must be CLOUDFRONT scope (created in us-east-1). Null attaches none."
}
