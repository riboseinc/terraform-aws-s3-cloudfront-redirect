# resource "aws_cloudfront_origin_access_identity" "main" {
#   provider = "aws.cloudfront"
#   comment = "cf-origin-${var.fqdn}"
# }

resource "aws_cloudfront_distribution" "main" {
  provider = "aws.cloudfront"
  http_version = "http2"

  origin {
    origin_id   = "origin-${var.fqdn}"
    domain_name = "${aws_s3_bucket.main.website_endpoint}"

    custom_origin_config {
      origin_protocol_policy = "match-viewer"
      http_port = "80"
      https_port = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    # s3_origin_config is not compatible with S3 website hosting, if this
    # is used, /news/index.html will not resolve as /news/.
    # https://www.reddit.com/r/aws/comments/6o8f89/can_you_force_cloudfront_only_access_while_using/
    # s3_origin_config {
    #   origin_access_identity = "${aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path}"
    # }
    # Instead, we use a secret to authenticate CF requests to S3 policy.
    # Not the best, but...
    custom_header {
      name  = "User-Agent"
      value = "${var.refer_secret}"
    }

  }

  enabled = true

  aliases = ["${var.fqdn}"]

  price_class = "PriceClass_100"

  default_cache_behavior {
    target_origin_id = "origin-${var.fqdn}"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.ssl_certificate_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  web_acl_id = "${var.web_acl_id}"
}
