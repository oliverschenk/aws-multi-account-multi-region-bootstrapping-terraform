data "aws_caller_identity" "current" {}

resource "aws_codebuild_project" "codebuild" {
  name          = "${module.this.id}-${var.codebuild_project_name}"
  description   = "Build project for ${title(module.this.namespace)} ${title(module.this.name)} ${replace(title(var.codebuild_project_name), "/-| /", "")}"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  dynamic secondary_artifacts {
    for_each = var.secondary_artifacts
    content {
      artifact_identifier = secondary_artifacts.value["artifact_identifier"]
      bucket_owner_access = secondary_artifacts.value["bucket_owner_access"]
      type = secondary_artifacts.value["type"]
      packaging = secondary_artifacts.value["packaging"]
      location = secondary_artifacts.value["location"]
      path = secondary_artifacts.value["path"]
      namespace_type = secondary_artifacts.value["namespace_type"]
      name = secondary_artifacts.value["name"]
    }
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/${module.this.namespace}/${module.this.name}/${var.codebuild_project_name}"
    }

    s3_logs {
      status   = "ENABLED"
      bucket_owner_access = "READ_ONLY"
      location = "${var.logging_bucket_id}/${module.this.namespace}/${module.this.name}/${var.codebuild_project_name}"
    }
  }

  tags = module.this.tags
}

resource "aws_iam_role" "codebuild" {
  name = "${local.capitalised_name}CodebuildRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role = aws_iam_role.codebuild.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudWatchLogging",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${module.this.namespace}/${module.this.name}/${var.codebuild_project_name}",
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${module.this.namespace}/${module.this.name}/${var.codebuild_project_name}:*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Sid": "AllowStoreS3Artifacts",
      "Effect": "Allow",
      "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${var.artifacts_bucket_id}",
        "arn:aws:s3:::${var.artifacts_bucket_id}/*"
      ]
    },
    {
      "Sid": "AllowStoreS3Logs",
      "Effect": "Allow",
      "Action": [
          "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.logging_bucket_id}",
        "arn:aws:s3:::${var.logging_bucket_id}/*"
      ]
    }
  ]
}
POLICY
}

###############################################################################
# Attach the policy that allows assuming the roles for the target accounts
###############################################################################

resource "aws_iam_role_policy_attachment" "assume_role_policy_attachment" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

resource "aws_iam_policy" "assume_role_policy" {
  name        = "${local.capitalised_name}CodebuildAssumeRolePolicy"
  path        = "/"
  description = "Assume role policy for Terraform deployment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : var.assume_role_arns
      }
    ]
  })

  tags = module.this.tags
}

locals {
  assume_role_arns_string = join(", ", var.assume_role_arns)
  capitalised_name        = "${title(module.this.namespace)}${replace(title(module.this.name), "/-| /", "")}${replace(title(var.codebuild_project_name), "/-| /", "")}"
}
