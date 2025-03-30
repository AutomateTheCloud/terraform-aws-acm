resource "aws_route53_record" "validation" {
  count   = (var.validation_zone_id != "" && var.validation_method == "DNS" ? length(local.distinct_domain_names) + 1 : 0)
  zone_id = var.validation_zone_id
  name    = element(local.validation_domains, count.index)["resource_record_name"]
  type    = element(local.validation_domains, count.index)["resource_record_type"]
  ttl     = "60"
  records = [
    element(local.validation_domains, count.index)["resource_record_value"]
  ]
  allow_overwrite = true
  depends_on      = [aws_acm_certificate.this]
  provider        = aws.this
}
