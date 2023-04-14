variable "aws_region" {}

variable "codebuild_project_name" {}

variable "logging_bucket_id" {
  type        = string
  description = "Logging bucket ID"
}

variable "artifacts_bucket_id" {
  type        = string
  description = "Artifacts bucket ID"
}

variable "assume_role_arns" {
  type        = list(string)
  description = "List of role ARNs to allow CodeBuild to assume"
}

variable "buildspec" {
  type        = string
  default     = "buildspec.yml"
  description = "Build YML specification file"
}

variable "build_timeout" {
  type        = number
  default     = 10
  description = "The CodeBuild timeout in minutes"
}

variable "secondary_artifacts" {
  type = list(object({
    artifact_identifier = string
    location            = string
    bucket_owner_access = optional(string, "NONE")
    type                = optional(string, "S3")
    packaging           = optional(string, "ZIP")
    encryption_disabled = optional(bool, false)
    path                = optional(string, "")
    namespace_type      = optional(string, "NONE")
    name                = optional(string, "/")
  }))
  description = "A list of secondary artifacts"
  default = []
}
