# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the certificate.
    - `acm_certificate` - The certificate, including its `arn`, `status`, `domain_name`, `subject_alternative_names`, `not_after` (expiry), and `domain_validation_options`: the `resource_record_name`, `resource_record_type` and `resource_record_value` of the DNS record that validates each domain name. `status` and the validity dates are read when the certificate is created; when the module waits for validation, they still show `PENDING_VALIDATION` until the next plan or apply refreshes them.
    - `acm_certificate_validation` - The `certificate_arn` and `validation_record_fqdns` once the certificate is issued. `null` unless the module waits for validation.
    - `route53_record` - The validation records, keyed by domain name (without a leading `*.`), each with its `fqdn`, `name`, `type`, `records`, `ttl` and `zone_id`. `null` unless `route53_validation` is set.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource. Resources that are not created are null.
    acm_certificate            = local.output_resources.acm_certificate
    acm_certificate_validation = local.output_resources.acm_certificate_validation
    route53_record             = local.output_resources.route53_record
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    acm_certificate = {
      arn                       = aws_acm_certificate.this.arn
      certificate_authority_arn = aws_acm_certificate.this.certificate_authority_arn
      certificate_body          = aws_acm_certificate.this.certificate_body
      certificate_chain         = aws_acm_certificate.this.certificate_chain
      domain_name               = aws_acm_certificate.this.domain_name
      domain_validation_options = aws_acm_certificate.this.domain_validation_options
      early_renewal_duration    = aws_acm_certificate.this.early_renewal_duration
      id                        = aws_acm_certificate.this.id
      key_algorithm             = aws_acm_certificate.this.key_algorithm
      not_after                 = aws_acm_certificate.this.not_after
      not_before                = aws_acm_certificate.this.not_before
      options                   = aws_acm_certificate.this.options
      pending_renewal           = aws_acm_certificate.this.pending_renewal
      region                    = aws_acm_certificate.this.region
      renewal_eligibility       = aws_acm_certificate.this.renewal_eligibility
      renewal_summary           = aws_acm_certificate.this.renewal_summary
      status                    = aws_acm_certificate.this.status
      subject_alternative_names = aws_acm_certificate.this.subject_alternative_names
      tags                      = aws_acm_certificate.this.tags
      tags_all                  = aws_acm_certificate.this.tags_all
      type                      = aws_acm_certificate.this.type
      validation_emails         = aws_acm_certificate.this.validation_emails
      validation_method         = aws_acm_certificate.this.validation_method
      validation_option         = aws_acm_certificate.this.validation_option
    }

    acm_certificate_validation = length(aws_acm_certificate_validation.this) == 0 ? null : {
      certificate_arn         = aws_acm_certificate_validation.this[0].certificate_arn
      id                      = aws_acm_certificate_validation.this[0].id
      region                  = aws_acm_certificate_validation.this[0].region
      validation_record_fqdns = aws_acm_certificate_validation.this[0].validation_record_fqdns
    }


    # Keyed by domain name. Only the attributes a validation record sets; the routing
    # policy attributes are always empty here.
    route53_record = length(local.route53_validation_domains) == 0 ? null : {
      for d in local.route53_validation_domains : d => {
        allow_overwrite = aws_route53_record.validation[d].allow_overwrite
        fqdn            = aws_route53_record.validation[d].fqdn
        id              = aws_route53_record.validation[d].id
        name            = aws_route53_record.validation[d].name
        records         = aws_route53_record.validation[d].records
        ttl             = aws_route53_record.validation[d].ttl
        type            = aws_route53_record.validation[d].type
        zone_id         = aws_route53_record.validation[d].zone_id
      }
    }
  }
}
