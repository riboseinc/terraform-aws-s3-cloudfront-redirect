module "main" {
  source = "../"

  fqdn                = var.fqdn
  ssl_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
  redirect_target     = var.redirect_target

  providers = {
    aws.cloudfront = aws.cloudfront
    aws.main       = aws.main
  }

}
