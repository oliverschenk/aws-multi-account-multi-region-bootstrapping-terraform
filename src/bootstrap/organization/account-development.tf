###############################################################################
# Everything in this document is deployed into the Development account from the
# management account context using the OrganizationAccountAccessRole role
###############################################################################
provider "aws" {
  alias = "assume_development"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.development.id}:role/OrganizationAccountAccessRole"
  }

  region = var.management_aws_region
}

###############################################################################
# Create a Terraform deployment role based on the default AWS Administrator
# policy and allow it to be assumed by the Deployment account
###############################################################################
module "deployment_assume_development_terraform_deployment_role" {
  source = "../../modules/cross-account-role"

  providers = {
    aws = aws.assume_development
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = var.terraform_deployment_role_name
  role_policy_arn         = var.administrator_default_arn

  tags = module.this.tags
}