remote_state {
  backend = "s3"
  config = {
    bucket         = "<bucket_name>"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "<aws_region>"
    encrypt        = true
    dynamodb_table = "<terragrunt-locks-table>"
  }
}
