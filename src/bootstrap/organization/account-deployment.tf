###############################################################################
# Everything in this document is deployed into the Deployment account from
# the management account context using the OrganizationAccountAccessRole role
###############################################################################
provider "aws" {
  alias = "assume_deployment"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.deployment.id}:role/OrganizationAccountAccessRole"
  }

  region = var.management_aws_region
}

###############################################################################
# Create a Terraform deployment role based on the default AWS Administrator
# policy and allow it to be assumed by a role in the Deployment account
###############################################################################
module "deployment_assume_deployment_terraform_deployment_role" {
  source = "../../modules/cross-account-role"

  providers = {
    aws = aws.assume_deployment
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = var.terraform_deployment_role_name
  role_policy_arn         = var.administrator_default_arn

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Deployment account.
###############################################################################
module "assume_role_policy_deployment_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.deployment.name
  account_id   = aws_organizations_account.deployment.id
  role_name    = module.deployment_assume_deployment_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Management account.
###############################################################################
module "assume_role_policy_management_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = "Management"
  account_id   = data.aws_caller_identity.current.account_id
  role_name    = module.deployment_assume_management_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Security account.
###############################################################################
module "assume_role_policy_security_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.security.name
  account_id   = aws_organizations_account.security.id
  role_name    = module.deployment_assume_security_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Shared Services account.
###############################################################################
module "assume_role_policy_shared_services_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.shared_services.name
  account_id   = aws_organizations_account.shared_services.id
  role_name    = module.deployment_assume_shared_services_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Development account.
###############################################################################
module "assume_role_policy_development_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.development.name
  account_id   = aws_organizations_account.development.id
  role_name    = module.deployment_assume_development_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the Terraform
# deployment role in the Logging account.
###############################################################################
module "assume_role_policy_logging_terraform_deploy" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.logging.name
  account_id   = aws_organizations_account.logging.id
  role_name    = module.deployment_assume_logging_terraform_deployment_role.role_name

  tags = module.this.tags
}

###############################################################################
# Create a TerraformAdminAccess policy for Terraform read/write access based
# on the terraform_admin policy document
###############################################################################
resource "aws_iam_policy" "terraform_admin" {
  name        = "TerraformAdminAccess"
  policy      = data.aws_iam_policy_document.terraform_admin.json
  description = "Grants permissions needed by Terraform to manage Terraform remote state"
  provider    = aws.assume_deployment

  tags = module.this.tags
}

###############################################################################
# Create a TerraformAdmin role in the Deployment account that is
# allowed to be assumed from the Deployment account
###############################################################################
module "cross_account_role_terraform_admin" {
  source = "../../modules/cross-account-role"

  providers = {
    aws = aws.assume_deployment
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = "TerraformAdministrator"
  role_policy_arn         = aws_iam_policy.terraform_admin.arn

  tags = module.this.tags
}

###############################################################################
# Create a TerraformReadAccess policy for Terraform read access based on the
# terraform_reader policy document
###############################################################################
resource "aws_iam_policy" "terraform_reader" {
  name        = "TerraformReadAccess"
  policy      = data.aws_iam_policy_document.terraform_reader.json
  description = "Grants permissions to read Terraform remote state"
  provider    = aws.assume_deployment
  
  tags = module.this.tags
}

###############################################################################
# Create a TerraformReader role in the Deployment account that is
# allowed to be assumed from the Deployment accounts.
###############################################################################
module "cross_account_role_terraform_reader" {
  source = "../../modules/cross-account-role"

  providers = {
    aws = aws.assume_deployment
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = "TerraformReader"
  role_policy_arn         = aws_iam_policy.terraform_reader.arn

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the TerraformAdmin
# role in the Deployment account
###############################################################################
module "assume_role_policy_terraform_admin" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.deployment.name
  account_id   = aws_organizations_account.deployment.id
  role_name    = module.cross_account_role_terraform_admin.role_name

  tags = module.this.tags
}

###############################################################################
# Policy that allows the Deployment account to assume the TerraformReader
# role in the Deployment account
###############################################################################
module "assume_role_policy_terraform_reader" {
  source = "../../modules/assume-role-policy"

  providers = {
    aws = aws.assume_deployment
  }

  account_name = aws_organizations_account.deployment.name
  account_id   = aws_organizations_account.deployment.id
  role_name    = module.cross_account_role_terraform_reader.role_name

  tags = module.this.tags
}
