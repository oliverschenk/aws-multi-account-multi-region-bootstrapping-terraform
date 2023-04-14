###############################################################################
# Create CloudTrail organization trail
###############################################################################
resource "aws_cloudtrail" "organization_trail" {
  name           = "${module.this.id}-organization-trail"
  s3_bucket_name = var.cloudtrail_bucket_id

  include_global_service_events = true
  is_organization_trail         = true
  is_multi_region_trail         = true

  tags = module.this.tags
}
