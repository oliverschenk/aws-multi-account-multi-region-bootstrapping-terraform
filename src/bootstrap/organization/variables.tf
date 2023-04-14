variable "terraform_init_user_name" {
  default = "terraform-init"
}

variable "use_existing_organization" {
  type    = bool
  default = true
}

variable "administrator_default_arn" {}

# variable "billing_default_arn" {}
# variable "billing_role_name" {}

variable "management_aws_region" {}

variable "terraform_state_bucket_name" {}
variable "terraform_state_bucket_region" {}
variable "terraform_state_dynamodb_table" {}
variable "terraform_deployment_role_name" {}

variable "security_account_email" {}
variable "deployment_account_email" {}
variable "development_account_email" {}
variable "logging_account_email" {}
variable "shared_services_account_email" {}
