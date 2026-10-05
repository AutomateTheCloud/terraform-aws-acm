# Basic certificate

A certificate for a domain and its `www` subdomain, such as `example.org` and `www.example.org`. The module adds the DNS validation records to the domain's Route 53 hosted zone, in the same AWS account, and waits until ACM has issued the certificate.

The hosted zone must already exist and be the zone the domain's registrar points to. If it is not, ACM cannot see the records, and the apply fails after 75 minutes.

## Run it

```shell
terraform init
terraform apply -var 'domain_name=<your domain>'
```

Remove it with `terraform destroy` and the same `-var`. A certificate still attached to a load balancer or CloudFront distribution cannot be deleted.

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

#### <a name="output_certificate_arn"></a> [certificate_arn](#output_certificate_arn)

Description: ARN of the issued certificate
<!-- END_TF_DOCS -->
