terraform {
  source = "../../../modules/vpc"
}

include {
  path = find_in_parent_folders()
}

locals {
  account_vars     = yamldecode(file(find_in_parent_folders("account.yaml", find_in_parent_folders("empty.yaml"))))
  environment_vars = yamldecode(file(find_in_parent_folders("env.yaml", find_in_parent_folders("empty.yaml"))))
  # config.yaml sits next to this file. find_in_parent_folders() only looks in parent folders.
  config_vars = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

inputs = {
  aws_region      = local.account_vars.aws_region
  environment     = local.environment_vars.environment
  vpc_cidr        = local.config_vars.vpc_cidr
  private_subnets = local.config_vars.private_subnets
  public_subnets  = local.config_vars.public_subnets
}
