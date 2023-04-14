include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//terraform-codepipeline"
}

dependency "random_prefix" {
  config_path = "../random-pipeline-prefix"
  mock_outputs = {
    result = "abc123"
  }
}

dependency "artifacts_bucket" {
  config_path = "../artifacts-bucket"
  mock_outputs = {
    s3_bucket_id = "mock-artifacts-bucket-name"
  }
}

dependency "codebuild_plan" {
  config_path = "../codebuild-plan"
  mock_outputs = {
    codebuild_project_name = "mock-codebuild-project-name"
  }
}

dependency "codebuild_apply" {
  config_path = "../codebuild-apply"
  mock_outputs = {
    codebuild_project_name = "mock-codebuild-project-name"
  }
}

dependency "codecommit" {
  config_path = "../codecommit"
  mock_outputs = {
    repository_name = "mock-repository-name"
  }
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))

  environment_common = {
    NAME      = local.common_vars.name
    NAMESPACE = local.common_vars.namespace
  }

  env_vars = merge(
    local.common_vars.default_environment,
    local.environment_common
  )
}

inputs = {
  pipeline_prefix = dependency.random_prefix.outputs.result
  pipeline_name   = local.common_vars.pipeline_name

  codebuild_project_name_plan = dependency.codebuild_plan.outputs.codebuild_project_name
  codebuild_project_name_apply = dependency.codebuild_apply.outputs.codebuild_project_name

  repository_name  = dependency.codecommit.outputs.repository_name
  branch_name = "master"

  environment_variables_plan  = local.env_vars
  environment_variables_apply = local.env_vars
  
  source_artifact_name = local.common_vars.source_artifact_name
  plan_artifact_name = local.common_vars.plan_artifact_name

  approval_stage = {
    enabled                    = true
    notification_email_address = local.common_vars.build_notification_email
  }

  artifacts_bucket_id = dependency.artifacts_bucket.outputs.s3_bucket_id
}
