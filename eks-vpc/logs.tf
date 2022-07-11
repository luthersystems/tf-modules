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
