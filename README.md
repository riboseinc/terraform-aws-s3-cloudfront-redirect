# Terraform module to setup a S3 Website with CloudFront, ACM

This module helps you create a S3 website, assuming that:

* it runs HTTPS via Amazon's Certificate Manager ("ACM")
* its domain is backed by a Route53 zone
* and of course, your AWS account provides you access to all these resources necessary.

This module is available on the [Terraform Registry](https://registry.terraform.io/modules/riboseinc/s3-cloudfront-redirect/aws/).

This module is a pair with
[terraform-aws-s3-cloudfront-website](https://github.com/riboseinc/terraform-aws-s3-cloudfront-website),
which handles hosting of a static S3 website with CloudFront and ACM.

## Sample Usage

You can literally copy and paste the following example, change the following attributes, and you're ready to go:

* `fqdn` set to your static website's hostname
* `redirect_target` set to where you want the hostname to redirect to (e.g. `example.com` => (this one) `www.example.com`)


```hcl
# AWS Region for S3 and other resources
provider "aws" {
  region = "us-west-2"
  alias = "main"
}

# AWS Region for Cloudfront (ACM certs only supports us-east-1)
provider "aws" {
  region = "us-east-1"
  alias = "cloudfront"
}

# Variables
variable "fqdn" {
  description = "The fully-qualified domain name root of the resulting S3 website."
  default     = "example.com"
}

variable "redirect_target" {
  description = "The fully-qualified domain name to redirect to."
  default     = "www.example.com"
}

# Using this module
module "main" {
  source = "github.com/riboseinc/terraform-aws-s3-cloudfront-redirect"

  fqdn = "${var.fqdn}"
  redirect_target = "${var.redirect_target}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"

  refer_secret = "${base64sha512("REFER-SECRET-19265125-${var.fqdn}-52865926")}"
  force_destroy = "true"

  providers = {
    aws.main = aws.main
    aws.cloudfront = aws.cloudfront
  }

  # Optional WAF Web ACL ID, defaults to none.
  web_acl_id = "${data.terraform_remote_state.site.waf-web-acl-id}"
}

# ACM Certificate generation

resource "aws_acm_certificate" "cert" {
  provider          = "aws.cloudfront"
  domain_name       = "${var.fqdn}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.cloudfront"
  name     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.main.id}"
  records  = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.cloudfront"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}


# Route 53 record for the static site

data "aws_route53_zone" "main" {
  provider     = "aws.main"
  name         = "${var.fqdn}"
  private_zone = false
}

resource "aws_route53_record" "web" {
  provider = "aws.main"
  zone_id  = "${data.aws_route53_zone.main.zone_id}"
  name     = "${var.fqdn}"
  type     = "A"

  alias {
    name    = "${module.main.cf_domain_name}"
    zone_id = "${module.main.cf_hosted_zone_id}"
    evaluate_target_health = false
  }
}

# Outputs

output "s3_bucket_id" {
  value = "${module.main.s3_bucket_id}"
}

output "s3_domain" {
  value = "${module.main.s3_website_endpoint}"
}

output "s3_hosted_zone_id" {
  value = "${module.main.s3_hosted_zone_id}"
}

output "cloudfront_domain" {
  value = "${module.main.cf_domain_name}"
}

output "cloudfront_hosted_zone_id" {
  value = "${module.main.cf_hosted_zone_id}"
}

output "cloudfront_distribution_id" {
  value = "${module.main.cf_distribution_id}"
}

output "route53_fqdn" {
  value = "${aws_route53_record.web.fqdn}"
}

output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.cert.certificate_arn}"
}
```

## Upgrading to Terraform 0.12

This module now supports Terraform 0.12.

To upgrade to Terraform 0.12 using this module, do this:

```bash
terraform init -upgrade
terraform 0.12upgrade
terraform plan
terraform apply -auto-approve
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4 |
| <a name="provider_aws.cloudfront"></a> [aws.cloudfront](#provider\_aws.cloudfront) | >= 4 |
| <a name="provider_aws.main"></a> [aws.main](#provider\_aws.main) | >= 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_website_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_s3_object.index_html](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudfront_default_root_object"></a> [cloudfront\_default\_root\_object](#input\_cloudfront\_default\_root\_object) | Default root object for cloudfront. Need to also provide custom error response if changing from default | `string` | `"index.html"` | no |
| <a name="input_cloudfront_default_ttl"></a> [cloudfront\_default\_ttl](#input\_cloudfront\_default\_ttl) | The default TTL for the cloudfront cache | `number` | `86400` | no |
| <a name="input_cloudfront_max_ttl"></a> [cloudfront\_max\_ttl](#input\_cloudfront\_max\_ttl) | The maximum TTL for the cloudfront cache | `number` | `31536000` | no |
| <a name="input_cloudfront_min_ttl"></a> [cloudfront\_min\_ttl](#input\_cloudfront\_min\_ttl) | The minimum TTL for the cloudfront cache | `number` | `0` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | The force\_destroy argument of the S3 bucket | `string` | `"false"` | no |
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | The FQDN of the website and also name of the S3 bucket | `string` | n/a | yes |
| <a name="input_redirect_target"></a> [redirect\_target](#input\_redirect\_target) | The FQDN to redirect to | `string` | n/a | yes |
| <a name="input_refer_secret"></a> [refer\_secret](#input\_refer\_secret) | A secret string to authenticate CF requests to S3 | `string` | `"345-VERY-SECRET-678"` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | ARN of the certificate covering var.fqdn | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags | `map(string)` | `{}` | no |
| <a name="input_use_html_page_to_redirect"></a> [use\_html\_page\_to\_redirect](#input\_use\_html\_page\_to\_redirect) | Use an HTML page to redirect | `bool` | `false` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | WAF Web ACL ID to attach to the CloudFront distribution, optional | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cf_distribution_id"></a> [cf\_distribution\_id](#output\_cf\_distribution\_id) | n/a |
| <a name="output_cf_domain_name"></a> [cf\_domain\_name](#output\_cf\_domain\_name) | n/a |
| <a name="output_cf_hosted_zone_id"></a> [cf\_hosted\_zone\_id](#output\_cf\_hosted\_zone\_id) | n/a |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | n/a |
| <a name="output_s3_hosted_zone_id"></a> [s3\_hosted\_zone\_id](#output\_s3\_hosted\_zone\_id) | n/a |
| <a name="output_s3_website_endpoint"></a> [s3\_website\_endpoint](#output\_s3\_website\_endpoint) | n/a |
<!-- END_TF_DOCS -->
