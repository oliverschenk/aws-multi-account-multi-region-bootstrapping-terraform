###############################################################################
# The temp_admin user is created and removed by the init script and thus only
# exists during the execution of the init script. It should only be stored in
# local state.
###############################################################################
terraform {
  backend "local" {}
}

###############################################################################
# Get the data object representing the organization state from the Shared
# Services account where Terraform state is stored
###############################################################################
data "terraform_remote_state" "organization" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket_name
    key      = var.management_terraform_state_path
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${var.terraform_state_account_id}:role/OrganizationAccountAccessRole"
  }
}

###############################################################################
# Define a provider for accessing the Security account using the default
# OrganizationAccountAccessRole role. All the resources in this file are to be
# deployed into the Security account
###############################################################################
provider "aws" {
  alias = "assume_deployment"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.account_ids["deployment"]}:role/OrganizationAccountAccessRole"
  }

  region = var.management_aws_region
}

###############################################################################
# Create a temp_admin user
###############################################################################
resource "aws_iam_user" "temp_admin" {
  name          = "temp-admin"
  force_destroy = true

  provider = aws.assume_deployment

  tags = module.this.tags
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Security account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_security_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.security_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Deployment account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_deployment_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.deployment_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Development account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_development_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.development_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Shared Services account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_shared_services_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.shared_services_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Management account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_management_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.management_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform deployment role in the
# Management account for deploying initial account resources
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_terraform_deploy_role_logging_account" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.logging_terraform_deploy_role_policy_arn

  provider = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform Admin role in the
# Deployment account for reading/writing Terraform state
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_role_terraform_admin" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.terraform_admin_role_policy_arn
  provider   = aws.assume_deployment
}

###############################################################################
# Allow the temp_admin user to assume the Terraform Reader role in the
# Deployment account for reading Terraform state
###############################################################################
resource "aws_iam_user_policy_attachment" "assume_role_terraform_reader" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.terraform_reader_role_policy_arn
  provider   = aws.assume_deployment
}

###############################################################################
# Grant the temp_admin user CodeCommit permissions in order to be able to
# commit the initial repository into CodeCommit
###############################################################################
resource "aws_iam_user_policy_attachment" "code_commit_access" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"

  provider = aws.assume_deployment
}

###############################################################################
# Create a temporary set of access credentials for the temp_admin user in the
# Deployment account and encrypt the secret access key using Keybase PGP
###############################################################################
resource "aws_iam_access_key" "temp_admin" {
  user    = aws_iam_user.temp_admin.name
  pgp_key = "keybase:${var.keybase}"

  provider = aws.assume_deployment
}
