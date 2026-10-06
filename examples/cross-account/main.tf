# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A certificate in one AWS account, validated through a Route 53 hosted zone in another.
# This is common when one account holds an organization's DNS.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The account that gets the certificate.
provider "aws" {
  region = "us-east-1"
}

# The account that holds the hosted zone, reached by assuming a role in it.
provider "aws" {
  alias  = "dns"
  region = "us-east-1"

  assume_role {
    role_arn = var.dns_role_arn
  }
}

variable "domain_name" {
  description = "A domain name with a public Route 53 hosted zone in the DNS account, such as example.org"
  type        = string
}

variable "dns_role_arn" {
  description = "ARN of an IAM role in the DNS account that this configuration can assume, and that may change records in the hosted zone"
  type        = string
}

data "aws_route53_zone" "this" {
  provider     = aws.dns
  name         = var.domain_name
  private_zone = false
}

module "acm" {
  source = "../../"

  # The certificate uses the default provider; the validation records use aws.dns.
  providers = { aws = aws, aws.dns = aws.dns }

  details = {
    scope       = "Example"
    purpose     = "Cross Account Certificate"
    environment = "Development"
  }

  domain_name        = "app.${var.domain_name}"
  route53_validation = { zone_id = data.aws_route53_zone.this.zone_id }
}

output "certificate_arn" {
  description = "ARN of the issued certificate"
  value       = module.acm.metadata.acm_certificate_validation.certificate_arn
}
