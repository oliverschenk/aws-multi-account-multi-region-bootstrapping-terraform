include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//random-string"
}

inputs = {
  length = 6
}
