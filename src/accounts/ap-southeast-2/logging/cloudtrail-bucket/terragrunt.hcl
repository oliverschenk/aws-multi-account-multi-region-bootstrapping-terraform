include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//cloudtrail-bucket"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  id = "${local.common_vars.namespace}-${local.region_vars.locals.aws_region}-${local.common_vars.name}"

  lifecycle_configuration_rule = {
    enabled = true
    id      = "${local.id}-organization-trail-lifecycle-rule"

    abort_incomplete_multipart_upload_days = 1

    filter_and = null
    expiration = {
      days = 90
    }

    transition = []
    noncurrent_version_expiration = null
    noncurrent_version_transition = []
  }
}

inputs = {
  enabled = true

  name = "${local.common_vars.name}-organization-trail"
  
  versioning_enabled            = true
  lifecycle_configuration_rules = [local.lifecycle_configuration_rule]
}

