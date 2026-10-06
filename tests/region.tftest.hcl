# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:111111111111:certificate/test-certificate"
      domain_validation_options = [
        { domain_name = "example.com", resource_record_name = "_a.example.com.", resource_record_type = "CNAME", resource_record_value = "_a.acm-validations.aws." },
        { domain_name = "*.example.com", resource_record_name = "_a.example.com.", resource_record_type = "CNAME", resource_record_value = "_a.acm-validations.aws." },
        { domain_name = "www.example.com", resource_record_name = "_b.www.example.com.", resource_record_type = "CNAME", resource_record_value = "_b.acm-validations.aws." },
        { domain_name = "api.example.com", resource_record_name = "_c.api.example.com.", resource_record_type = "CNAME", resource_record_value = "_c.acm-validations.aws." },
      ]
    }
  }
}

# The Route 53 zone's account. Its records get a recognizable fqdn, so a test can tell
# which provider created them.
mock_provider "aws" {
  alias = "dns"
  mock_resource "aws_route53_record" {
    defaults = { fqdn = "created-by-aws-dns" }
  }
}

variables {
  details            = { scope = "Test", purpose = "Region", environment = "test" }
  domain_name        = "example.com"
  route53_validation = { zone_id = "Z0123456789ABCDEFGHIJ" }
}

run "provider_region_by_default" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command   = apply
  providers = { aws = aws, aws.dns = aws }
  variables { region = "eu-west-1" }
  assert {
    condition = alltrue([
      aws_acm_certificate.this.region == "eu-west-1",
      aws_acm_certificate_validation.this[0].region == "eu-west-1",
      output.metadata.aws.region.name == "eu-west-1",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Regression: Regions missing from the old hard-coded table failed to plan.
run "region_not_in_old_table" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { region = "mx-central-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
