# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A certificate for a CloudFront distribution: a domain and every subdomain one level
# below it, created in us-east-1 (the only Region CloudFront uses certificates from)
# while the provider works in another Region.

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
  region = "us-west-2"
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

  providers = { aws = aws, aws.dns = aws }

  # CloudFront uses certificates only from us-east-1.
  region = "us-east-1"

  details = {
    scope            = "Example"
    scope_abbr       = "ex"
    purpose          = "Content Delivery Network"
    purpose_abbr     = "cdn"
    environment      = "Production"
    environment_abbr = "prd"
    additional_tags  = { CostCenter = "1234" }
  }

  # The wildcard covers www.example.org and api.example.org, but not example.org itself.
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]

  validation_method                   = "DNS"
  enable_certificate_transparency_log = true

  route53_validation = {
    zone_id             = data.aws_route53_zone.this.zone_id
    wait_for_validation = true
  }
}

output "certificate" {
  description = "ARN, Region and expiry of the issued certificate"
  value = {
    arn       = module.acm.metadata.acm_certificate_validation.certificate_arn
    region    = module.acm.metadata.aws.region.name
    not_after = module.acm.metadata.acm_certificate.not_after
  }
}
