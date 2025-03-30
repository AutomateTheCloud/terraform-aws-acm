locals {
  distinct_domain_names = sort(distinct(concat([var.domain_name], [for s in var.subject_alternative_names : replace(s, "*.", "")])))
  validation_domains    = (var.validation_method == "DNS" ? [for k, v in aws_acm_certificate.this.domain_validation_options : tomap(v) if contains(local.distinct_domain_names, replace(v.domain_name, "*.", ""))] : [])
}
