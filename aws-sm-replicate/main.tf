data "aws_iam_policy_document" "codebuild_sm_replicate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_sm_replicate" {
  name = "codebuild-sm-replicate"

  assume_role_policy = data.aws_iam_policy_document.codebuild_sm_replicate_assume_role.json
}

data "aws_iam_policy_document" "codebuild_sm_replicate" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]
    resources = [var.source_kms_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [var.replica_kms_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.replica_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codebuild_sm_replicate" {
  name   = "codebuild-sm-replicate-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.codebuild_sm_replicate.json
}

resource "aws_iam_role_policy_attachment" "codebuild_sm_replicate" {
  role       = aws_iam_role.codebuild_sm_replicate.name
  policy_arn = aws_iam_policy.codebuild_sm_replicate.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_sm_replicate_sm_rw" {
  role       = aws_iam_role.codebuild_sm_replicate.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}


module "luthername_codebuild_sm_replicate" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  subcomponent   = "dr"
  resource       = "sm"
  id             = "427e"
}

resource "aws_codebuild_project" "sm_replicate" {
  name          = module.luthername_codebuild_sm_replicate.name
  description   = "Replicate SM containers across regions"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_sm_replicate.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "SM_TARGET_REGION"
      value = var.replica_region
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "SM_TARGET_KMS_ARN"
      value = var.replica_kms_arn
      type  = "PLAINTEXT"
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "sm_replicate"
      stream_name = module.luthername_codebuild_sm_replicate.name
    }
  }

  tags = module.luthername_codebuild_sm_replicate.tags

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/replicate_buildspec.yaml")
  }

}

data "aws_iam_policy_document" "event_sm_replicate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_sm_replicate" {
  name = "event-sm-replicate"

  assume_role_policy = data.aws_iam_policy_document.event_sm_replicate_assume_role.json
}

data "aws_iam_policy_document" "event_sm_replicate" {
  statement {
    actions = [
      "codebuild:StartBuild"
    ]

    resources = [
      "${aws_codebuild_project.sm_replicate.arn}",
    ]
  }
}

resource "aws_iam_policy" "event_sm_replicate" {
  name   = "event-sm-replicate-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.event_sm_replicate.json
}

resource "aws_iam_role_policy_attachment" "event_sm_replicate" {
  role       = aws_iam_role.event_sm_replicate.name
  policy_arn = aws_iam_policy.event_sm_replicate.arn
}

resource "aws_cloudwatch_event_target" "sm_replicate" {
  target_id = "sm-replicate"
  rule      = aws_cloudwatch_event_rule.sm_replicate.name
  arn       = aws_codebuild_project.sm_replicate.arn
  role_arn  = aws_iam_role.event_sm_replicate.arn

  input_transformer {
    input_paths = {
      awsRegion  = "$.region"
      eventName  = "$.detail.eventName"
      secretId   = "$.detail.requestParameters.secretId"
      secretName = "$.detail.requestParameters.name"
    }

    input_template = file("${path.module}/event_input_template.json")
  }
}

module "luthername_event_sm_replicate" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  subcomponent   = "sm-replicate-"
  resource       = "event-rule"
  id             = "b204"
}

resource "aws_cloudwatch_event_rule" "sm_replicate" {
  name        = module.luthername_event_sm_replicate.name
  description = "Capture all Secrets Managerevents"

  event_pattern = file("${path.module}/event_pattern.json")

  tags = module.luthername_event_sm_replicate.tags
}

