# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
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
  details     = { scope = "Test", purpose = "Defaults", environment = "test" }
  domain_name = "example.com"
}

# Only the required inputs. The zone is in the certificate's account.
run "defaults" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }

  assert {
    condition     = aws_acm_certificate.this.validation_method == "DNS"
    error_message = "DNS validation is the default."
  }
  assert {
    condition     = one(aws_acm_certificate.this.options).certificate_transparency_logging_preference == "ENABLED"
    error_message = "Certificate transparency logging must be on by default."
  }
  assert {
    condition     = length(aws_route53_record.validation) == 0 && length(aws_acm_certificate_validation.this) == 0
    error_message = "No records or wait without route53_validation."
  }
  assert {
    condition = aws_acm_certificate.this.tags == tomap({
      Scope = "Test", Purpose = "Defaults", Environment = "test", Name = "example.com"
    })
    error_message = "Unexpected tags."
  }
  assert {
    condition     = output.metadata.route53_record == null && output.metadata.acm_certificate_validation == null
    error_message = "Resources that are not created must be null in metadata."
  }
}

run "defaults_apply" {
  command   = apply
  providers = { aws = aws, aws.dns = aws }

  assert {
    condition     = output.metadata.acm_certificate.arn == "arn:aws:acm:us-east-1:111111111111:certificate/test-certificate"
    error_message = "metadata.acm_certificate.arn is wrong."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws.region.abbr == "use1"
    error_message = "metadata.aws is wrong."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "defaults" && output.metadata.details.purpose.machine == "defaults"
    error_message = "metadata.details is wrong."
  }
}

run "email_validation" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables {
    validation_method                   = "EMAIL"
    enable_certificate_transparency_log = false
  }
  assert {
    condition     = aws_acm_certificate.this.validation_method == "EMAIL" && length(aws_route53_record.validation) == 0
    error_message = "EMAIL validation creates no records."
  }
  assert {
    condition     = one(aws_acm_certificate.this.options).certificate_transparency_logging_preference == "DISABLED"
    error_message = "Certificate transparency logging should be off."
  }
}
