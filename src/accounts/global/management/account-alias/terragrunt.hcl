include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//account-alias"
}

inputs = {
  account_alias = "management"
}