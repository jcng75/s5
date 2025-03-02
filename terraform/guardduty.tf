# Enable GuardDuty for S3 logs
resource "aws_guardduty_detector" "guardduty" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
  }

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    "Name"          = "GuardDuty",
    "Orchestration" = "Terraform"
  }
}

resource "aws_guardduty_malware_protection_plan" "protection_plan" {
  depends_on = [aws_iam_role.guardduty_role]
  role       = aws_iam_role.guardduty_role.arn

  protected_resource {
    s3_bucket {
      bucket_name = aws_s3_bucket.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = {
    "Name"          = "GuardDutyMalwareProtectionPlan",
    "Orchestration" = "Terraform"
  }
}
