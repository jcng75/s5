data "aws_caller_identity" "current" {}

# ALlow only specific user to be able to assume role
resource "aws_iam_role" "website_access_role" {
  name = "s3_website_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumeRolePolicy"
        Principal = {
          AWS = data.aws_iam_user.user.arn
        }
      }
    ]
  })

  tags = {
    Name = "s3_website_access_role"
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
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:ListBucket"
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
}

data "aws_iam_user" "user" {
  user_name = "justin"
}

# Assigning assumerole policy to user
resource "aws_iam_policy_attachment" "user_role_attachment" {
  name       = "user_role_attachment"
  policy_arn = aws_iam_policy.assume_role_policy.arn
  users      = [data.aws_iam_user.user.user_name]
}
