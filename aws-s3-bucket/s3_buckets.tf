module "luthername_s3_bucket" {
  source                = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project        = "${var.luther_project}"
  aws_region            = "${var.aws_region}"
  aws_region_short_code = "${var.aws_region_short_code}"
  luther_env            = "${var.luther_env}"
  component             = "${var.component}"
  resource              = "s3"
  id                    = "${var.random_identifier}"

  providers = {
    template = "template"
  }
}

data "template_file" "aws_s3_bucket_name_full" {
  template = "luther-${module.luthername_s3_bucket.names[0]}"
}

# NOTE:  We define a template containing the ARN for resource
# aws_s3_bucket.bucket because we need to reference the bucket in the policy
# document which is passed in during the bucket's creation.
data "template_file" "aws_s3_bucket_arn" {
  template = "arn:aws:s3:::$${bucket}"

  vars {
    bucket = "${data.template_file.aws_s3_bucket_name_full.rendered}"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "luther-${module.luthername_s3_bucket.names[0]}"
  acl    = "private"
  region = "${var.aws_region}"

  versioning {
    enabled = true

    #mfa_delete = true
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
    Name        = "luther-${module.luthername_s3_bucket.names[0]}"
    Project     = "${module.luthername_s3_bucket.luther_project}"
    Environment = "${module.luthername_s3_bucket.luther_env}"
    Component   = "${module.luthername_s3_bucket.component}"
    Resource    = "${module.luthername_s3_bucket.resource}"
    ID          = "${module.luthername_s3_bucket.ids[0]}"
  }
}
