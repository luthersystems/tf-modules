output "ids" {
  value = data.template_file.id.*.rendered
}

output "names" {
  value = data.template_file.name.*.rendered
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
  value = var.org_name
}

output "component" {
  value = var.component
}

output "subcomponent" {
  value = var.subcomponent
}

output "resource" {
  value = var.resource
}

output "replication" {
  value = var.replication
}
