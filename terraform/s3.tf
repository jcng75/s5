# S3 Bucket Creation - Using random numbers to ensure unique bucket names
resource "aws_s3_bucket" "bucket" {
  bucket = "s3-static-website-bucket-7950"
  # Indicates bucket to be destroyed even if it is not empty
  force_destroy = true

  tags = {
    Name = "s3-static-website-bucket-7950"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  depends_on = [aws_s3_bucket_acl.acl]
  bucket     = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "WriteAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.website_access_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
      {
        Sid       = "PublicWebsiteAccess",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject",
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

# Create a base configuration for website stating index and error pages
resource "aws_s3_bucket_website_configuration" "bucket_website_configuration" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "owner_controls" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.owner_controls,
    aws_s3_bucket_public_access_block.access_block,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}
