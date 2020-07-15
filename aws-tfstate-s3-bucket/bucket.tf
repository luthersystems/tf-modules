data "template_file" "bucket_name" {
  template = "luther-terraform-$${luther_project}-$${region_short_code}-$${luther_env}-state-s3-$${random_identifier}"

  vars = {
    luther_project    = var.luther_project
    luther_env        = var.luther_env
    region_short_code = var.aws_region_short_code[var.aws_region]
    # This identifier should be random because buckets are in a global
    # (public) namespace.
    random_identifier = var.random_identifier
  }
}

resource "aws_s3_bucket" "state" {
  bucket = data.template_file.bucket_name.rendered
  acl    = "private"
  region = var.aws_region

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
    #mfa_delete = true
  }

  tags = {
    Name        = data.template_file.bucket_name.rendered
    Project     = var.luther_project
    Environment = var.luther_env
    Component   = "state"
    Resource    = "s3"
    # ID matches the Name
    ID = var.random_identifier
  }
}

output "aws_s3_bucket" {
  value = aws_s3_bucket.state.bucket
}
