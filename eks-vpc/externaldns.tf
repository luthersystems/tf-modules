module "externaldns_public_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = var.component

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "external-dns-public"
  k8s_namespace      = "external-dns"
  add_policy         = true
  policy             = data.aws_iam_policy_document.externaldns.json

  providers = {
    aws      = aws
    template = template
  }
}

output "externaldns_public_service_account_role_arn" {
  value = module.externaldns_public_service_account_iam_role.arn
}

module "externaldns_private_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = var.component

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "external-dns-private"
  k8s_namespace      = "external-dns"
  add_policy         = true
  policy             = data.aws_iam_policy_document.externaldns.json

  providers = {
    aws      = aws
    template = template
  }
}

output "externaldns_private_service_account_role_arn" {
  value = module.externaldns_private_service_account_iam_role.arn
}

# See the externaldns docs regarding its required IAM policy:
#   https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
data "aws_iam_policy_document" "externaldns" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListTagsForResource",
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }
}
