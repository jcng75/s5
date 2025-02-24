# ALlow only specific user and guardduty to be able to assume role
resource "aws_iam_role" "website_access_role" {
  name = "s3_website_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "UserAssumeRolePolicy"
        Principal = {
          AWS = data.aws_iam_user.user.arn
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "GuardDutyAssumeRolePolicy"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name          = "s3_website_access_role"
    Orchestration = "Terraform"
  }
}

# Policy to allow access to specific S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_website_access_policy"
  description = "Policy to allow access to specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Limit the s3 actions to only the ones needed
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:GetBucketOwnershipControls",
          "s3:ListBucket",
          "s3:PutObjectTagging"
        ]
        Effect = "Allow"
        # Reference the bucket ARN
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      }
    ]
  })

  tags = {
    "Name"          = "s3_website_access_policy"
    "Orchestration" = "Terraform"
  }
}


# Attach policy to role
resource "aws_iam_role_policy_attachment" "s3_role_policy_attachment" {
  role       = aws_iam_role.website_access_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


# Role policy to allow user to assume role
resource "aws_iam_policy" "assume_role_policy" {
  name        = "AllowAssumeRole"
  description = "Policy to allow user to assume a role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.website_access_role.arn
      },
    ]
  })

  tags = {
    "Name"          = "UserAssumeRolePolicy",
    "Orchestration" = "Terraform"
  }
}

# Assigning assumerole policy to user
resource "aws_iam_policy_attachment" "user_role_attachment" {
  name       = "user_role_attachment"
  policy_arn = aws_iam_policy.assume_role_policy.arn
  users      = [data.aws_iam_user.user.user_name]
}

# Create a role for guardduty to assume
resource "aws_iam_role" "guardduty_role" {
  name = "guardduty_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "GuardDutyAssumeRolePolicy",
        Principal = {
          Service = [
            "guardduty.amazonaws.com",
            "malware-protection-plan.guardduty.amazonaws.com"
          ]
        }
      }
  ] })

  tags = {
    Name          = "guardduty_s3_access_role"
    Orchestration = "Terraform"
  }
}

# Policy to allow access to specific S3 bucket
resource "aws_iam_policy" "guardduty_access_policy" {
  name        = "guardduty_s3_access_policy"
  description = "Policy to allow access to specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowManagedRuleToSendS3EventsToGuardDuty",
        Effect = "Allow",
        Action = [
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:PutEvents"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowPostScanTag",
        Effect = "Allow",
        Action = [
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:PutObjectVersionTagging",
          "s3:GetObjectVersionTagging"
        ],
        Resource = [aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*"]

      },
      {
        Sid    = "AllowEnableS3EventBridgeEvents",
        Effect = "Allow",
        Action = [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification"
        ],
        Resource = [aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*"]
      },
      {
        Sid    = "AllowPutValidationObject",
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = [aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*"]
      },
      {
        Sid    = "AllowCheckBucketOwnership",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketLocation",
        ],
        Resource = [aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*"]
      },
      {
        Sid    = "AllowMalwareScan",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = [aws_s3_bucket.bucket.arn,
        "${aws_s3_bucket.bucket.arn}/*"]
    }]
  })

  tags = {
    "Name"          = "guardduty_s3_access_policy"
    "Orchestration" = "Terraform"
  }
}


# Attach policy to role
resource "aws_iam_role_policy_attachment" "guardduty_role_policy_attachment" {
  role       = aws_iam_role.guardduty_role.name
  policy_arn = aws_iam_policy.guardduty_access_policy.arn
}
