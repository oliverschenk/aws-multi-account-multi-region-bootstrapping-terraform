variable "keybase" {
  description = "Enter the keybase profile to encrypt the secret_key (to decrypt: terraform output secret_key | base64 --decode | keybase pgp decrypt)"
}

variable "management_aws_region" {}
variable "management_terraform_state_path" {}

variable "terraform_state_account_id" {}
variable "terraform_state_bucket_name" {}
variable "terraform_state_bucket_region" {}
