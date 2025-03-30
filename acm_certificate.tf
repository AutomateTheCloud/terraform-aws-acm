resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = (length(var.subject_alternative_names) > 0 ? sort(var.subject_alternative_names) : null)
  validation_method         = var.validation_method
  options {
    certificate_transparency_logging_preference = (var.enable_certificate_transparency_log ? "ENABLED" : "DISABLED")
  }
  tags = merge(
    local.tags,
    tomap({
      "Name" = var.domain_name
    })
  )
  lifecycle {
    ignore_changes        = [subject_alternative_names]
    create_before_destroy = true
  }
  provider = aws.this
}
