terraform {
  source = "../../../modules/eks"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  # Lets init, validate and plan run before the VPC exists. Apply always uses the real outputs.
  mock_outputs = {
    vpc_id          = "vpc-00000000"
    private_subnets = ["subnet-00000000", "subnet-00000001"]
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

locals {
  account_vars     = yamldecode(file(find_in_parent_folders("account.yaml", find_in_parent_folders("empty.yaml"))))
  environment_vars = yamldecode(file(find_in_parent_folders("env.yaml", find_in_parent_folders("empty.yaml"))))
  # config.yaml sits next to this file. find_in_parent_folders() only looks in parent folders.
  config_vars = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

inputs = {
  aws_region          = local.account_vars.aws_region
  environment         = local.environment_vars.environment
  cluster_name        = local.config_vars.cluster_name
  cluster_version     = local.config_vars.cluster_version
  vpc_id              = dependency.vpc.outputs.vpc_id
  authentication_mode = local.config_vars.authentication_mode
  subnet_ids          = dependency.vpc.outputs.private_subnets
  access_entries      = local.config_vars.access_entries
  eks_managed_node_groups = {
    default = {
      ami_type       = local.config_vars.ami_type
      instance_types = local.config_vars.instance_types
      min_size       = local.config_vars.min_size
      max_size       = local.config_vars.max_size
      desired_size   = local.config_vars.desired_size
    }
  }
}
