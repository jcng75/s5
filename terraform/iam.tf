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
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "s3_website_access_role"
  }
}

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

resource "aws_iam_policy_attachment" "user_role_attachment" {
  name       = "user_role_attachment"
  policy_arn = aws_iam_policy.assume_role_policy.arn
  users      = [data.aws_iam_user.user.user_name]
}
