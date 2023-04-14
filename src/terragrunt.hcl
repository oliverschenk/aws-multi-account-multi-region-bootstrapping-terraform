locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "ignore"), {locals = { aws_region = local.common_vars.management_aws_region}})
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"), {})

  account_ids = jsondecode(file("accounts.json"))

  terraform_state_bucket_name = "${local.common_vars.namespace}-${local.common_vars.name}-${local.common_vars.terraform_state_bucket_region}-deployment-${local.common_vars.terraform_state_bucket}" 
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
provider "aws" {
  alias  = "noassume"
  region = "${local.region_vars.locals.aws_region}"
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids[local.account_vars.locals.account_name]}:role/${local.common_vars.terraform_deployment_role_name}"
  }

  region = "${local.region_vars.locals.aws_region}"
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.terraform_state_bucket_name
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.common_vars.terraform_state_bucket_region
    role_arn       = "arn:aws:iam::${get_env("TF_AWS_ACCT", get_aws_account_id())}:role/TerraformAdministrator"
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
  generate = {    
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.common_vars,
  local.account_vars.locals,
  local.region_vars.locals,
  { terraform_state_bucket_name = local.terraform_state_bucket_name }
)
