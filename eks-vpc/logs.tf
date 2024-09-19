module "luthername_logs" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "logs"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = module.luthername_logs.name
  retention_in_days = var.aws_cloudwatch_retention_days
  tags              = module.luthername_logs.tags
}

output "aws_cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.main.arn
}

module "luthername_logs_subscription_filter" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "logs"
  subcomponent   = "sub"
}

resource "aws_cloudwatch_log_subscription_filter" "level_error" {
  count           = var.aws_cloudwatch_log_subscription_filter_lambda_arn == "" ? 0 : 1
  name            = module.luthername_logs_subscription_filter.name
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = "?\"panic.go\" ?\"level=fatal\" ?\"level=panic\" ?\"level=error\" ?\"level=warn\" ?\"ERROR\" ?\"WARN\" ?\"FATAL\" ?\"CRITICAL\" ?\"NOTICE\" ?\"PANIC\""
  destination_arn = var.aws_cloudwatch_log_subscription_filter_lambda_arn
  distribution    = "ByLogStream"
}

#
# fluent bit
#

resource "random_string" "fluentbit" {
  length  = 4
  upper   = false
  special = false
}

module "fluentbit_service_account_iam_role" {
  count = local.logs ? 1 : 0

  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "mon"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "aws-for-fluent-bit"
  k8s_namespace      = "kube-system"
  add_policy         = true
  policy             = data.aws_iam_policy_document.mon_fluentbit[0].json
  id                 = random_string.fluentbit.result
}

locals {
  logs = var.logs || local.monitoring

  fluentbit_service_account_role_arn = try(module.fluentbit_service_account_iam_role[0].arn, "")
}

output "fluentbit_service_account_role_arn" {
  value = local.fluentbit_service_account_role_arn
}

data "aws_iam_policy_document" "mon_fluentbit" {
  count = local.logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "${aws_cloudwatch_log_group.main.arn}:log-stream:*"
    ]
  }
}
