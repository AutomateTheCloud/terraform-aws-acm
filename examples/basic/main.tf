# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A certificate for a domain and its www subdomain, validated through a Route 53 hosted
# zone in the same AWS account.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "domain_name" {
  description = "A domain name with a public Route 53 hosted zone in this account, such as example.org"
  type        = string
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

module "acm" {
  source = "../../"

  # The hosted zone is in the same account, so the DNS records use the same provider.
  providers = { aws = aws, aws.dns = aws }

  details = {
    scope       = "Example"
    purpose     = "Basic Certificate"
    environment = "Development"
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  route53_validation        = { zone_id = data.aws_route53_zone.this.zone_id }
}

output "certificate_arn" {
  description = "ARN of the issued certificate"
  value       = module.acm.metadata.acm_certificate_validation.certificate_arn
}
