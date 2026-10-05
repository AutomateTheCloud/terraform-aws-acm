# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_acm_certificate" "this" {
  region                    = var.region
  domain_name               = var.domain_name
  subject_alternative_names = length(var.subject_alternative_names) > 0 ? var.subject_alternative_names : null
  validation_method         = var.validation_method

  options {
    certificate_transparency_logging_preference = var.enable_certificate_transparency_log ? "ENABLED" : "DISABLED"
  }

  tags = merge(local.tags, { Name = var.domain_name })

  # Changing the domain names replaces the certificate. Create the new one first, so
  # that load balancers and CloudFront distributions using it can switch over.
  lifecycle {
    create_before_destroy = true
  }
}
