resource "aws_acm_certificate" "cert" {
  count = length(var.domain) > 0 ? 1 : 0

  domain_name = var.domain

  subject_alternative_names = ["*.${var.domain}"] # Include wildcard for subdomains
  validation_method         = "DNS"

  tags = {
    Project     = var.luther_project
    Environment = var.luther_env
    Resource    = "acm"
  }
}

data "aws_route53_zone" "zone" {
  count = length(var.domain) > 0 ? 1 : 0
  name  = "${var.domain}."
}


locals {
  cert_validation_options = length(var.domain) > 0 ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  cert_arn = length(var.domain) > 0 ? aws_acm_certificate.cert[0].arn : ""
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.cert_validation_options

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.zone[0].zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = length(var.domain) > 0 ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
