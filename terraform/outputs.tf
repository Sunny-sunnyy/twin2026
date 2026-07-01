# File này export các giá trị quan trọng sau khi `terraform apply` xong.
# Dùng để copy endpoint nhanh hoặc truyền sang bước deploy frontend.
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "cloudfront_url" {
  # Đây là URL public mặc định của website nếu chưa gắn custom domain.
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "s3_frontend_bucket" {
  # Bucket chứa build static frontend.
  description = "Name of the S3 bucket for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "s3_memory_bucket" {
  # Bucket backend dùng để lưu conversation memory.
  description = "Name of the S3 bucket for memory storage"
  value       = aws_s3_bucket.memory.id
}

output "lambda_function_name" {
  # Tên function để tiện kiểm tra log, deploy zip mới, hoặc debug thủ công.
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api.function_name
}

output "custom_domain_url" {
  # Chỉ có giá trị khi bật use_custom_domain.
  description = "Root URL of the production site"
  value       = var.use_custom_domain ? "https://${var.root_domain}" : ""
}
