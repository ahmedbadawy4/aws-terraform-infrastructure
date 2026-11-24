# Overview

This example provides a Terraform configuration for provisioning a new VPC and Amazon Elastic Kubernetes Service (EKS) cluster on AWS. It uses the same modules as the Terragrunt setup in `aws/`, without Terragrunt.

## Prerequisites
Before deploying the EKS cluster, ensure you have the following tools installed and configured on your local machine:

- [Terraform](https://www.terraform.io/downloads.html) (v1.4.6 is the version used in this repository; the modules need 1.3 or higher)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) (configured with credentials)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for managing the Kubernetes cluster)
- An S3 bucket and a DynamoDB table for the Terraform state. Set them in the backend block in `config.tf`:

  ```
  terraform {
    backend "s3" {
      bucket         = "<bucket_name>"
      key            = "<some_key_path>/terraform.tfstate"
      region         = "<region>"
      encrypt        = true
      dynamodb_table = "<dynamodb_table_name>"
    }
  .....
  }
  ```

### AWS IAM Permissions

You need appropriate AWS IAM permissions to create resources such as:

- EKS cluster
- VPC, subnets, and security groups
- IAM roles and policies
- EC2 instances for worker nodes

*Ensure your AWS credentials are properly set up either via the AWS CLI (`aws configure`) or via environment variables.*

## How to Deploy

#### 1. Configure Variables
Each variable can be customized. Create a `terraform.tfvars` file and add the values below:

```
environment             = "<environment_name>"
developer_principal_arn = "<developers SSO iam role arn>"
admin_principal_arn     = "<admin SSO iam role arn>"
ami_type                = "<node_group_ami_type>" # optional, the default is AL2023_x86_64_STANDARD
instance_types          = ["<instance_type>"]
min_size                = <min number of instances>
max_size                = <max number of instances>
desired_size            = <desired number of instances>
```
#### 2. Initialize Terraform
Run the following command to initialize Terraform, which will download the necessary modules and provider plugins:

```
terraform init
```

#### 3. Create an Execution Plan
The execution plan shows you what Terraform will do when you apply it. You can create the plan by running:

```
terraform plan --var-file=terraform.tfvars -out=tfplan -no-color
```
This will generate a plan file named `tfplan`, which you can inspect or save for later use.

#### 4. Apply the Plan
To deploy the EKS cluster and all associated resources, apply the generated plan:

```
terraform apply tfplan
```
This command will provision the resources in your AWS account. A saved plan already contains the variable values, so `apply` does not take `--var-file`.

#### 5. Configure `kubectl` to Access the EKS Cluster
Once the cluster is successfully created, you can use the AWS CLI to update your kubectl configuration to interact with the new EKS cluster:

```
aws eks --region <region> update-kubeconfig --name <cluster_name>
```
The cluster name is `<environment>-<cluster_name>`, for example `dev-eks-cluster` with the default `cluster_name`. This command configures kubectl to use the cluster.

#### 6. Verify the Cluster (Optional)
Use kubectl to verify that the cluster is running and accessible:

```
kubectl get nodes
```
This should display a list of worker nodes if everything was set up correctly.

## How to destroy the cluster (all the deployed infra)
If you need to delete all resources created by Terraform, run the following command:

```
terraform destroy --var-file=terraform.tfvars
```
This will tear down all infrastructure provisioned by this configuration.

## Troubleshooting

If you encounter issues during deployment:

1. Ensure your AWS credentials are configured and have sufficient permissions.
2. Ensure the S3 bucket that works as a backend is configured correctly and the local machine has access to it.
3. Check that your AWS region, VPC, and subnets are correct.
4. Look at the Terraform state and plan output for details on errors.
5. Re-run Terraform in debug mode to get more details, for example `TF_LOG=DEBUG TF_LOG_PATH=terraform_debug.log terraform apply`
6. Ensure the `kubectl` configuration is correctly pointing to the EKS cluster.
