output "s3_bucket" {
  value       = aws_s3_bucket.bucket.id
  description = "Name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN of the S3 bucket"
}

output "role_guardduty_role_arn" {
  value       = aws_iam_role.guardduty_role.arn
  description = "ARN of the IAM GuardDuty role"
}

output "role_s3_role_arn" {
  value       = aws_iam_role.website_access_role.arn
  description = "ARN of the IAM Web Access role"
}

output "guardduty_detector_arn" {
  value       = aws_guardduty_detector.guardduty.arn
  description = "ARN of the GuardDuty detector"
}

output "guardduty_detector_malware_protection_arn" {
  value       = aws_guardduty_malware_protection_plan.protection_plan.arn
  description = "ARN of the GuardDuty Malware Protection Plan"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.guardduty_sns_topic.arn
  description = "ARN of the SNS topic"
}

output "sns_topic_subscription_arn" {
  value       = aws_sns_topic_subscription.guardduty_sns_topic_subscription.arn
  description = "ARN of the SNS topic subscription"
}
