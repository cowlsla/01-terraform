output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table Name"
}
