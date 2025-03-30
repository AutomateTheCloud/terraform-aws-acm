variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = ""
}

variable "enable_certificate_transparency_log" {
  description = "Enable Certificate Transparency Log"
  type        = bool
  default     = true
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names"
  type        = list(any)
  default     = []
}

variable "validation_method" {
  description = "Validation Method (DNS, EMAIL)"
  type        = string
  default     = "DNS"
  validation {
    condition     = can(regex("^(DNS|EMAIL)$", var.validation_method))
    error_message = "Validation Method - Invalid input, options: \"DNS\", \"EMAIL\"."
  }
}

variable "validation_zone_id" {
  description = "Validation Zone ID (leave blank to skip validation)"
  type        = string
  default     = ""
}

variable "wait_for_validation" {
  description = "Whether to wait for the validation to complete"
  type        = bool
  default     = true
}
