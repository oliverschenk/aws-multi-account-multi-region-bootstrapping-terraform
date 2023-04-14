include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules//email-billing-alarm"
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

inputs = {
  monthly_billing_threshold  = local.common_vars.billing_monthly_threshold
  currency                   = local.common_vars.billing_currency
  notification_email_address = local.common_vars.billing_alarm_notification_email
}
