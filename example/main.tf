terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: ACM
module "acm" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "ACM - test-acm.demo.ee.nss-aws.com"
    environment         = "prd"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  # domain_name                         = "uetl.ultradata-aws.neustar"
  # subject_alternative_names           = [
    # "test-prd.example-ssl-domain.com",
    # "test-qa.example-ssl-domain.com",
    # "test-dev.example-ssl-domain.com"
  # ]

  domain_name                         = "test-acm.demo.ee.nss-aws.com"
  subject_alternative_names           = [
    "test-acm-prd.demo.ee.nss-aws.com"
  ]
  validation_method                   = "DNS"
  enable_certificate_transparency_log = true

  # validation_zone_id                  = ""
  validation_zone_id                  = "Z01884772ANE9SSJX2C0M"
  wait_for_validation                 = true
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.acm.metadata
}
