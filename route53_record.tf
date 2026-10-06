# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# One validation record per domain name. A wildcard and its base domain (`*.example.com`
# and `example.com`) share one record.
resource "aws_route53_record" "validation" {
  provider = aws.dns
  for_each = local.route53_validation_domains

  zone_id = var.route53_validation.zone_id
  name    = local.domain_validation_options[each.key].resource_record_name
  type    = local.domain_validation_options[each.key].resource_record_type
  ttl     = 60
  records = [local.domain_validation_options[each.key].resource_record_value]

  # Another certificate for the same domain name in this account uses the same record.
  allow_overwrite = true

  # ACM gives a domain name the same record for every certificate in an account. When
  # the certificate is replaced, its validation options are unknown until apply, and
  # without this every record would be deleted and created again, before the new
  # certificate exists. The certificate still in use would be left without its records
  # if the apply then failed.
  lifecycle {
    ignore_changes = [name, type, records]
  }
}
