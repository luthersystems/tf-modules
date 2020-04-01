locals {
  organization = var.org_name == "" ? null : var.org_name
  subcomponent = var.subcomponent == "" ? null : var.subcomponent
}

output "id" {
  value = local.id
}

output "ids" {
  value = local.ids
}

output "name" {
  value = local.name
}

output "names" {
  value = local.names
}

output "luther_project" {
  value = var.luther_project
}

output "aws_region" {
  value = var.aws_region
}

output "luther_env" {
  value = var.luther_env
}

output "org_name" {
  value = local.organization
}

output "component" {
  value = var.component
}

output "subcomponent" {
  value = local.subcomponent
}

output "resource" {
  value = var.resource
}

output "replication" {
  value = var.replication
}

output "tags" {
  value = {
    Name         = local.name
    Project      = var.luther_project
    Environment  = var.luther_env
    Organization = local.organization
    Component    = var.component
    Subcomponent = local.subcomponent
    Resource     = var.resource
    ID           = local.id
  }
}
