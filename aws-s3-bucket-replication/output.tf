output "bucket" {
  value = module.aws_s3_bucket.bucket
}

output "arn" {
  value = module.aws_s3_bucket.arn
}

output "bucket_regional_domain_name" {
  value = module.aws_s3_bucket.bucket_regional_domain_name
}

output "bucket_regional_domain_name_replica" {
  value = module.aws_s3_bucket_replica.bucket_regional_domain_name
}

output "bucket_replica" {
  value = module.aws_s3_bucket_replica.bucket
}

output "arn_replica" {
  value = module.aws_s3_bucket_replica.arn
}
