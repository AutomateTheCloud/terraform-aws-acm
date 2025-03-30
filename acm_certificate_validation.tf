resource "aws_acm_certificate_validation" "this" {
  count                   = (var.validation_zone_id != "" && var.validation_method == "DNS" && var.wait_for_validation ? 1 : 0)
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = aws_route53_record.validation.*.fqdn
  provider                = aws.this
}
