data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

module "luthername_transfer_server_lambda_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "role"
  subcomponent   = "lambda"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role" "transfer_lambda" {
  name               = "${module.luthername_transfer_server_lambda_role.names[0]}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"

  tags = {
    Name         = "${module.luthername_transfer_server_lambda_role.names[count.index]}"
    Project      = "${module.luthername_transfer_server_lambda_role.luther_project}"
    Environment  = "${module.luthername_transfer_server_lambda_role.luther_env}"
    Organization = "${module.luthername_transfer_server_lambda_role.org_name}"
    Component    = "${module.luthername_transfer_server_lambda_role.component}"
    Subcomponent = "${module.luthername_transfer_server_lambda_role.subcomponent}"
    Resource     = "${module.luthername_transfer_server_lambda_role.resource}"
    ID           = "${module.luthername_transfer_server_lambda_role.ids[count.index]}"
  }
}

data "aws_iam_policy_document" "transfer_lambda" {
  statement {
    sid = "AllowLogging"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid     = "GetSFTPSecrets"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.secrets_prefix}/*",
    ]
  }

  statement {
    sid     = "DecryptSFTPSecrets"
    actions = ["kms:Decrypt"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }

    resources = ["${var.bucket_kms_key_arn}"]
  }
}

resource "aws_iam_role_policy" "transfer_lambda" {
  name   = "transfer-lambda"
  role   = "${aws_iam_role.transfer_lambda.id}"
  policy = "${data.aws_iam_policy_document.transfer_lambda.json}"
}

module "luthername_transfer_server_lambda" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "lambda"

  providers = {
    template = "template"
  }
}

locals {
  lambda_zip = "${path.module}/files/lambda.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/files/lambda.py"
  output_path = "${local.lambda_zip}"
}

resource "aws_lambda_function" "transfer_auth" {
  function_name    = "${module.luthername_transfer_server_lambda.names[0]}"
  filename         = "${local.lambda_zip}"
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  role             = "${aws_iam_role.transfer_lambda.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python3.7"

  tags = {
    Name         = "${module.luthername_transfer_server_lambda.names[count.index]}"
    Project      = "${module.luthername_transfer_server_lambda.luther_project}"
    Environment  = "${module.luthername_transfer_server_lambda.luther_env}"
    Organization = "${module.luthername_transfer_server_lambda.org_name}"
    Component    = "${module.luthername_transfer_server_lambda.component}"
    Subcomponent = "${module.luthername_transfer_server_lambda.subcomponent}"
    Resource     = "${module.luthername_transfer_server_lambda.resource}"
    ID           = "${module.luthername_transfer_server_lambda.ids[count.index]}"
  }

  environment {
    variables = {
      SecretsManagerRegion = "${var.aws_region}"
      KeyPrefix            = "${var.secrets_prefix}"
    }
  }
}
