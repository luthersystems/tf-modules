variable "timestamped_log_files" {
  type = list(object({
    path             = string
    timestamp_format = string
  }))

  default = []
}

variable "log_files" {
  type    = list(string)
  default = []
}

variable "cloudwatch_log_group" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "run_as_user" {
  type    = string
  default = null
}

variable "distro" {
  type = string
}

variable "log_namespace" {
  type = string
}

variable "custom_script" {
  type    = string
  default = ""
}

variable "arch" {
  type    = string
  default = "amd64"
}
