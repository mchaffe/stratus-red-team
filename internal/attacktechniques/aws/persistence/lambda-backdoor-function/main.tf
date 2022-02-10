terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.71.0"
    }
  }
}
provider "aws" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  default_tags {
    tags = {
      StratusRedTeam = true
    }
  }
}

data "aws_iam_policy_document" "assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifies = "lambda.amazonaws.com"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "lambda" {
  name = "lambda-function-role-stratus-red-team"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

resource "random_string" "suffix" {
  length    = 16
  min_lower = 16
  special   = false
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "stratus-red-team-lambda-function-code-${random_string.suffix.result}"
  acl           = "private"
  force_destroy = true
}
resource "aws_s3_bucket_object" "code" {
  bucket         = aws_s3_bucket.bucket.id
  key            = "index.zip"
  content_base64 = "UEsDBBQAAAAIAJuwM1S3dfsVfQAAAJEAAAAHABwAbWFpbi5qc1VUCQAD9nzoYfd86GF1eAsAAQT2AQAABBQAAAA1zLEOgjAQgOG9T3FhopF0YDRxZHGoA8bJpakHNilXcr0aCPHdlYHxH74flzmxZPN29IrIcAFweSUPQyEvIVGNHyRpwCcSXETDpmCPnCKamMa66h6dvZ/hSRWc4NrfrMnCgcYwrAemEmMDrdZ/yyiF6fjti14Y3WTdhOqrflBLAQIeAxQAAAAIAJuwM1S3dfsVfQAAAJEAAAAHABgAAAAAAAEAAACkgQAAAABtYWluLmpzVVQFAAP2fOhhdXgLAAEE9gEAAAQUAAAAUEsFBgAAAAABAAEATQAAAL4AAAAAAA=="
}

resource "aws_lambda_function" "lambda" {
  function_name = "stratus-sample-lambda-function"
  s3_bucket     = aws_s3_bucket.bucket.id
  s3_key        = aws_s3_bucket_object.code.key
  role          = aws_iam_role.lambda.arn
  handler       = "index.test"
  runtime       = "nodejs12.x"
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "display" {
  value = format("Lambda function %s is ready", aws_lambda_function.lambda.arn)
}