###############################################################################
# Everything in this document is deployed into the Logging account from the
# management account context using the OrganizationAccountAccessRole role
###############################################################################
provider "aws" {
  alias = "assume_logging"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.logging.id}:role/OrganizationAccountAccessRole"
  }

  region = var.management_aws_region
}

###############################################################################
# Create a Terraform deployment role based on the default AWS Administrator
# policy and allow it to be assumed by the Deployment account
###############################################################################
module "deployment_assume_logging_terraform_deployment_role" {
  source = "../../modules/cross-account-role"

  providers = {
    aws = aws.assume_logging
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = var.terraform_deployment_role_name
  role_policy_arn         = var.administrator_default_arn

  tags = module.this.tags
}

