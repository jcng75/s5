# Create the event bus
resource "aws_cloudwatch_event_bus" "event_bus" {
  name = "guardduty_event_bus"
}

# Create the event rule
resource "aws_cloudwatch_event_rule" "guardduty_event_rule" {
  name           = "guardduty_severity_rule"
  description    = "Rule that triggers on guardduty finding a dangerous S3 upload"
  event_pattern  = file("event_pattern.json")
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
}

# Select cloudwatch event target (SNS) triggered by the event rule
resource "aws_cloudwatch_event_target" "sns" {
  rule           = aws_cloudwatch_event_rule.guardduty_event_rule.name
  target_id      = "SendToSNS"
  arn            = aws_sns_topic.guardduty_sns_topic.arn
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  role_arn       = aws_iam_role.eventbridge_guardduty_role.arn

  # Configure transformer to convert event to SNS message
  input_transformer {
    input_paths = {
      "severity" : "$.detail.severity",
      "Account_ID" : "$.detail.accountId",
      "Finding_ID" : "$.detail.id",
      "Finding_Type" : "$.detail.type",
      "region" : "$.region",
      "Finding_description" : "$.detail.description"
    }

    input_template = "{\"default\": \"GuardDuty Finding\", \"severity\": <severity>, \"Account_ID\": <Account_ID>, \"Finding_ID\": <Finding_ID>, \"Finding_Type\": <Finding_Type>, \"region\": <region>, \"Finding_description\": <Finding_description>}"
  }
}

resource "aws_cloudwatch_event_bus_policy" "guardduty_event_bus_policy" {
  event_bus_name = aws_cloudwatch_event_bus.event_bus.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowGuardDuty"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com",
        }
        Action   = ["events:PutEvents"]
        Resource = aws_cloudwatch_event_bus.event_bus.arn
      }
    ]
  })
}

resource "aws_iam_role" "eventbridge_guardduty_role" {
  name = "eventbridge_guardduty_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "EventBridgeInvokeSNS"
  role = aws_iam_role.eventbridge_guardduty_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.guardduty_sns_topic.arn
      }
    ]
  })
}
