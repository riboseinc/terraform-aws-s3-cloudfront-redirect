#resource "aws_cloudfront_origin_access_identity" "main" {
#  provider = aws.cloudfront
#  comment = "${var.fqdn} OAI"
#}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = var.fqdn
  description                       = "${var.fqdn} OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  #checkov:skip=CKV_AWS_34:"target will redirect to https anyway"
  #checkov:skip=CKV_AWS_86:"Activate access logging later"
  #checkov:skip=CKV_AWS_174:"Enforce tls 1.2 at target"
  #checkov:skip=CKV_AWS_68:"Target has WAF"
  #checkov:skip=CKV_AWS_310:"Origin Failover?"
  #checkov:skip=CKV_AWS_305:"No need for default root object"
  provider     = aws.cloudfront
  http_version = "http2"

  is_ipv6_enabled     = true
  default_root_object = var.cloudfront_default_root_object

  dynamic "custom_error_response" {
    for_each = var.use_html_page_to_redirect ? [1] : []
    content {
      error_code            = 404
      error_caching_min_ttl = 10
      response_code         = 200
      response_page_path    = "/${var.cloudfront_default_root_object}"
    }
  }

  dynamic "custom_error_response" {
    for_each = var.use_html_page_to_redirect ? [1] : []
    content {
      error_code            = 403
      error_caching_min_ttl = 10
      response_code         = 200
      response_page_path    = "/${var.cloudfront_default_root_object}"
    }
  }

  origin {
    origin_id                = "origin-${var.fqdn}"
    domain_name              = var.use_html_page_to_redirect ? aws_s3_bucket.main.bucket_regional_domain_name : aws_s3_bucket_website_configuration.main.website_endpoint
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id

    #dynamic "s3_origin_config" {
    #  for_each = var.use_html_page_to_redirect ? [] : []
    #  content {
    #    origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    #  }
    #}

    # https://docs.aws.amazon.com/AmazonCloudFront/latest/
    # DeveloperGuide/distribution-web-values-specify.html
    dynamic "custom_origin_config" {
      for_each = var.use_html_page_to_redirect ? [] : [1]
      content {
        # "HTTP Only: CloudFront uses only HTTP to access the origin."
        # "Important: If your origin is an Amazon S3 bucket configured
        # as a website endpoint, you must choose this option. Amazon S3
        # doesn't support HTTPS connections for website endpoints."
        origin_protocol_policy = "http-only"

        http_port  = "80"
        https_port = "443"

        # TODO: given the origin_protocol_policy set to `http-only`,
        # not sure what this does...
        # "If the origin is an Amazon S3 bucket, CloudFront always uses TLSv1.2."
        origin_ssl_protocols = ["TLSv1.2"]
      }
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
      value = var.refer_secret
    }
  }

  enabled = true

  aliases = [var.fqdn]

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
    acm_certificate_arn      = var.ssl_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  web_acl_id = var.web_acl_id
}
