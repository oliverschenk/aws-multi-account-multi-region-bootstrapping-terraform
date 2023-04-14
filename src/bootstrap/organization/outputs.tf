output "account_ids" {
  value = {
    management      = data.aws_caller_identity.current.account_id
    security        = aws_organizations_account.security.id
    deployment      = aws_organizations_account.deployment.id
    development     = aws_organizations_account.development.id
    logging         = aws_organizations_account.logging.id
    shared-services = aws_organizations_account.shared_services.id
  }
  description = "Map of accounts created in the organization including the management account"
}

output "crossaccount_assume_from_deployment_account_policy_json" {
  value = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
}

output "security_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_security_terraform_deploy.policy_arn
}

output "deployment_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_deployment_terraform_deploy.policy_arn
}

output "development_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_development_terraform_deploy.policy_arn
}

output "shared_services_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_shared_services_terraform_deploy.policy_arn
}

output "management_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_management_terraform_deploy.policy_arn
}

output "logging_terraform_deploy_role_policy_arn" {
  value = module.assume_role_policy_logging_terraform_deploy.policy_arn
}

output "terraform_admin_role_policy_arn" {
  value = module.assume_role_policy_terraform_admin.policy_arn
}

output "terraform_reader_role_policy_arn" {
  value = module.assume_role_policy_terraform_reader.policy_arn
}
