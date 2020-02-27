module "luthername_logs" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
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
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
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
}
