variable "aws_region" {
  default = "eu-west-2"
}

variable "aws_region_replica" {
  default = "eu-west-1"
}

variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "component" {
  type    = string
  default = "logs"
}

variable "component_replica" {
  default = ""
}

variable "random_identifier" {
  type        = string
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
  default     = ""
}

variable "random_identifier_replica" {
  type        = string
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
  default     = ""
}

variable "aws_kms_key_arn" {
  type        = string
  description = "The KMS key to encrypt the bucket"
  default     = ""
}

variable "aws_kms_key_arn_replica" {
  type        = string
  description = "Destination kms key arn for S3 bucket replication"
  default     = ""
}

variable "lifecycle_rules" {
  type = list(map(string))

  default = []
}

variable "lifecycle_rules_replica" {
  type = list(map(string))

  default = []
}

variable "force_destroy" {
  default = false
}

variable "replicate_deletes" {
  default = false
}
