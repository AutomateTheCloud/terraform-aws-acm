# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
      # Route 53 validation records can live in another AWS account, so they use
      # their own provider configuration. Pass `aws.dns = aws` when the zone is in
      # the certificate's account.
      configuration_aliases = [aws.dns]
    }
  }
}
