variable "fqdn" {
  type        = string
  description = "The FQDN of the website and also name of the S3 bucket"
}

variable "redirect_target" {
  type        = string
  description = "The FQDN to redirect to"
}

variable "force_destroy" {
  type        = string
  description = "The force_destroy argument of the S3 bucket"
  default     = "false"
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ARN of the certificate covering var.fqdn"
}

variable "web_acl_id" {
  type        = string
  description = "WAF Web ACL ID to attach to the CloudFront distribution, optional"
  default     = ""
}

variable "refer_secret" {
  type        = string
  description = "A secret string to authenticate CF requests to S3"
  default     = "345-VERY-SECRET-678"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}

variable "use_html_page_to_redirect" {
  type        = bool
  description = "Use an HTML page to redirect"
  default     = false
}

# All values for the TTL are important when uploading static content that changes
# https://stackoverflow.com/questions/67845341/cloudfront-s3-etag-possible-for-cloudfront-to-send-updated-s3-object-before-t
variable "cloudfront_min_ttl" {
  type        = number
  default     = 0
  description = "The minimum TTL for the cloudfront cache"
}

variable "cloudfront_default_ttl" {
  type        = number
  default     = 86400
  description = "The default TTL for the cloudfront cache"
}

variable "cloudfront_max_ttl" {
  type        = number
  default     = 31536000
  description = "The maximum TTL for the cloudfront cache"
}

variable "cloudfront_default_root_object" {
  type        = string
  description = "Default root object for cloudfront. Need to also provide custom error response if changing from default"
  default     = "index.html"
}
