# Atlantis server (Terraform)

Creates one EC2 instance for [Atlantis](https://www.runatlantis.io/). The Ansible playbook in `../ansible` then installs Docker and starts the Atlantis container.

## What it creates

- An Amazon Linux 2023 instance (`t3.small` by default) in the default VPC of the chosen region. It uses IMDSv2 only and an encrypted 30 GB gp3 root volume.
- A security group: HTTP (80) from `sg_cidr_blocks`, SSH (22) from `ssh_cidr_blocks`, all outbound traffic.
- An IAM role and instance profile. The inline policy allows S3, DynamoDB and EC2. Attach more policies, for example one for EKS, with `additional_policy_arns`.

## How to use it

1. Replace the backend placeholders in `config.tf` with your state bucket, key, region and lock table.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill it in.
3. From the repository root, run `make atlantis-infra`. It runs `terraform init` and `terraform apply`, then saves the public IP to `ec2_ip.txt`.
4. Run `make atlantis-config PRIVATE_KEY=<path-to-key.pem>` to configure the server with Ansible. See the root README for the environment variables the playbook needs.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.atlantis_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.atlantis_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.atlantis_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.atlantis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.atlantis_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.amazon_linux_2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | Extra IAM policy ARNs to attach to the Atlantis instance role, for example a policy that allows managing EKS. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | the AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | the AWS tags to apply to all resources | `map(any)` | `{}` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | the business unit name | `string` | `"SRE"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | the environment name | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | `"t3.small"` | no |
| <a name="input_sg_cidr_blocks"></a> [sg\_cidr\_blocks](#input\_sg\_cidr\_blocks) | CIDR blocks allowed to reach Atlantis on port 80. GitHub sends webhooks from its published IP ranges, so restrict this where possible. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_ssh_cidr_blocks"></a> [ssh\_cidr\_blocks](#input\_ssh\_cidr\_blocks) | CIDR blocks allowed to reach SSH on port 22. Ansible needs this to configure the server. | `list(string)` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair for accessing EC2 | `string` | n/a | yes |
| <a name="input_team"></a> [team](#input\_team) | the team name | `string` | `"SRE"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_atlantis_server_public_ip"></a> [atlantis\_server\_public\_ip](#output\_atlantis\_server\_public\_ip) | The public IP of the Atlantis server |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
