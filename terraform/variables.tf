# File này định nghĩa toàn bộ input của module Terraform.
# Ý tưởng là chỉ thay đổi giá trị ở terraform.tfvars, không hardcode trong resource.
variable "project_name" {
  # Prefix chung cho tên resource, ví dụ: twin-dev-api.
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  # Region chính để deploy hầu hết resource của stack.
  # Với tài khoản của bạn hiện tại, nên dùng ap-southeast-1.
  description = "Primary AWS region for the stack"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  # Tách môi trường để dễ dùng workspace hoặc tfvars riêng cho dev/test/prod.
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "bedrock_model_id" {
  # Model Bedrock mà Lambda sẽ gọi ở runtime.
  # Dùng global inference profile sẽ ổn định hơn cho quota và availability.
  description = "Bedrock model ID"
  type        = string
  default     = "global.amazon.nova-2-lite-v1:0"
}

variable "lambda_timeout" {
  # Timeout Lambda cần đủ lớn cho request AI nhưng không quá cao để tránh tốn chi phí.
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 90
}

variable "api_throttle_burst_limit" {
  # Burst limit cho API Gateway: số request tăng đột biến cho phép trong thời gian ngắn.
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 10
}

variable "api_throttle_rate_limit" {
  # Rate limit trung bình theo thời gian của API Gateway.
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 5
}

variable "use_custom_domain" {
  # Bật khi muốn gắn domain thật qua Route53 + ACM + CloudFront aliases.
  description = "Attach a custom domain to CloudFront"
  type        = bool
  default     = false
}

variable "root_domain" {
  # Domain gốc, ví dụ: example.com
  description = "Apex domain name, e.g. mydomain.com"
  type        = string
  default     = ""
}
