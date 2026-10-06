# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}
mock_provider "aws" {
  alias = "dns"
}

# Regression: route53_validation.zone_id can refer to a hosted zone created in the same
# run, whose ID is not known until apply.
run "zone_created_in_same_run" {
  command   = plan
  providers = { aws = aws, aws.dns = aws.dns }
  module {
    source = "./tests/fixtures/same_run_zone"
  }
  assert {
    condition     = length(module.acm.metadata.route53_record) == 2
    error_message = "Validation records were not planned."
  }
}
