# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-acm#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "domain_name" {
  description = <<-EOT
    The fully qualified domain name the certificate is for, such as `example.com`, or a wildcard such as `*.example.com`. A wildcard covers one level of subdomains (`www.example.com`) but not the domain itself; add `example.com` to `subject_alternative_names` to cover both.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.domain_name) <= 253 && can(regex("^(\\*\\.)?([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", var.domain_name))
    error_message = "domain_name must be a fully qualified domain name, such as example.com or *.example.com, with no trailing period."
  }
}

variable "enable_certificate_transparency_log" {
  description = <<-EOT
    Record the certificate in public certificate transparency logs. Browsers such as Chrome and Safari reject a public certificate that is not logged, so turn this off only for a certificate that browsers never see. The logs are public, so they show the certificate's domain names. Defaults to `true`.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the certificate in, such as `us-west-2`. Defaults to the Region of the default `aws` provider passed to the module. CloudFront uses only certificates in `us-east-1`.
  EOT
  type        = string
  default     = null
}

variable "route53_validation" {
  description = <<-EOT
    Create the DNS validation records in a Route 53 hosted zone. `null`, the default, creates no records: add the records listed in the `metadata` output's `acm_certificate.domain_validation_options` to your DNS yourself. Requires `validation_method = "DNS"`.

    - `zone_id` - (Required) The ID of the hosted zone that holds every domain name on the certificate, such as `Z0123456789ABCDEFGHIJ`. The records are created with the module's `aws.dns` provider, so the zone can be in another AWS account.
    - `wait_for_validation` - (Optional) Wait until ACM has issued the certificate before finishing the apply, so that resources using it can be created in the same run. Defaults to `true`. ACM can take several minutes, and the wait fails after 75 minutes.
  EOT
  type = object({
    zone_id             = string
    wait_for_validation = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.route53_validation == null || var.validation_method == "DNS"
    error_message = "route53_validation requires validation_method = \"DNS\"."
  }

  validation {
    condition     = var.route53_validation == null || try(trimspace(var.route53_validation.zone_id) != "", false)
    error_message = "route53_validation.zone_id must be a hosted zone ID."
  }
}

variable "subject_alternative_names" {
  description = <<-EOT
    More domain names for the certificate to cover, such as `["www.example.com", "*.example.com"]`. ACM allows 10 names per certificate unless you request a quota increase. Defaults to none.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for n in var.subject_alternative_names :
      length(n) <= 253 && can(regex("^(\\*\\.)?([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", n))
    ])
    error_message = "Each subject alternative name must be a fully qualified domain name, such as www.example.com or *.example.com, with no trailing period."
  }
}

variable "validation_method" {
  description = <<-EOT
    How you prove to ACM that you control the domain names: `DNS` (the default), by adding a CNAME record for each name, or `EMAIL`, by approving an email that ACM sends to the domain's registered contacts. DNS-validated certificates renew automatically while the records stay in place.
  EOT
  type        = string
  default     = "DNS"
  nullable    = false

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "validation_method must be \"DNS\" or \"EMAIL\"."
  }
}
