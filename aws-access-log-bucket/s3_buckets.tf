module "luthername_s3_bucket_logs" {
  source                = "../luthername"
  luther_project        = "${var.luther_project}"
  aws_region            = "${var.aws_region}"
  aws_region_short_code = "${var.aws_region_short_code}"
  luther_env            = "${var.luther_env}"
  component             = "${var.component}"
  resource              = "s3"
  id                    = "${var.random_identifier}"
}

data "template_file" "aws_s3_bucket_logs_name_full" {
  template = "luther-${module.luthername_s3_bucket_logs.names[0]}"
}

# NOTE:  We define a template containing the ARN for resource
# aws_s3_bucket.logs because we need to reference the bucket in the policy
# document which is passed in during the bucket's creation.
data "template_file" "aws_s3_bucket_logs_arn" {
  template = "arn:aws:s3:::$${bucket}"

  vars {
    bucket = "${data.template_file.aws_s3_bucket_logs_name_full.rendered}"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "luther-${module.luthername_s3_bucket_logs.names[0]}"
  acl    = "private"
  region = "${var.aws_region}"

  versioning {
    enabled = true

    #mfa_delete = true
  }

  policy = "${data.aws_iam_policy_document.logs_alb.json}"

  lifecycle_rule {
    prefix  = "access_logs/"
    enabled = true

    expiration {
      days = 30

      # Because we have versioning on the bucket we need to delete
      # "expired object delete markers". See the following link for
      # more information:
      # http://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-configuration-examples.html#lifecycle-config-conceptual-ex8
      # This is needed in addition to noncurrent_version_expiration to
      # completely remove a key from the bucket.
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = 60
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${var.aws_kms_key_arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "luther-${module.luthername_s3_bucket_logs.names[0]}"
    Project     = "${module.luthername_s3_bucket_logs.luther_project}"
    Environment = "${module.luthername_s3_bucket_logs.luther_env}"
    Component   = "${module.luthername_s3_bucket_logs.component}"
    Resource    = "${module.luthername_s3_bucket_logs.resource}"
    ID          = "${module.luthername_s3_bucket_logs.ids[0]}"
  }
}

module "luthername_policy_logs_alb" {
  source                = "../luthername"
  luther_project        = "${var.luther_project}"
  aws_region            = "${var.aws_region}"
  aws_region_short_code = "${var.aws_region_short_code}"
  luther_env            = "${var.luther_env}"
  component             = "${var.component}"
  resource              = "policy"
  subcomponent          = "alb"
}

module "luthername_statement_logs_alb" {
  source                = "../luthername"
  luther_project        = "${var.luther_project}"
  aws_region            = "${var.aws_region}"
  aws_region_short_code = "${var.aws_region_short_code}"
  luther_env            = "${var.luther_env}"
  component             = "${var.component}"
  resource              = "sid"
  subcomponent          = "alb"
}

# Allow the AWS account which operates ALBs to write access logs
# aws_s3_bucket.logs.
data "aws_iam_policy_document" "logs_alb" {
  policy_id = "${module.luthername_policy_logs_alb.names[0]}"

  statement {
    sid    = "${module.luthername_statement_logs_alb.names[0]}"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    # This is a bit permissive, but several environments will have their
    # access logs written under this root key prefix.
    resources = [
      "${data.template_file.aws_s3_bucket_logs_arn.rendered}/access_logs/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${data.template_file.aws_account_alb_access_logs.rendered}",
      ]
    }
  }
}

data "template_file" "aws_account_alb_access_logs" {
  template = "arn:aws:iam::$${account_number}:root"

  vars {
    account_number = "${var.aws_alb_access_log_accounts[var.aws_region]}"
  }
}
