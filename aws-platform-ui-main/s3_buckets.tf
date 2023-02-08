locals {
  storage_s3_bucket_arn = try(data.aws_s3_bucket.env_static[0].id, "")
}

data "aws_s3_bucket" "env_static" {
  count = var.env_static_s3_bucket != "" ? 1 : 0

  bucket = var.env_static_s3_bucket
}
