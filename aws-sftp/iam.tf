module "luthername_transfer_server_user_role" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "role"
  subcomponent   = "s3"

  providers = {
    template = "template"
  }
}

resource "aws_iam_role" "transfer_server_user" {
  name               = "${module.luthername_transfer_server_user_role.names[0]}"
  assume_role_policy = "${data.aws_iam_policy_document.transfer_assume_role.json}"

  tags = {
    Name         = "${module.luthername_transfer_server_user_role.names[0]}"
    Project      = "${module.luthername_transfer_server_user_role.luther_project}"
    Environment  = "${module.luthername_transfer_server_user_role.luther_env}"
    Organization = "${module.luthername_transfer_server_user_role.org_name}"
    Component    = "${module.luthername_transfer_server_user_role.component}"
    Subcomponent = "${module.luthername_transfer_server_logging_role.subcomponent}"
    Resource     = "${module.luthername_transfer_server_user_role.resource}"
    ID           = "${module.luthername_transfer_server_user_role.ids[0]}"
  }
}

data "aws_iam_policy_document" "transfer_server_user_s3" {
  statement {
    sid = "AllowListingOfUserFolder"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = ["${module.aws_s3_bucket_sftp.arn}"]
  }

  statement {
    sid = "HomeDirObjectAccess"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObjectVersion",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
    ]

    resources = ["${formatlist("${module.aws_s3_bucket_sftp.arn}/%s", var.bucket_prefix_patterns)}"]
  }

  statement {
    sid = "AllowFileKMSEncryptDecrypt"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt",
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "s3.${var.aws_region}.amazonaws.com",
      ]
    }

    resources = ["${var.bucket_kms_key_arn}"]
  }
}

resource "aws_iam_role_policy" "transfer_server_user" {
  name   = "s3-access"
  role   = "${aws_iam_role.transfer_server_user.id}"
  policy = "${data.aws_iam_policy_document.transfer_server_user_s3.json}"
}

output "sftp_user_role" {
  value = "${aws_iam_role.transfer_server_user.arn}"
}
