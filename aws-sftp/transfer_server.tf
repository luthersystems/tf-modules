data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

module "luthername_transfer_server_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "role"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role" "transfer_server" {
  name               = "${module.luthername_transfer_server_role.names[0]}"
  assume_role_policy = "${data.aws_iam_policy_document.transfer_assume_role.json}"

  tags = {
    Name         = "${module.luthername_transfer_server_role.names[0]}"
    Project      = "${module.luthername_transfer_server_role.luther_project}"
    Environment  = "${module.luthername_transfer_server_role.luther_env}"
    Organization = "${module.luthername_transfer_server_role.org_name}"
    Component    = "${module.luthername_transfer_server_role.component}"
    Resource     = "${module.luthername_transfer_server_role.resource}"
    ID           = "${module.luthername_transfer_server_role.ids[0]}"
  }
}

data "aws_iam_policy_document" "transfer_server" {
  statement {
    sid       = "InvokeAuthAPI"
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_stage.transfer_auth.execution_arn}/GET/*"]
  }

  statement {
    sid       = "GetAuthAPI"
    actions   = ["apigateway:GET"]
    resources = ["${aws_api_gateway_rest_api.transfer_auth.execution_arn}"]
  }
}

resource "aws_iam_role_policy" "transfer_server" {
  name   = "transfer-server"
  role   = "${aws_iam_role.transfer_server.id}"
  policy = "${data.aws_iam_policy_document.transfer_server.json}"
}

module "luthername_transfer_server_logging_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "role"
  subcomponent   = "logging"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role" "transfer_server_logging" {
  name               = "${module.luthername_transfer_server_logging_role.names[0]}"
  assume_role_policy = "${data.aws_iam_policy_document.transfer_assume_role.json}"

  tags = {
    Name         = "${module.luthername_transfer_server_logging_role.names[0]}"
    Project      = "${module.luthername_transfer_server_logging_role.luther_project}"
    Environment  = "${module.luthername_transfer_server_logging_role.luther_env}"
    Organization = "${module.luthername_transfer_server_logging_role.org_name}"
    Component    = "${module.luthername_transfer_server_logging_role.component}"
    Subcomponent = "${module.luthername_transfer_server_logging_role.subcomponent}"
    Resource     = "${module.luthername_transfer_server_logging_role.resource}"
    ID           = "${module.luthername_transfer_server_logging_role.ids[0]}"
  }
}

data "aws_iam_policy_document" "transfer_server_logging" {
  statement {
    sid = "AllowLogging"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "transfer_server_logging" {
  name   = "transfer-server-logging"
  role   = "${aws_iam_role.transfer_server_logging.id}"
  policy = "${data.aws_iam_policy_document.transfer_server_logging.json}"
}

module "luthername_transfer_server" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "ts"

  providers = {
    template = "template"
  }
}

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "API_GATEWAY"
  url                    = "${aws_api_gateway_stage.transfer_auth.invoke_url}"
  invocation_role        = "${aws_iam_role.transfer_server.arn}"
  logging_role           = "${aws_iam_role.transfer_server_logging.arn}"

  tags = {
    Name         = "${module.luthername_transfer_server.names[0]}"
    Project      = "${module.luthername_transfer_server.luther_project}"
    Environment  = "${module.luthername_transfer_server.luther_env}"
    Organization = "${module.luthername_transfer_server.org_name}"
    Component    = "${module.luthername_transfer_server.component}"
    Resource     = "${module.luthername_transfer_server.resource}"
    ID           = "${module.luthername_transfer_server.ids[0]}"
  }
}

output "transfer_server_endpoint" {
  value = "${aws_transfer_server.sftp.endpoint}"
}
