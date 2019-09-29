provider "aws" {
  alias = "main"
  description = "AWS Region for S3 and other resources"
}

provider "aws" {
  alias = "cloudfront"
  description = "AWS Region for Cloudfront (ACM certs only supports us-east-1)"
}
