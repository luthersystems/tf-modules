output "is_downgrade" {
  description = "Whether the desired Kubernetes major/minor version is lower than the current version."
  value       = local.is_downgrade
}
