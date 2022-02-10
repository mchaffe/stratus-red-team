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

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_flow_log" "flow-logs" {
  iam_role_arn    = aws_iam_role.role.arn
  log_destination = aws_cloudwatch_log_group.logs.arn
  traffic_type    = "REJECT"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/stratus-red-team/vpc-flow-logs"
}

data "aws_iam_policy_document" "assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifies = "vpc-flow-logs.amazonaws.com"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "role" {
  name = "example"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

data "aws_iam_policy_document" "allow-writing-to-cloudwatch" {
  statement {
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name = "allow-writing-to-cloudwatch"
  role = aws_iam_role.role.id

  policy = data.aws_iam_policy_document.allow-writing-to-cloudwatch.json
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "flow_logs_id" {
  value = aws_flow_log.flow-logs.id
}

output "display" {
  value = format("VPC Flow Logs %s in VPC %s ready", aws_flow_log.flow-logs.id, aws_vpc.vpc.id)
}