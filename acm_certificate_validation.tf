# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Waits until ACM has issued the certificate.
resource "aws_acm_certificate_validation" "this" {
  count = local.wait_for_validation ? 1 : 0

  region                  = var.region
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for d in local.route53_validation_domains : aws_route53_record.validation[d].fqdn]
}
