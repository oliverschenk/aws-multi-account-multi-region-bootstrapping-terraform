resource "random_string" "this" {
  length  = var.length
  special = false
  upper   = false
}
