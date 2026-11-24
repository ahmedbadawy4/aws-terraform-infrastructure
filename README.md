# AWS Terraform infrastructure

Terraform modules for an Amazon EKS cluster and a VPC, deployed with Terragrunt to two environments (dev and prod) that share one state backend. The repository also has an Atlantis server (Terraform creates the host, Ansible configures it) and pre-commit checks that run in GitHub Actions.

This is a reference setup to learn from and adapt. It is not a production setup. Read [Limits](#limits) before you reuse any part of it.

## Repository structure

| Path | What it holds |
|------|---------------|
| [aws/](./aws) | Terragrunt live config. `terragrunt.hcl` sets the shared S3 state backend. `dev/` and `prod/` each have `account.yaml`, `env.yaml`, and a `vpc/` and an `eks/` folder with `terragrunt.hcl` and `config.yaml`. `global.yaml` is not read by any file yet. |
| [modules/vpc](./modules/vpc) | Terraform module around `terraform-aws-modules/vpc/aws`: public and private subnets and one NAT gateway. |
| [modules/eks](./modules/eks) | Terraform module around `terraform-aws-modules/eks/aws`: cluster, managed node group and access entries. |
| [atlantis-server/terraform](./atlantis-server/terraform) | The EC2 host, security group and IAM role for Atlantis. |
| [atlantis-server/ansible](./atlantis-server/ansible) | Playbook that installs Docker and runs Atlantis, plus `files/repos.yaml`, the server-side Atlantis config. |
| [atlantis.yaml](./atlantis.yaml) | Atlantis repo config: four projects (dev and prod, vpc and eks), with vpc planned before eks. |
| [.github/workflows/infra-pipeline.yaml](./.github/workflows/infra-pipeline.yaml) | Manual Terragrunt plan or apply for one folder. |
| [.github/workflows/pre-commit.yaml](./.github/workflows/pre-commit.yaml) | Runs the pre-commit hooks on pull requests, on pushes to `main` and on demand. |
| [.pre-commit-config.yaml](./.pre-commit-config.yaml) | The hooks: Terragrunt and Terraform format, validate, tflint, terraform-docs, YAML check, and secret scans. |
| [example](./example) | The same two modules used directly with Terraform, without Terragrunt. |
| [makefile](./makefile) | Targets `atlantis-infra`, `atlantis-config` and `clean`. |
| [pre-commit-script.sh](./pre-commit-script.sh) | Runs pre-commit one folder at a time, then on the whole repository. |

## How the Terragrunt setup works

- Each folder `aws/<env>/<resource>/` has a `terragrunt.hcl` that points to a module and a `config.yaml` with the values for that resource (CIDR ranges for the VPC, cluster name, version, node sizes and access entries for EKS).
- `aws/<env>/env.yaml` sets the environment name. `aws/<env>/account.yaml` sets `aws_region`.
- The EKS folder reads the VPC outputs (`vpc_id`, `private_subnets`) through a Terragrunt `dependency` block, so the VPC must exist before the cluster.
- Both environments use the backend in `aws/terragrunt.hcl`. The state key is the folder path, for example `dev/vpc/terraform.tfstate`.
- The cluster name is `<environment>-<cluster_name>`, for example `dev-shared`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.4.6 (the version used by the pipelines and Atlantis)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) v0.67.14
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html), configured with credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [pre-commit](https://pre-commit.com/), [tflint](https://github.com/terraform-linters/tflint) and [terraform-docs](https://terraform-docs.io/) for the hooks
- [Ansible](https://docs.ansible.com/) with the `community.docker` collection, only for the Atlantis server (`ansible-galaxy collection install community.docker`)
- An S3 bucket and a DynamoDB table for the Terraform state and locks. Terragrunt can create them on the first `init` if your credentials allow it.

## Set up the configuration

1. Replace the placeholders in [aws/terragrunt.hcl](./aws/terragrunt.hcl): `<bucket_name>`, `<aws_region>` and `<terragrunt-locks-table>`.
2. Set `aws_region` in `aws/dev/account.yaml` and `aws/prod/account.yaml`.
3. Set the IAM role ARNs in `aws/dev/eks/config.yaml` and `aws/prod/eks/config.yaml` (`<admin-iam-role-arn>` and `<dev-iam-role-arn>`).
4. Check the other values in each `config.yaml`.

## How to deploy

### A. From your machine with Terragrunt

Deploy the VPC first, then the cluster:

```bash
cd aws/dev/vpc
terragrunt init
terragrunt apply
cd ../eks
terragrunt init
terragrunt apply
```

Then connect `kubectl` to the cluster:

```bash
aws eks update-kubeconfig --region <region> --name dev-shared
kubectl get nodes
```

Use `aws/prod/...` for the prod environment.

### B. With the GitHub Actions pipeline

The [infra pipeline](./.github/workflows/infra-pipeline.yaml) runs `terragrunt plan` or `terragrunt apply` for one folder. Start it from the Actions tab with **Run workflow**, then choose the folder (`aws/dev/vpc`, `aws/dev/eks`, `aws/prod/vpc` or `aws/prod/eks`) and the action.

- `plan` can run from any branch. `apply` runs only from `main`.
- It runs on a GitHub-hosted runner and gets AWS credentials through OIDC. No access keys are stored in GitHub.
- One run at a time for each folder, so two runs do not compete for the same state lock.

What you need to set up first:

1. An IAM OIDC identity provider for GitHub in each AWS account, and an IAM role that trusts this repository. The role needs access to the state bucket, the lock table and the resources it manages.
2. Two GitHub environments named `dev` and `prod`. Add required reviewers to `prod` to approve its runs.
3. In each environment, two variables: `AWS_ROLE_ARN` (the role to assume) and `AWS_REGION`.

### C. With Atlantis

[Atlantis](https://www.runatlantis.io/) runs `terragrunt plan` on pull requests and `terragrunt apply` when you ask for it in a comment.

1. Replace the backend placeholders in `atlantis-server/terraform/config.tf`.
2. Copy `atlantis-server/terraform/terraform.tfvars.example` to `terraform.tfvars` in the same folder and fill it in. Use your own IP range for `ssh_cidr_blocks`. Add an IAM policy for EKS to `additional_policy_arns` if Atlantis should manage the cluster.
3. Create the host:

   ```bash
   make atlantis-infra
   ```

4. Export the values the playbook reads, then configure the host:

   ```bash
   export ATLANTIS_GH_USER=<github-user>
   export ATLANTIS_GH_TOKEN=<github-token>
   export ATLANTIS_GH_WEBHOOK_SECRET=<webhook-secret>
   export ATLANTIS_REPO_ALLOWLIST=github.com/<owner>/<repository>
   make atlantis-config PRIVATE_KEY=<path-to-key.pem>
   ```

   The playbook installs Docker, downloads Terragrunt (checksum verified), copies [repos.yaml](./atlantis-server/ansible/files/repos.yaml) and starts the Atlantis container.

5. Add a webhook in the GitHub repository (Settings, Webhooks):
   - Payload URL: `http://<atlantis-public-ip>/events`
   - Content type: `application/json`
   - Secret: the same value as `ATLANTIS_GH_WEBHOOK_SECRET`
   - Events: Pull requests, Issue comments, Pull request reviews and Pushes

How it works on a pull request:

- Atlantis plans the projects whose files changed (`dev-vpc`, `dev-eks`, `prod-vpc`, `prod-eks`, defined in [atlantis.yaml](./atlantis.yaml)). The VPC projects run before the EKS projects.
- Comment `atlantis plan -p dev-vpc` to plan again. Comment `atlantis apply -p dev-vpc` to apply. The server config requires the pull request to be approved and mergeable before an apply.
- Atlantis does not apply on merge. Applies happen only when someone comments `atlantis apply`.
- Other commands: `atlantis unlock` and `atlantis help`.

On the first deploy of an environment, apply the VPC, then plan the cluster again (`atlantis plan -p dev-eks`) before you apply it. See [Limits](#limits) for the reason.

## Pre-commit checks

```bash
pre-commit install
pre-commit run --all-files
```

`./pre-commit-script.sh` does the same one folder at a time. The same hooks run through the [pre-commit workflow](./.github/workflows/pre-commit.yaml). On a pull request it checks only the files the pull request changed. On a push to `main`, or when you start it by hand from the Actions tab, it checks every file.

## How to destroy

Destroy in the reverse order of the deploy, and never delete the VPC while a cluster uses it:

```bash
cd aws/dev/eks
terragrunt destroy
cd ../vpc
terragrunt destroy
```

To remove the Atlantis host, run `terraform destroy` in `atlantis-server/terraform`.

## Limits

This is a reference setup. These are design limits you should know before you reuse it.

**State and environments**
- Dev and prod write to the same state bucket and lock table (the keys differ). Any role that can read and write the bucket can change the state of both environments, so restrict access by key prefix if you need a stronger split.
- The dev and prod VPCs use the same CIDR ranges in their `config.yaml` files. Change one of them if you ever need to connect the two networks.
- Only `aws_region` is read from `account.yaml`. `aws_account_id`, `account_name` and `aws/global.yaml` are not used yet.
- The modules live in this repository and are not versioned with tags. A change to a module reaches every environment that uses it.
- When Terragrunt plans the cluster before the VPC exists, it uses mock VPC outputs. A plan saved that way cannot be applied. Apply the VPC first, then plan the cluster again.

**Network and cluster**
- The cluster API endpoint is public by default (`cluster_endpoint_public_access = true`). Set it to `false` and arrange private access for your runners if you need a private endpoint.
- The VPC has one NAT gateway, so all private subnets share one point of failure. The subnets have no role tags for load balancers.
- The identity that creates the cluster becomes a cluster admin (`enable_cluster_creator_admin_permissions` is `true`).
- The nodes are two to four `m5.xlarge` instances in one managed node group.
- Kubernetes 1.35 is set in the `config.yaml` files. Its standard support ends in March 2027, so plan an upgrade before then.

**Atlantis server**
- Atlantis runs on one `t3.small` instance in the default VPC of the region. It is a single point of failure and has limited capacity for parallel plans.
- It serves plain HTTP on port 80. The `sg_cidr_blocks` default is open to the internet. GitHub webhooks come from published IP ranges, so restrict the range where you can.
- The Atlantis web page has no login. The webhook secret protects only the `/events` endpoint.
- The instance role allows `s3:*`, `dynamodb:*` and `ec2:*` on all resources. It has no EKS or IAM permissions, so add them with `additional_policy_arns` (or switch to assuming roles) before Atlantis can manage the cluster. Narrow the wildcards for any real use.
- The server config applies to every repository in `ATLANTIS_REPO_ALLOWLIST`. Keep that list short.
- The Atlantis version, Terraform version and Terragrunt version are pinned in the playbook. Update them together with the pipelines.
