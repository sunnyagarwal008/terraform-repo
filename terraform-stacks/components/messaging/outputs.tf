output "sqs_queue_url" {
  value = aws_sqs_queue.app.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.app.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.app.arn
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}
