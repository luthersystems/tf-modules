variable "target_tags" {
  type = "map"
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
  type = "string"
}
