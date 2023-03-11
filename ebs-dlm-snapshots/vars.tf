variable "target_tags" {
  type = map(string)
}

variable "interval_hours" {
  default = 24
}

variable "times" {
  default = ["23:45"]
}

variable "retain_count" {
  default = 14
}

variable "role_arn" {
  default = ""
}

variable "description" {
  type = string
}

variable "cross_region_settings" {
  type = map(object({
    region        = string
    cmk_arn       = string
    interval      = number
    interval_unit = string
  }))
}
