variable "luther_project" {
  type = string
}

variable "luther_env" {
  type = string
}

variable "org_name" {
  type    = string
  default = ""
}

variable "component" {
  type = string

  # a default component is defined in this module because it will typically
  # be "bastion" 
  default = "bastion"
}

variable "aws_instance_type" {
  type = string
}

variable "aws_ami" {
  type = string
}

variable "root_volume_size_gb" {
  type    = string
  default = "8"
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_ids" {
  type = list(string)
}

variable "aws_availability_zones" {
  type = list(string)

  description = <<EOF
The availability zones in which to create each instance's persistant storage
volume.  The list of availability zones must be passed as a list, instead of
being inferred internally using data sources, to provide backwards
compatability if AWS adds a new AZ to a region.

NOTE:  The entries of aws_availability_zones must match the availability zone
of the subnet referenced by the corresponding entry of list variable
aws_subnet_ids.  The availability zones are passed as a separate list to avoid
making storage volumes dependent on subnets (i.e. The subnets can be destroyed
without destroying the data volumes).
EOF

}

variable "ssh_port" {
  type    = string
  default = "2222"
}

variable "ssh_whitelist_ingress" {
  type    = list(string)
  default = []
}

variable "prometheus_server_security_group_id" {
  type = string
}

variable "prometheus_node_exporter_metrics_port" {
  type    = string
  default = "9111"
}

variable "authorized_key_sync_metrics_port" {
  type    = string
  default = "9112"
}

variable "authorized_key_sync_s3_bucket_arn" {
  type = string
}

variable "authorized_key_sync_s3_key_prefix" {
  type    = string
  default = "/"
}

variable "aws_kms_key_arns" {
  type        = list(string)
  description = "KMS used to encrypt objects in the buckets accessed by the ASG"
}

#variable "project_static_asset_s3_bucket_arn" {
#   type = "string"
#}

variable "common_static_asset_s3_bucket_arn" {
  type = string
}

variable "aws_cloudwatch_alarm_actions_enabled" {
  type    = string
  default = "true"
}

variable "aws_autorecovery_sns_arn" {
  type = string
}

variable "aws_autorecovery_arn" {
  type = string
}

variable "aws_autorestart_arn" {
  type = string
}
