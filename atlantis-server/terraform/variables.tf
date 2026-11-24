variable "environment" {
  description = "the environment name"
  type        = string
}

variable "team" {
  description = "the team name"
  type        = string
  default     = "SRE"
}

variable "business_unit" {
  description = "the business unit name"
  type        = string
  default     = "SRE"
}

variable "aws_tags" {
  description = "the AWS tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "aws_region" {
  description = "the AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for accessing EC2"
  type        = string
}

variable "sg_cidr_blocks" {
  description = "CIDR blocks allowed to reach Atlantis on port 80. GitHub sends webhooks from its published IP ranges, so restrict this where possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH on port 22. Ansible needs this to configure the server."
  type        = list(string)
}

variable "additional_policy_arns" {
  description = "Extra IAM policy ARNs to attach to the Atlantis instance role, for example a policy that allows managing EKS."
  type        = list(string)
  default     = []
}
