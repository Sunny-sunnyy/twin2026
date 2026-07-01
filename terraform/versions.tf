# File này khóa version Terraform và AWS provider để tránh lệch hành vi giữa các máy.
terraform {
  # Cho phép mọi bản Terraform từ 1.0 trở lên.
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # Provider mặc định.
  # Sẽ dùng credentials/profile/region từ AWS CLI hoặc biến môi trường hiện có.
  # Khai báo rõ từ biến để cấu hình nhất quán giữa local, CI và các máy khác.
  region = var.aws_region
}

provider "aws" {
  # CloudFront chỉ dùng được certificate ACM ở us-east-1,
  # nên tạo thêm provider alias riêng cho các resource custom domain.
  alias  = "us_east_1"
  region = "us-east-1"
}
