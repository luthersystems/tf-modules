variable "target_tags" {
  type = map(string)
}

variable "interval_hours" {
  type    = number
  default = 24
}

variable "times" {
  type    = list(string)
  default = ["23:45"]
}

variable "retain_count" {
  type    = number
  default = 14
}

variable "role_arn" {
  type = string
}

variable "description" {
  type = string
}

variable "cross_region_settings" {
  type = list(object({
    region        = string
    cmk_arn       = string
    interval      = number
    interval_unit = string
  }))
  default = []
}

variable "luther_env" {
  type = string
}

variable "luther_project" {
  type = string
}
