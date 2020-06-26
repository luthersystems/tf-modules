data "aws_iam_policy_document" "codebuild_ecr_replicate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_ecr_replicate" {
  name = "codebuild-ecr-replicate"

  assume_role_policy = data.aws_iam_policy_document.codebuild_ecr_replicate_assume_role.json
}

data "aws_iam_policy_document" "codebuild_ecr_replicate" {
  statement {
    actions = [
      "ecr:CreateRepository",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "codebuild_ecr_replicate" {
  name   = "codebuild-ecr-replicate-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.codebuild_ecr_replicate.json
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_replicate" {
  role       = aws_iam_role.codebuild_ecr_replicate.name
  policy_arn = aws_iam_policy.codebuild_ecr_replicate.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_replicate_ecr_power_user" {
  role       = aws_iam_role.codebuild_ecr_replicate.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_replicate_ssm_ro" {
  role       = aws_iam_role.codebuild_ecr_replicate.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

module "luthername_codebuild_ecr_replicate" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=v23.1.1"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  subcomponent   = "dr"
  resource       = "ecr"
  id             = "desu"

  providers = {
    template = template
  }
}

resource "aws_codebuild_project" "ecr_replicate" {
  name          = module.luthername_codebuild_ecr_replicate.name
  description   = "Replicate ECR containers across regions"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_ecr_replicate.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_TARGET_REGIONS"
      value = join(",", var.replica_regions)
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "ecr_replicate"
      stream_name = module.luthername_codebuild_ecr_replicate.name
    }
  }

  tags = module.luthername_codebuild_ecr_replicate.tags

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/ecr_replicate_buildspec.yaml")
  }

}

data "aws_iam_policy_document" "event_ecr_replicate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_ecr_replicate" {
  name = "event-ecr-replicate"

  assume_role_policy = data.aws_iam_policy_document.event_ecr_replicate_assume_role.json
}

data "aws_iam_policy_document" "event_ecr_replicate" {
  statement {
    actions = [
      "codebuild:StartBuild"
    ]

    resources = [
      "${aws_codebuild_project.ecr_replicate.arn}",
    ]
  }
}

resource "aws_iam_policy" "event_ecr_replicate" {
  name   = "event-ecr-replicate-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.event_ecr_replicate.json
}

resource "aws_iam_role_policy_attachment" "event_ecr_replicate" {
  role       = aws_iam_role.event_ecr_replicate.name
  policy_arn = aws_iam_policy.event_ecr_replicate.arn
}

resource "aws_cloudwatch_event_target" "ecr_replicate" {
  target_id = "ecr-replicate"
  rule      = aws_cloudwatch_event_rule.ecr_replicate.name
  arn       = aws_codebuild_project.ecr_replicate.arn
  role_arn  = aws_iam_role.event_ecr_replicate.arn

  input_transformer {
    input_paths = {
      awsRegion  = "$.region"
      imageTag   = "$.detail.image-tag"
      registryId = "$.account"
      repoName   = "$.detail.repository-name"
    }

    input_template = file("${path.module}/event_input_template.json")
  }
}

module "luthername_event_ecr_replicate" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=v23.1.1"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  subcomponent   = "replicate-region-"
  resource       = "event-rule"
  id             = "471c"

  providers = {
    template = template
  }
}

resource "aws_cloudwatch_event_rule" "ecr_replicate" {
  name        = module.luthername_event_ecr_replicate.name
  description = "Capture all ECR push success events"

  event_pattern = file("${path.module}/event_pattern.json")

  tags = module.luthername_event_ecr_replicate.tags
}

