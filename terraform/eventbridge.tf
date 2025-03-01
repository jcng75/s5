# NOTE: We will be using the default eventbridge bus
# Create the event rule using
resource "aws_cloudwatch_event_rule" "guardduty_event_rule" {
  name          = "guardduty_severity_rule"
  description   = "Rule that triggers on guardduty finding a dangerous S3 upload"
  event_pattern = file("event_pattern.json")
  tags = {
    "Orchestration" : "Terraform"
  }
}

# Select cloudwatch event target (SNS) triggered by the event rule
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_event_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_sns_topic.arn
  role_arn  = aws_iam_role.eventbridge_guardduty_role.arn

  # Configure transformer to convert event to SNS message
  input_transformer {
    input_paths = {
      "Account_ID" : "$.detail.AccountId",
      "Finding_ID" : "$.detail.Id",
      "Finding_Type" : "$.detail.Type",
      "Finding_description" : "$.detail.Description",
      "region" : "$.Region",
      "severity" : "$.detail.Severity",
      "title" : "$.detail.Title"
    }

    input_template = <<TEMPLATE
"<title>"
"AWS <Account_ID> has a severity <severity> GuardDuty finding type <Finding_Type> in the <region> region."
"Finding Description:"
"<Finding_description>. "
"For more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>"
  TEMPLATE
  }
}

resource "aws_cloudwatch_event_bus_policy" "guardduty_event_bus_policy" {
  event_bus_name = data.aws_cloudwatch_event_bus.event_bus.name
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
        Resource = data.aws_cloudwatch_event_bus.event_bus.arn
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

  tags = {
    "Orchestration" : "Terraform"
  }
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
