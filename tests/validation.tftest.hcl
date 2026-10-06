# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}

variables {
  details     = { scope = "Test", purpose = "Validation", environment = "test" }
  domain_name = "example.com"
}

run "scope_required" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "purpose_required" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "environment_required" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

# Regression: an empty domain name used to plan.
run "domain_name_empty" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { domain_name = "" }
  expect_failures = [var.domain_name]
}

run "domain_name_trailing_period" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { domain_name = "example.com." }
  expect_failures = [var.domain_name]
}

run "domain_name_not_fully_qualified" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { domain_name = "localhost" }
  expect_failures = [var.domain_name]
}

run "domain_name_wildcard_in_middle" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { domain_name = "www.*.example.com" }
  expect_failures = [var.domain_name]
}

run "subject_alternative_name_invalid" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { subject_alternative_names = ["www.example.com", "not a name"] }
  expect_failures = [var.subject_alternative_names]
}

run "validation_method_invalid" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { validation_method = "HTTP" }
  expect_failures = [var.validation_method]
}

run "route53_validation_needs_dns" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables {
    validation_method  = "EMAIL"
    route53_validation = { zone_id = "Z0123456789ABCDEFGHIJ" }
  }
  expect_failures = [var.route53_validation]
}

run "route53_validation_zone_id_empty" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables { route53_validation = { zone_id = "" } }
  expect_failures = [var.route53_validation]
}

# Regression: an empty abbreviation override was used as the abbreviation.
run "empty_abbr_override_is_ignored" {
  command   = plan
  providers = { aws = aws, aws.dns = aws }
  variables {
    details = { scope = "My Scope", scope_abbr = "", purpose = "p", environment = "e" }
  }
  assert {
    condition     = output.metadata.details.scope.abbr == "my_scope" && output.metadata.details.scope.machine == "myscope"
    error_message = "An empty override must fall back to the generated abbreviation."
  }
}
