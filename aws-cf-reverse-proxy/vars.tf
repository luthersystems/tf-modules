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

variable "app_naked_domain" {
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
