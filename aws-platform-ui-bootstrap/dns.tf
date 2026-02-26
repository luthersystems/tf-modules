module "luthername_dns_zone" {
  source         = "../luthername"
  count          = var.create_dns ? 1 : 0
  luther_project = var.project
  aws_region     = local.region
  luther_env     = var.env
  org_name       = var.org_name
  component      = "dns"
  resource       = "zone"
}

resource "aws_route53_zone" "main" {
  count = var.create_dns ? 1 : 0
  name  = var.domain
  tags  = module.luthername_dns_zone[0].tags
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
