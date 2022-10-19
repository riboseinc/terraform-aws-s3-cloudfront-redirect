resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}


resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  redirect_all_requests_to {
    host_name = var.redirect_target
  }
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

