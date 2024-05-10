resource "aws_route53_zone" "main" {
  count = var.create_dns ? 1 : 0 # Only create the resource if var.create_dns is true
  name  = var.domain
}

output "domain" {
  value = var.create_dns ? var.domain : ""
}

output "aws_route53_zone_name_servers" {
  value       = var.create_dns ? aws_route53_zone.main[0].name_servers : []
  description = "The name servers for the DNS zone. Available only when the zone is created."
}

output "zone_id" {
  value       = var.create_dns ? aws_route53_zone.main[0].zone_id : ""
  description = "The Zone ID for the DNS zone. Available only when the zone is created."
}
