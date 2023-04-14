variable "aws_region" {}

variable "artifacts_bucket_id" {
  type        = string
  description = "Artifacts bucket ID"
}

variable "pipeline_prefix" {
  type        = string
  description = "The pipeline name prefix"
}

variable "pipeline_name" {
  type        = string
  description = "The name of the pipeline"
}

variable "repository_name" {
  type        = string
  description = "Repository name"
}

variable "branch_name" {
  type        = string
  description = "The name of the branch to clone"
}

variable "approval_stage" {
  type = object({
    enabled                    = bool
    notification_email_address = string
  })
  default = {
    enabled                    = false
    notification_email_address = ""
  }
  validation {
    condition     = !var.approval_stage.enabled || length(var.approval_stage.notification_email_address) > 0
    error_message = "A valid notification email address must be a given if approval stage is enabled."
  }
  description = "Approval stage configuration."
}

variable "environment_variables_plan" {
  type        = map(string)
  default     = {}
  description = "A map of environment variables to pass into pipeline for plan stage"
}

variable "environment_variables_apply" {
  type        = map(string)
  default     = {}
  description = "A map of environment variables to pass into pipeline for apply stage"
}

variable "codebuild_project_name_plan" {
  type        = string
  description = "CodeBuild project name to handle Terraform plan stage"
}

variable "codebuild_project_name_apply" {
  type        = string
  description = "CodeBuild project name to handle Terraform apply stage"
}

variable "source_artifact_name" {
  type        = string
  description = "The name of the source artifact"
  default     = "SourceArtifact"
}

variable "plan_artifact_name" {
  type        = string
  description = "The name of the plan artifact"
  default     = "PlanArtifact"
}
