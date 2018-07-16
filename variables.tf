variable "fqdn" {
  type        = "string"
  description = "The FQDN of the website and also name of the S3 bucket"
}

variable "redirect_target" {
  type        = "string"
  description = "The FQDN to redirect to"
}

variable "force_destroy" {
  type        = "string"
  description = "The force_destroy argument of the S3 bucket"
  default     = "false"
}

variable "ssl_certificate_arn" {
  type        = "string"
  description = "ARN of the certificate covering var.fqdn"
}

variable "web_acl_id" {
  type        = "string"
  description = "WAF Web ACL ID to attach to the CloudFront distribution, optional"
  default     = ""
}

variable "refer_secret" {
  type        = "string"
  description = "A secret string to authenticate CF requests to S3"
  default    = "345-VERY-SECRET-678"
}

variable "tags" {
  type        = "map"
  description = "Tags"
  default     = {}
}
