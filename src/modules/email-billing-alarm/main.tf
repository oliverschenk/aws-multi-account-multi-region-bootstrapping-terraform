resource "aws_cloudwatch_metric_alarm" "consolidated_billing_alarm" {
  alarm_name          = "account-billing-alarm-${lower(var.currency)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "28800"
  statistic           = "Maximum"
  alarm_description   = "Consolidated billing alarm >= ${var.currency} ${var.monthly_billing_threshold}"
  threshold           = var.monthly_billing_threshold
  alarm_actions       = [aws_sns_topic.consolidated_billing_alarm.arn]

  dimensions = {
    Currency = var.currency
  }

  tags = module.this.tags
}

resource "aws_sns_topic" "consolidated_billing_alarm" {
  name  = "billing-alarm-notification-${lower(var.currency)}"

  tags = module.this.tags
}

resource "aws_sns_topic_subscription" "consolidated_billing_alarm" {
  topic_arn = aws_sns_topic.consolidated_billing_alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email_address
}
