# Certificate for CloudFront

A certificate for a domain and every subdomain one level below it (`example.org` and `*.example.org`), ready for a CloudFront distribution. CloudFront uses certificates only from `us-east-1`, so the example sets `region = "us-east-1"` while its provider works in `us-west-2`: one provider is enough.

It also shows the rest of the module's inputs: abbreviation overrides and an extra tag in `details`, certificate transparency logging, and waiting for validation. The wildcard and the domain itself share one validation record, so the module creates one record, not two.

## Run it

```shell
terraform init
terraform apply -var 'domain_name=<your domain>'
```

Remove it with `terraform destroy` and the same `-var`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: A domain name with a public Route 53 hosted zone in this account, such as example.org

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_certificate"></a> [certificate](#output_certificate)

Description: ARN, Region and expiry of the issued certificate
<!-- END_TF_DOCS -->
