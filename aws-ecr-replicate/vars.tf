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

variable "replica_regions" {
  type = list(string)

  default = [
    "eu-west-1",
    "eu-west-2",
    "eu-central-1",
    "us-west-1"
  ]
}
