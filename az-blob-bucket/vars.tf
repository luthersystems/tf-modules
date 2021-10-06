variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "component" {
  type    = string
  default = ""
}

variable "random_identifier" {
  type        = string
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
  default     = ""
}

variable "resource_group" {
  type = string
}

variable "az_location" {
  type = string
}

variable "blob_delete_retention_days" {
  default = 7
}

variable "container_delete_retention_days" {
  default = 7
}

variable "subnet_id" {
  default = ""
}
