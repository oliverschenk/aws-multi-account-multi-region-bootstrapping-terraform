module "s3_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.1.0"
  enabled = module.this.enabled

  acl                                    = var.acl
  source_policy_documents                = data.aws_iam_policy_document.default.*.json
  force_destroy                          = var.force_destroy
  versioning_enabled                     = var.versioning_enabled
  lifecycle_configuration_rules          = var.lifecycle_configuration_rules
  sse_algorithm                          = var.sse_algorithm
  kms_master_key_arn                     = var.kms_master_key_arn
  block_public_acls                      = var.block_public_acls
  block_public_policy                    = var.block_public_policy
  ignore_public_acls                     = var.ignore_public_acls
  restrict_public_buckets                = var.restrict_public_buckets
  access_log_bucket_name                 = local.access_log_bucket_name
  allow_ssl_requests_only                = var.allow_ssl_requests_only
  bucket_notifications_enabled           = var.bucket_notifications_enabled
  bucket_notifications_type              = var.bucket_notifications_type
  bucket_notifications_prefix            = var.bucket_notifications_prefix

  context = module.this.context
}

module "s3_access_log_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.1.0"
  enabled = module.this.enabled && var.create_access_log_bucket

  acl                                    = var.acl
  force_destroy                          = var.force_destroy
  versioning_enabled                     = var.versioning_enabled
  lifecycle_configuration_rules          = var.lifecycle_configuration_rules
  sse_algorithm                          = var.sse_algorithm
  kms_master_key_arn                     = var.kms_master_key_arn
  block_public_acls                      = var.block_public_acls
  block_public_policy                    = var.block_public_policy
  ignore_public_acls                     = var.ignore_public_acls
  restrict_public_buckets                = var.restrict_public_buckets
  access_log_bucket_name                 = ""
  allow_ssl_requests_only                = var.allow_ssl_requests_only

  attributes = ["access-logs"]
  context    = module.this.context
}

data "aws_iam_policy_document" "default" {
  count       = module.this.enabled ? 1 : 0

  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${local.arn_format}:s3:::${module.this.id}",
    ]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${local.arn_format}:s3:::${module.this.id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

data "aws_partition" "current" {}

locals {
  access_log_bucket_name = var.create_access_log_bucket == true ? module.s3_access_log_bucket.bucket_id : var.access_log_bucket_name
  arn_format             = "arn:${data.aws_partition.current.partition}"
}