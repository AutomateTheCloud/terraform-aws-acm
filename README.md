# Terraform module for AWS Certificate Manager certificates

Creates a public TLS certificate in AWS Certificate Manager (ACM), and can validate it through a Route 53 hosted zone, including a zone in another AWS account.

A certificate created with only the required inputs is validated by DNS, which lets ACM renew it automatically, and is recorded in public certificate transparency logs, which browsers require.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Domain names | One, required | `domain_name`, `subject_alternative_names` |
| Validation method | DNS | `validation_method` |
| DNS validation records | None: you add them | `route53_validation` |
| Wait until issued | Yes, when the module creates the records | `route53_validation.wait_for_validation` |
| Certificate transparency logging | On | `enable_certificate_transparency_log` |
| Region | The provider's | `region` |

## Usage

```hcl
module "acm" {
  source  = "AutomateTheCloud/acm/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.dns = aws }

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  domain_name               = "example.org"
  subject_alternative_names = ["www.example.org"]
  route53_validation        = { zone_id = "Z0123456789ABCDEFGHIJ" }
}
```

`details` and `domain_name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on the certificate.

### Providers

The module takes two provider configurations, and every call must pass both:

- `aws` creates the certificate, and waits for it to be issued.
- `aws.dns` creates the validation records in the Route 53 hosted zone.

When the hosted zone is in the same account as the certificate, pass the same provider twice: `providers = { aws = aws, aws.dns = aws }`. When the zone is in another account, pass a provider for that account as `aws.dns`. The [cross-account example](https://github.com/AutomateTheCloud/terraform-aws-acm/tree/main/examples/cross-account) shows how.

The certificate is created in the `aws` provider's Region. To create it somewhere else without configuring another provider, set `region`. CloudFront uses certificates only from `us-east-1`:

```hcl
module "acm_cloudfront" {
  source  = "AutomateTheCloud/acm/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.dns = aws }

  region                    = "us-east-1"
  details                   = { scope = "Automate the Cloud", purpose = "Web Site", environment = "Production" }
  domain_name               = "example.org"
  subject_alternative_names = ["*.example.org"]
  route53_validation        = { zone_id = "Z0123456789ABCDEFGHIJ" }
}
```

Route 53 is a global service, so the Region of the `aws.dns` provider does not matter.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the certificate belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a certificate in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the certificate, the load balancer using it, its DNS zone and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_certificate" {
  source  = "AutomateTheCloud/acm/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.dns = aws }

  details     = local.details
  domain_name = "example.org"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_certificate.metadata.acm_certificate.arn` for the certificate's ARN, or `module.site_certificate.metadata.aws.region.abbr` for the Region's short form.
## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. Each needs a domain with a public Route 53 hosted zone.

- [Basic certificate](https://github.com/AutomateTheCloud/terraform-aws-acm/tree/main/examples/basic): a domain and its `www` subdomain, validated through a hosted zone in the same account.
- [Cross-account validation](https://github.com/AutomateTheCloud/terraform-aws-acm/tree/main/examples/cross-account): a certificate in one account, validated through a hosted zone in another.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-acm/tree/main/examples/complete): a wildcard certificate for CloudFront, in `us-east-1`, with most of the module's inputs.

## Things to know

### Validating without Route 53

Without `route53_validation`, the module requests the certificate and stops: ACM issues it once the validation records exist. Add a CNAME record for each entry in the `metadata` output's `acm_certificate.domain_validation_options`, using its `resource_record_name` and `resource_record_value`, to whichever DNS service hosts the domain. Keep the records in place: ACM checks them again before it renews the certificate.

With `validation_method = "EMAIL"`, ACM sends an approval email to the domain's registered contacts and to addresses such as `admin@` and `webmaster@`. Someone has to approve it, and again before each renewal, so DNS validation is the better choice wherever you control the DNS.

### One hosted zone

`route53_validation.zone_id` is one hosted zone, and every name on the certificate must be in it. For a certificate that covers names in two zones, create the records yourself, as described above.

### Wildcards

`*.example.org` covers `www.example.org` and `api.example.org`, but not `example.org` itself or `a.b.example.org`. To cover the domain as well, list both. They share one validation record, so the module creates one.

### Changing the domain names

Changing `domain_name` or `subject_alternative_names` replaces the certificate, because ACM cannot change a certificate's names. The module creates the new certificate first, so load balancers and CloudFront distributions that reference it by ARN switch over before the old one is deleted. The validation records of names that stay on the certificate are kept, because ACM uses the same record for a domain name in every certificate in an account; only added names get new records.

### Shared validation records

Every certificate for the same domain name in an account gets the same validation record, so the module overwrites a record that already exists. Destroying the module deletes that record, and another certificate for the same name then cannot renew until the record is created again, for example by applying its own configuration.

### Certificate transparency logs

Certificate transparency logs are public. Anyone can search them for the domain names on your certificates, so do not put a name you want kept private on a public certificate.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-acm/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-acm/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-acm#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The fully qualified domain name the certificate is for, such as `example.com`, or a wildcard such as `*.example.com`. A wildcard covers one level of subdomains (`www.example.com`) but not the domain itself; add `example.com` to `subject_alternative_names` to cover both.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_enable_certificate_transparency_log"></a> [enable_certificate_transparency_log](#input_enable_certificate_transparency_log)

Description: Record the certificate in public certificate transparency logs. Browsers such as Chrome and Safari reject a public certificate that is not logged, so turn this off only for a certificate that browsers never see. The logs are public, so they show the certificate's domain names. Defaults to `true`.

Type: `bool`

Default: `true`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the certificate in, such as `us-west-2`. Defaults to the Region of the default `aws` provider passed to the module. CloudFront uses only certificates in `us-east-1`.

Type: `string`

Default: `null`

#### <a name="input_route53_validation"></a> [route53_validation](#input_route53_validation)

Description: Create the DNS validation records in a Route 53 hosted zone. `null`, the default, creates no records: add the records listed in the `metadata` output's `acm_certificate.domain_validation_options` to your DNS yourself. Requires `validation_method = "DNS"`.

- `zone_id` - (Required) The ID of the hosted zone that holds every domain name on the certificate, such as `Z0123456789ABCDEFGHIJ`. The records are created with the module's `aws.dns` provider, so the zone can be in another AWS account.
- `wait_for_validation` - (Optional) Wait until ACM has issued the certificate before finishing the apply, so that resources using it can be created in the same run. Defaults to `true`. ACM can take several minutes, and the wait fails after 75 minutes.

Type:

```hcl
object({
    zone_id             = string
    wait_for_validation = optional(bool, true)
  })
```

Default: `null`

#### <a name="input_subject_alternative_names"></a> [subject_alternative_names](#input_subject_alternative_names)

Description: More domain names for the certificate to cover, such as `["www.example.com", "*.example.com"]`. ACM allows 10 names per certificate unless you request a quota increase. Defaults to none.

Type: `list(string)`

Default: `[]`

#### <a name="input_validation_method"></a> [validation_method](#input_validation_method)

Description: How you prove to ACM that you control the domain names: `DNS` (the default), by adding a CNAME record for each name, or `EMAIL`, by approving an email that ACM sends to the domain's registered contacts. DNS-validated certificates renew automatically while the records stay in place.

Type: `string`

Default: `"DNS"`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the certificate.
- `acm_certificate` - The certificate, including its `arn`, `status`, `domain_name`, `subject_alternative_names`, `not_after` (expiry), and `domain_validation_options`: the `resource_record_name`, `resource_record_type` and `resource_record_value` of the DNS record that validates each domain name. `status` and the validity dates are read when the certificate is created; when the module waits for validation, they still show `PENDING_VALIDATION` until the next plan or apply refreshes them.
- `acm_certificate_validation` - The `certificate_arn` and `validation_record_fqdns` once the certificate is issued. `null` unless the module waits for validation.
- `route53_record` - The validation records, keyed by domain name (without a leading `*.`), each with its `fqdn`, `name`, `type`, `records`, `ttl` and `zone_id`. `null` unless `route53_validation` is set.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-acm/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-acm/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
