variable "monthly_billing_threshold" {
  description = "The threshold for which estimated monthly charges will trigger the metric alarm."
  type        = string
}

variable "currency" {
  description = "Short notation for currency type (e.g. USD, CAD, AUD)"
  type        = string
  default     = "AUD"
}

variable "notification_email_address" {
  description = "Email address where notifications should be sent"
  type        = string
}
