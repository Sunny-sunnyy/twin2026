# File này chứa giá trị thực tế cho biến ở môi trường hiện tại.
# Hiện đang là cấu hình dev mặc định.

# Prefix tên project để Terraform ghép thành tên resource.
project_name = "twin"

# Region chính của stack.
aws_region = "ap-southeast-1"

# Môi trường đang triển khai.
environment = "dev"

# Model Bedrock mặc định cho Lambda.
bedrock_model_id = "global.amazon.nova-2-lite-v1:0"

# Timeout backend AI.
lambda_timeout = 60

# Throttle cơ bản để tránh spam API.
api_throttle_burst_limit = 10
api_throttle_rate_limit  = 5

# Chưa dùng domain riêng ở môi trường dev.
use_custom_domain = false
root_domain       = ""
