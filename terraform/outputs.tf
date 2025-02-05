output "s3_bucket" {
  value       = aws_s3_bucket.bucket.id
  description = "Name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN of the S3 bucket"
}

output "role_policy_arn" {
  value       = aws_iam_policy.s3_access_policy.arn
  description = "ARN of the IAM policy"
}
