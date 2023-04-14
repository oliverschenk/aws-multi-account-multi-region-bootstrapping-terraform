terraform {
  backend "s3" {}
}

###############################################################################
# Gets the data object that represents the currently running identity context
###############################################################################
data "aws_caller_identity" "current" {}

###############################################################################
# Create a new organisation if use_existing_organization is false
###############################################################################
resource "aws_organizations_organization" "org" {
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
  feature_set          = "ALL"

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "sso.amazonaws.com"
  ]

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create OU for Security aspects
###############################################################################
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Infrastructure aspects
###############################################################################
resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Sandbox aspects
###############################################################################
resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Deployment aspects
###############################################################################
resource "aws_organizations_organizational_unit" "deployment" {
  name      = "Deployment"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Workload aspects
###############################################################################
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Production Workload aspects
###############################################################################
resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

###############################################################################
# Create OU for Test Workload aspects
###############################################################################
resource "aws_organizations_organizational_unit" "workloads_test" {
  name      = "Test"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

###############################################################################
# Create a Security account
# -------------------------
# The security account hosts the tools used by the Security team.
###############################################################################
resource "aws_organizations_account" "security" {
  name  = "Core Security Account"
  email = var.security_account_email

  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Development account
# ----------------------------
# The development account is a development sandbox.
###############################################################################
resource "aws_organizations_account" "development" {
  name  = "Core Development Account"
  email = var.development_account_email

  parent_id = aws_organizations_organizational_unit.sandbox.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Shared Services account
# --------------------------------
# The shared services account is responsible for identity management
###############################################################################
resource "aws_organizations_account" "shared_services" {
  name  = "Core Shared Services Account"
  email = var.shared_services_account_email

  parent_id = aws_organizations_organizational_unit.infrastructure.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Deployment account
# --------------------------------
# The deployment account holds the code repositorties and CI/CD pipelines.
###############################################################################
resource "aws_organizations_account" "deployment" {
  name  = "Core Deployment Account"
  email = var.deployment_account_email

  parent_id = aws_organizations_organizational_unit.deployment.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Logging account
# --------------------------------
# The logging account collects logs from all member accounts.
###############################################################################
resource "aws_organizations_account" "logging" {
  name  = "Core Logging Account"
  email = var.logging_account_email

  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Terraform deployment role based on the default AWS Administrator
# policy and allow it to be assumed by the Deployment account
###############################################################################
module "deployment_assume_management_terraform_deployment_role" {
  source = "../../modules/cross-account-role"

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = var.terraform_deployment_role_name
  role_policy_arn         = var.administrator_default_arn

  tags = module.this.tags
}
