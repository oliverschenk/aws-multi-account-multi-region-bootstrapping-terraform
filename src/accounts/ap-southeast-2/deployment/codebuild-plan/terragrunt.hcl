include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//terraform-codebuild"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  account_ids = jsondecode(file(find_in_parent_folders("accounts.json")))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  tf_deployment_roles = formatlist("arn:aws:iam::%s:role/${local.common_vars.terraform_deployment_role_name}", values(local.account_ids))
  tf_state_roles = [
    "arn:aws:iam::${local.account_ids.deployment}:role/TerraformAdministrator",
    "arn:aws:iam::${local.account_ids.deployment}:role/TerraformReader",
  ]
}

dependency "pipeline_prefix" {
  config_path = "../random-pipeline-prefix"
  mock_outputs = {
    result = "abc123"
  }
}

dependency "logging_bucket" {
  config_path = "../logging-bucket"
  mock_outputs = {
    s3_bucket_id = "mock-logging-bucket-name"
  }
}

dependency "artifacts_bucket" {
  config_path = "../artifacts-bucket"
  mock_outputs = {
    s3_bucket_id = "mock-artifacts-bucket-name"
  }
}

inputs = {
  pipeline_prefix = dependency.pipeline_prefix.outputs.result

  codebuild_project_name = "accounts-terraform-plan"
  buildspec = "src/buildspec-plan.yaml"

  assume_role_arns = concat(local.tf_deployment_roles, local.tf_state_roles)

  logging_bucket_id    = dependency.logging_bucket.outputs.s3_bucket_id
  artifacts_bucket_id  = dependency.artifacts_bucket.outputs.s3_bucket_id

  secondary_artifacts = [
    {
      artifact_identifier = "TerraformVisual"
      bucket_owner_access = "READ_ONLY"
      type = "S3"
      packaging = "ZIP"
      location = dependency.artifacts_bucket.outputs.s3_bucket_id
      path = "${local.common_vars.namespace}-${local.region_vars.locals.aws_region}-${local.common_vars.name}-${local.account_vars.locals.stage}-${local.common_vars.pipeline_name}"
      namespace_type = "BUILD_ID"
      name = "terraform-visual"
    },
    {
      artifact_identifier = "Plans"
      bucket_owner_access = "READ_ONLY"
      type = "S3"
      packaging = "NONE"
      location = dependency.artifacts_bucket.outputs.s3_bucket_id
      path = "${local.common_vars.namespace}-${local.region_vars.locals.aws_region}-${local.common_vars.name}-${local.account_vars.locals.stage}-${local.common_vars.pipeline_name}"
      namespace_type = "BUILD_ID"
      name = "plan"
    }
  ]
}