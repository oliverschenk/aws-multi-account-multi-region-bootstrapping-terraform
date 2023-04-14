data "aws_caller_identity" "current" {}

data "aws_codecommit_repository" "repository" {
  repository_name = var.repository_name
}

resource "aws_codepipeline" "codepipeline" {

  # The name of the pipeline.
  #
  # The prefix is to avoid duplicate S3 paths
  # in the artifacts bucket as CodePipeline truncates
  # the pipeline name to 20 characters. It should be some
  # form of random string.
  name = "${var.pipeline_prefix}-${module.this.id}-${var.pipeline_name}"

  # the role under which CodePipeline will execute
  role_arn = aws_iam_role.codepipeline_role.arn

  # this is where CodePipeline artifacts will be stored
  artifact_store {
    location = var.artifacts_bucket_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = [var.source_artifact_name]

      configuration = {
        RepositoryName       = var.repository_name
        BranchName           = var.branch_name
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Terraform-Plan"
      namespace        = "TfPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = [var.source_artifact_name]
      output_artifacts = [var.plan_artifact_name]
      version          = "1"

      configuration = {
        ProjectName          = var.codebuild_project_name_plan
        EnvironmentVariables = local.codebuild_env_vars_plan
      }
    }
  }

  dynamic "stage" {
    for_each = var.approval_stage.enabled ? [1] : []
    content {
      name = "Approval"

      action {
        name     = "Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          CustomData         = "Review Terraform Plan for ${local.capitalised_name} Pipeline"
          NotificationArn    = module.sns[0].topic_arn
          ExternalEntityLink = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codebuild/${data.aws_caller_identity.current.account_id}/projects/#{TfPlan.BuildID}/build/#{TfPlan.BuildID}%3A#{TfPlan.BuildTag}/?region=${var.aws_region}"
        }
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name             = "Terraform-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = [var.plan_artifact_name]
      version          = "1"

      configuration = {
        ProjectName          = var.codebuild_project_name_apply
        EnvironmentVariables = local.codebuild_env_vars_apply
      }
    }
  }

  tags = module.this.tags
}

resource "aws_cloudwatch_event_rule" "codepipeline_event_rule" {
  name        = "${module.this.id}-codepipeline-rule"
  description = "Trigger CodePipeline when there is a code change in ${var.branch_name}"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"],
    detail-type = ["CodeCommit Repository State Change"],
    resources   = [data.aws_codecommit_repository.repository.arn],
    detail = {
      event         = ["referenceCreated", "referenceUpdated"],
      referenceType = ["branch"],
      referenceName = [var.branch_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline_target" {
  target_id = "${module.this.id}-codepipeline-target"
  rule      = aws_cloudwatch_event_rule.codepipeline_event_rule.name
  arn       = aws_codepipeline.codepipeline.arn

  role_arn = aws_iam_role.start_pipeline_execution_role.arn
}

resource "aws_iam_role" "start_pipeline_execution_role" {
  name = "${local.capitalised_name}StartPipelineExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "start_pipeline_executioncodepipeline_policy" {
  name = "${local.capitalised_name}StartPipelineExecutionPolicy"
  role = aws_iam_role.start_pipeline_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "codepipeline:StartPipelineExecution"
      ],
      "Resource": [
        "arn:aws:codepipeline:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_codepipeline.codepipeline.name}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.capitalised_name}Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.capitalised_name}Policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.artifacts_bucket_id}",
        "arn:aws:s3:::${var.artifacts_bucket_id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": [
        "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.codebuild_project_name_plan}",
        "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${var.codebuild_project_name_apply}"
      ]
    },
    {
      "Action": [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetRepository",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Resource": "${data.aws_codecommit_repository.repository.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_notification_policy" {

  # this resource is only included if approval stage is enabled
  count = var.approval_stage.enabled ? 1 : 0

  name = "${local.capitalised_name}NotificationPolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "${module.sns[0].topic_arn}"
    }
  ]
}
EOF
}

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "5.1.0"

  # this resource is only included if approval stage is enabled
  count = var.approval_stage.enabled ? 1 : 0

  name = "${module.this.id}-${var.pipeline_name}-approval"

  tags = module.this.tags
}

resource "aws_sns_topic_subscription" "pipeline-approval" {

  # this resource is only included if approval stage is enabled
  count = var.approval_stage.enabled ? 1 : 0

  topic_arn = module.sns[0].topic_arn
  protocol  = "email"
  endpoint  = var.approval_stage.notification_email_address
}

locals {

  capitalised_name = "${title(module.this.namespace)}${replace(title(module.this.name), "/-| /", "")}${title(var.pipeline_name)}"

  env_vars_plan = merge(
    var.environment_variables_plan
  )

  env_vars_apply = merge(
    var.environment_variables_apply
  )

  codebuild_env_vars_plan  = jsonencode([for k, v in local.env_vars_plan : { name : k, value : v, type : "PLAINTEXT" }])
  codebuild_env_vars_apply = jsonencode([for k, v in local.env_vars_apply : { name : k, value : v, type : "PLAINTEXT" }])
}
