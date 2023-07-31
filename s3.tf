resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  dynamic "index_document" {
    for_each = var.use_html_page_to_redirect ? [1] : []
    content {
      suffix = "index.html"
    }
  }

  dynamic "error_document" {
    for_each = var.use_html_page_to_redirect ? [1] : []
    content {
      key = "index.html"
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.use_html_page_to_redirect ? [] : [1]
    content {
      host_name = var.redirect_target
    }
  }
}

resource "aws_s3_object" "index_html" {
  count  = var.use_html_page_to_redirect ? 1 : 0
  bucket = aws_s3_bucket.main.id
  key    = var.cloudfront_default_root_object

  content = templatefile("${path.module}/index.html.tpl", {
    redirection_target = var.redirect_target
  })

  content_type = "text/html"
}

resource "aws_s3_bucket_public_access_block" "main" {
  #checkov:skip=CKV_AWS_54:"The bucket policy is handled by the terraform resource aws_s3_bucket_policy"
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = var.use_html_page_to_redirect ? true : false
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

  #statement {
  #  actions   = ["s3:GetObject"]
  #  resources = ["${aws_s3_bucket.main.arn}/*"]
  #
  #  principals {
  #    type        = "AWS"
  #    identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
  #  }
  #}

  dynamic "statement" {
    for_each = var.use_html_page_to_redirect ? [1] : []
    content {
      sid       = "AllowCloudFrontServicePrincipal"
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.main.arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [aws_cloudfront_distribution.main.arn]
      }

      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.use_html_page_to_redirect ? [] : [1]
    content {
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
}
