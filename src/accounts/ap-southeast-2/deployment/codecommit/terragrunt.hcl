include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//codecommit"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

inputs = {
  repository_name = "repository"
  repository_description = "Code repository for ${title(local.common_vars.namespace)} ${title(local.common_vars.name)} infrastructure"
}
