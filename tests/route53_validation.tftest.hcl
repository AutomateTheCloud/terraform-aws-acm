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
  details            = { scope = "Test", purpose = "Route 53", environment = "test" }
  domain_name        = "example.com"
  route53_validation = { zone_id = "Z0123456789ABCDEFGHIJ" }
}

# Regression: the module planned one more record than there are domain names.
run "one_record_per_domain" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["www.example.com"]
  }
  assert {
    condition     = toset(keys(aws_route53_record.validation)) == toset(["example.com", "www.example.com"])
    error_message = "Expected exactly one record for each domain name."
  }
  assert {
    condition     = length(aws_acm_certificate_validation.this) == 1
    error_message = "The module waits for validation by default."
  }
}

# A wildcard and its base domain share one validation record.
run "wildcard_and_base_share_a_record" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["*.example.com"]
  }
  assert {
    condition     = keys(aws_route53_record.validation) == ["example.com"]
    error_message = "Expected one shared record for example.com and *.example.com."
  }
}

# Regression: a wildcard as the main domain name failed at apply.
run "wildcard_domain_name" {
  command   = apply
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    domain_name = "*.example.com"
  }
  assert {
    condition = (
      aws_route53_record.validation["example.com"].name == "_a.example.com." &&
      aws_route53_record.validation["example.com"].records == toset(["_a.acm-validations.aws."])
    )
    error_message = "The wildcard's validation record is wrong."
  }
}

# Records are created with aws.dns, the zone's account; the certificate and the wait
# with the default provider.
run "records_use_the_dns_provider" {
  command   = apply
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["www.example.com"]
    route53_validation        = { zone_id = "Z0123456789ABCDEFGHIJ", wait_for_validation = true }
  }
  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.fqdn == "created-by-aws-dns"])
    error_message = "Validation records must be created with the aws.dns provider."
  }
  assert {
    condition     = toset(aws_acm_certificate_validation.this[0].validation_record_fqdns) == toset(["created-by-aws-dns"])
    error_message = "The wait must use the records' fqdns."
  }
  assert {
    condition     = output.metadata.route53_record["www.example.com"].zone_id == "Z0123456789ABCDEFGHIJ"
    error_message = "metadata.route53_record is wrong."
  }
}

run "no_wait" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    route53_validation = { zone_id = "Z0123456789ABCDEFGHIJ", wait_for_validation = false }
  }
  assert {
    condition     = length(aws_route53_record.validation) == 1 && length(aws_acm_certificate_validation.this) == 0
    error_message = "Records without waiting were expected."
  }
}

# Regression: the module ignored changes to subject_alternative_names. (A mock provider
# does not replace the certificate, so it keeps the validation options of every name
# used here; the real provider replaces it, which is tested in AWS.)
run "sans_create" {
  command   = apply
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["www.example.com"]
  }
}

run "sans_change_is_planned" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["api.example.com"]
  }
  assert {
    condition     = aws_acm_certificate.this.subject_alternative_names == toset(["api.example.com"])
    error_message = "A change to subject_alternative_names must be planned."
  }
  assert {
    condition     = toset(keys(aws_route53_record.validation)) == toset(["example.com", "api.example.com"])
    error_message = "Records must follow the new names."
  }
}

# Regression: replacing the certificate also replaced the validation records of names
# that did not change, deleting them before the new certificate existed. The records'
# names must stay known (from the state) when the certificate is replaced.
run "replaced_certificate_keeps_records" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  variables {
    subject_alternative_names = ["api.example.com"]
  }
  plan_options {
    replace = [aws_acm_certificate.this]
  }
  assert {
    condition     = aws_route53_record.validation["example.com"].name == "_a.example.com."
    error_message = "The example.com record must not be replaced with the certificate."
  }
}
