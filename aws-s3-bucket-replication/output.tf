output "bucket" {
  value = module.aws_s3_bucket.bucket
}

output "arn" {
  value = module.aws_s3_bucket.arn
}

output "bucket_replica" {
  value = module.aws_s3_bucket_replica.bucket
}

output "arn_replica" {
  value = module.aws_s3_bucket_replica.arn
}
