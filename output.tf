output "metadata" {
  description = "Metadata"
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

    acm = {
      id                        = aws_acm_certificate.this.id
      arn                       = aws_acm_certificate.this.arn
      domain_name               = aws_acm_certificate.this.domain_name
      subject_alternative_names = aws_acm_certificate.this.subject_alternative_names
      domain_validation_options = (var.validation_method == "DNS" ? aws_acm_certificate.this.domain_validation_options : null)
      validation_emails         = (var.validation_method == "EMAIL" ? aws_acm_certificate.this.validation_emails : null)
    }
  }
}
