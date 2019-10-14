module "luthername_logs" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "logs"

  providers = {
    template = "template"
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${module.luthername_logs.names[count.index]}"
  retention_in_days = 90

  tags = {
    Name         = "${module.luthername_logs.names[count.index]}"
    Project      = "${module.luthername_logs.luther_project}"
    Environment  = "${module.luthername_logs.luther_env}"
    Organization = "${module.luthername_logs.org_name}"
    Component    = "${module.luthername_logs.component}"
    Resource     = "${module.luthername_logs.resource}"
    ID           = "${module.luthername_logs.ids[count.index]}"
  }
}

output "aws_cloudwatch_log_group" {
  value = "${aws_cloudwatch_log_group.main.arn}"
}

module "luthername_logs_subscription_filter" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "logs"
  subcomponent   = "sub"

  providers = {
    template = "template"
  }
}

resource "aws_cloudwatch_log_subscription_filter" "level_error" {
  name            = "${module.luthername_logs_subscription_filter.names[count.index]}"
  log_group_name  = "${aws_cloudwatch_log_group.main.name}"
  filter_pattern  = "?\"panic.go\" ?\"level=fatal\" ?\"level=panic\" ?\"level=error\" ?\"level=warn\" ?\"ERROR\" ?\"WARN\" ?\"FATAL\" ?\"CRITICAL\" ?\"NOTICE\" ?\"PANIC\""
  destination_arn = "${var.aws_cloudwatch_log_subscription_filter_lambda_arn}"
  distribution    = "ByLogStream"

  depends_on = ["aws_lambda_permission.cloudwatch_subscription_filter"]
}

module "luthername_cloudwatch_logs_lambda_permissions" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "fnperm"
  subcomponent   = "logs"

  providers = {
    template = "template"
  }
}

resource "aws_lambda_permission" "cloudwatch_subscription_filter" {
  statement_id   = "${module.luthername_cloudwatch_logs_lambda_permissions.names[0]}"
  action         = "lambda:InvokeFunction"
  function_name  = "${var.aws_cloudwatch_log_subscription_filter_lambda_arn}"
  principal      = "logs.${var.aws_region}.amazonaws.com"
  source_arn     = "${aws_cloudwatch_log_group.main.arn}"
  source_account = "${var.aws_account_id}"

  provider = "aws.cloudwatch"
}
