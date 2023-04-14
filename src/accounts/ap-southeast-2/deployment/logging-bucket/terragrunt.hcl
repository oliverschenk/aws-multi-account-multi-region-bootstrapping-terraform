include "root" {
  path = find_in_parent_folders()
}

include "private_bucket" {
  path = "../_env/private-bucket.hcl"
  expose = true
}

inputs = {
  bucket = "${include.private_bucket.locals.id}-pipeline-logging"
}
