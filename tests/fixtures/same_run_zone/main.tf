# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A hosted zone in one account, and a certificate in another validated through it,
# created in the same run. The zone's ID is not known until apply.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws.dns]
    }
  }
}

resource "aws_route53_zone" "this" {
  provider = aws.dns
  name     = "example.com"
}

module "acm" {
  source    = "../../.."
  providers = { aws = aws, aws.dns = aws.dns }

  details                   = { scope = "Test", purpose = "Same run", environment = "test" }
  domain_name               = "example.com"
  subject_alternative_names = ["www.example.com"]
  route53_validation        = { zone_id = aws_route53_zone.this.zone_id }
}
