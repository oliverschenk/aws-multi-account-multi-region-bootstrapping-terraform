output "sns_topic_arn" {
  description = "SNS Topic ARN to be subscribed to in order to delivery the clodwatch billing alarms"
  value       = aws_sns_topic.consolidated_billing_alarm.arn
}

output "sns_topic_subscription_arn" {
  description = "SNS topic subscription ARN where CloudWatch billing alarms are delivered to"
  value       = aws_sns_topic_subscription.consolidated_billing_alarm.arn
}
