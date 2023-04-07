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

  # This default is the Luther Systems default KMS key for S3 buckets defined
  # in the common-infrastructure repository.
  default = "arn:aws:kms:eu-west-2:967058059066:key/4cf1dd96-7fd0-4d76-8cc6-4d991d6b27cf"
}

variable "aws_kms_key_arn_replica" {
  type        = string
  default     = "arn:aws:kms:eu-west-1:967058059066:key/ee234280-7ff2-4289-80a1-5301051c7da8"
  description = "Destination kms key arn for S3 bucket replication"
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
