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
  # Configure transformer to convert event to SNS message
  input_transformer {
    input_paths = {
      severity            = "$.detail.severity",
      Account_ID          = "$.detail.accountId",
      Finding_ID          = "$.detail.id",
      Finding_Type        = "$.detail.type",
      region              = "$.region",
      Finding_description = "$.detail.description"
    }

    input_template = <<EOF
      {
          "account_id": <Account_ID>,
          "severity": <severity>,
          "finding_id": <Finding_ID>,
          "finding_type": <Finding_Type>,
          "finding_description": <Finding_description>,
          "region": <region>
      }
    EOF
  }
}
