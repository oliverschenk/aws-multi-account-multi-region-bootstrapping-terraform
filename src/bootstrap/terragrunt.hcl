locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  environment = local.common_vars.management_aws_region
  
  terraform_state_bucket_name = "${local.common_vars.namespace}-${local.common_vars.name}-${local.common_vars.terraform_state_bucket_region}-deployment-${local.common_vars.terraform_state_bucket}"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.terraform_state_bucket_name
    key            = local.common_vars.management_terraform_state_path
    region         = local.common_vars.terraform_state_bucket_region
    role_arn       = "arn:aws:iam::${get_env("TF_AWS_ACCT", "")}:role/OrganizationAccountAccessRole"
    encrypt        = true
    dynamodb_table = local.common_vars.terraform_state_dynamodb_table
    s3_bucket_tags = {
      owner = "terraform"
      name  = "Terraform state storage"
    }
    dynamodb_table_tags = {
      owner = "terraform"
      name  = local.common_vars.terraform_state_dynamodb_table
    }
  }
}

inputs = merge(
  local.common_vars,
  {
    terraform_state_bucket_name = local.terraform_state_bucket_name,
    environment = local.environment 
  }
)
