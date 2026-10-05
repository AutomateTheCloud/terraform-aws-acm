# Certificate validated through another account

A certificate in one AWS account, validated through a Route 53 hosted zone in another. Many organizations keep their DNS in one account and their applications in others.

The configuration has two providers. The default `aws` provider creates the certificate. The `aws.dns` provider assumes a role in the DNS account and creates the validation records there. The module receives both through `providers = { aws = aws, aws.dns = aws.dns }`.

The role in the DNS account must trust the identity that runs Terraform, and allow `route53:GetHostedZone`, `route53:ListHostedZones`, `route53:ListResourceRecordSets`, `route53:ChangeResourceRecordSets` and `route53:GetChange`. Limit `ChangeResourceRecordSets` to the one hosted zone.

## Run it

```shell
terraform init
terraform apply -var 'domain_name=<your domain>' -var 'dns_role_arn=<role ARN in the DNS account>'
```

Remove it with `terraform destroy` and the same `-var` options.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_dns_role_arn"></a> [dns_role_arn](#input_dns_role_arn)

Description: ARN of an IAM role in the DNS account that this configuration can assume, and that may change records in the hosted zone

Type: `string`

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: A domain name with a public Route 53 hosted zone in the DNS account, such as example.org

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_certificate_arn"></a> [certificate_arn](#output_certificate_arn)

Description: ARN of the issued certificate
<!-- END_TF_DOCS -->
