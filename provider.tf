provider "aws" {
  alias   = "main"
  version = "~> 2.9"
  # description = "AWS Region for S3 and other resources"
}

provider "aws" {
  alias   = "cloudfront"
  version = "~> 2.9"
  # description = "AWS Region for Cloudfront (ACM certs only supports us-east-1)"
}

