include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "github.com/cloudposse/terraform-aws-cloudtrail//.?ref=0.22.0"
}

dependency "cloudtrail_bucket" {
  config_path = "../../logging/cloudtrail-bucket"
  mock_outputs = {
    bucket_id = "mock-bucket-id"
  }
}

inputs = {
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_logging                = true
  s3_bucket_name                = dependency.cloudtrail_bucket.outputs.bucket_id
}
