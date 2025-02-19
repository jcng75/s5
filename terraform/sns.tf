resource "aws_sns_topic" "guardduty_sns_topic" {
  name = "guardduty_sns_topic"
}

resource "aws_sns_topic_subscription" "guardduty_sns_topic_subscription" {
  topic_arn = aws_sns_topic.guardduty_sns_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# Ensure this policy only allows EventBridge to publish to the SNS topic
resource "aws_sns_topic_policy" "guardduty_sns_topic_policy" {
  arn = aws_sns_topic.guardduty_sns_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublishFromEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = [aws_sns_topic.guardduty_sns_topic.arn]
      }
    ]
  })
}
