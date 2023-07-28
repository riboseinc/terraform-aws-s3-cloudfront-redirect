resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  redirect_all_requests_to {
    host_name = var.redirect_target
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  #checkov:skip=CKV_AWS_54:"The bucket policy is handled by the terraform resource aws_s3_bucket_policy"
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket" "main" {
  provider = aws.main
  bucket   = var.fqdn

  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      "Name" = var.fqdn
    },
  )
}

data "aws_iam_policy_document" "bucket_policy" {
  provider = aws.main

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        var.refer_secret,
      ]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
