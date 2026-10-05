# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # Every domain name the certificate covers, lowercase and without a leading `*.`. These
  # are the names ACM validates, and they come from the inputs alone, so the set of
  # validation records is known at plan time.
  validation_domains = toset([
    for d in concat([var.domain_name], var.subject_alternative_names) : lower(trimprefix(d, "*."))
  ])

  route53_validation_domains = (var.validation_method == "DNS" && var.route53_validation != null) ? local.validation_domains : toset([])

  wait_for_validation = length(local.route53_validation_domains) > 0 && try(var.route53_validation.wait_for_validation, false)

  # The record ACM asks for, for each domain name. A wildcard and its base domain get the
  # same record, so the first match is enough.
  domain_validation_options = {
    for d in local.route53_validation_domains : d => [
      for o in aws_acm_certificate.this.domain_validation_options : o if lower(trimprefix(o.domain_name, "*.")) == d
    ][0]
  }
}
