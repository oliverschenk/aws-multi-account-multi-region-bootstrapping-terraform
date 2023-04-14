variable "cloudtrail_bucket_id" {}

variable "is_organization_trail" {
  type = bool
  default = false
}

variable "is_multi_region_trail" {
  type = bool
  default = false
}