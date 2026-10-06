# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A public ACM certificate for a domain name and its subject alternative names, including wildcards.
- DNS or email validation, with certificate transparency logging on by default.
- DNS validation records in a Route 53 hosted zone, through a separate `aws.dns` provider so the zone can be in another AWS account, and an optional wait until the certificate is issued.
- `region`, to create the certificate in a Region other than the provider's, such as `us-east-1` for CloudFront.
- A `metadata` output with everything the module created, including the validation records for DNS services other than Route 53.
- Offline tests, and examples for a basic certificate, validation through another account, and a wildcard certificate for CloudFront.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-acm/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-acm/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-acm/releases/tag/v1.0.0
