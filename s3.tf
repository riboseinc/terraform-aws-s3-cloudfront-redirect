resource "aws_s3_bucket" "main" {
  provider = "aws.main"
  bucket   = "${var.fqdn}"
  acl      = "private"
  policy   = "${data.aws_iam_policy_document.bucket_policy.json}"

  website {
    redirect_all_requests_to = "${var.redirect_target}"
  }

  force_destroy = "${var.force_destroy}"

  tags = "${merge("${var.tags}",map("Name", "${var.fqdn}"))}"
}

data "aws_iam_policy_document" "bucket_policy" {
  provider = "aws.main"

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        "${var.refer_secret}"
      ]
    }

    principals {
      type = "*"
      identifiers = ["*"]
    }

  }

}
