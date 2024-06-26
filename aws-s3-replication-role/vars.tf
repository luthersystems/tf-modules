variable "aws_region" {
  type = string
}

variable "aws_region_dr" {
  type = string
}

variable "luther_project" {
  type = string
}

variable "luther_env" {
  type = string
}

variable "component" {
  type = string
}

variable "random_identifier" {
  description = "A randomly generated string to mitigate namespace sniffing globally defined IAM role names"
  default     = ""
}

variable "bucket_source_arns" {
  type = list(string)
}

variable "bucket_destination_arns" {
  type = list(string)
}

variable "source_kms_key_ids" {
  type = list(string)
}

variable "destination_kms_key_ids" {
  type = list(string)
}
