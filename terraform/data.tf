data "aws_iam_user" "user" {
  user_name = "justin"
}

data "aws_caller_identity" "current" {}
