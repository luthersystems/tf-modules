data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

module "luthername_lambda_role" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "mon"
  resource       = "role"
  subcomponent   = "logstoslack"

  providers = {
    template = template
  }
}

resource "aws_iam_role" "lambda" {
  name               = module.luthername_lambda_role.names[0]
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name         = module.luthername_lambda_role.names[count.index]
    Project      = module.luthername_lambda_role.luther_project
    Environment  = module.luthername_lambda_role.luther_env
    Organization = module.luthername_lambda_role.org_name
    Component    = module.luthername_lambda_role.component
    Subcomponent = module.luthername_lambda_role.subcomponent
    Resource     = module.luthername_lambda_role.resource
    ID           = module.luthername_lambda_role.ids[count.index]
  }
}

data "aws_iam_policy_document" "lambda" {
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
    sid     = "GetSlackWebHookSecret"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      var.web_hook_url_secret_arn,
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

    resources = [data.aws_kms_key.secret.arn]
  }
}

data "aws_kms_key" "secret" {
  key_id = var.secret_kms_key_id
}

resource "aws_iam_role_policy" "lambda" {
  name   = "lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

module "luthername_lambda" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "mon"
  resource       = "lambda"
  subcomponent   = "logstoslack"

  providers = {
    template = template
  }
}

locals {
  lambda_zip = "${path.module}/files/lambda.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/files/index.js"
  output_path = local.lambda_zip
}

resource "aws_lambda_function" "main" {
  function_name    = module.luthername_lambda.names[0]
  filename         = local.lambda_zip
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs8.10"

  tags = {
    Name         = module.luthername_lambda.names[count.index]
    Project      = module.luthername_lambda.luther_project
    Environment  = module.luthername_lambda.luther_env
    Organization = module.luthername_lambda.org_name
    Component    = module.luthername_lambda.component
    Subcomponent = module.luthername_lambda.subcomponent
    Resource     = module.luthername_lambda.resource
    ID           = module.luthername_lambda.ids[count.index]
  }

  environment {
    variables = {
      minSeverityLevel       = var.min_severity_level
      slackChannel           = var.slack_channel
      webHookUrlSecretId     = var.web_hook_url_secret_arn
      webHookUrlSecretRegion = var.web_hook_url_secret_region == "" ? var.aws_region : var.web_hook_url_secret_region
    }
  }
}

output "function_arn" {
  value = aws_lambda_function.main.arn
}

module "luthername_lambda_permissions" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "mon"
  resource       = "fnperm"
  subcomponent   = "logstoslack"

  providers = {
    template = template
  }
}

resource "aws_lambda_permission" "main" {
  statement_id   = module.luthername_lambda_permissions.names[0]
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.main.arn
  principal      = "logs.${var.aws_region}.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
