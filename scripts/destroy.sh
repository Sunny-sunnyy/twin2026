#!/bin/bash
# Script hủy toàn bộ hạ tầng của một environment đã được tạo bằng Terraform.
# Tham số 1 là environment bắt buộc, tham số 2 là project name tùy chọn.
set -e

# Bắt buộc phải chỉ rõ environment để tránh xóa nhầm workspace mặc định.
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "Available environments: dev, test, prod"
    exit 1
fi

# Environment cần xóa, ví dụ: dev, test, prod.
ENVIRONMENT=$1
# Tiền tố tên tài nguyên; mặc định là `twin` nếu không truyền.
PROJECT_NAME=${2:-twin}

echo "🗑️ Preparing to destroy ${PROJECT_NAME}-${ENVIRONMENT} infrastructure..."

# Chuyển thẳng vào thư mục Terraform để mọi lệnh destroy chạy đúng state/workspace.
cd "$(dirname "$0")/../terraform"

# Kiểm tra workspace có tồn tại không; nếu không có thì dừng để tránh thao tác sai.
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Error: Workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list
    exit 1
fi

# Chọn đúng workspace trước khi xóa để Terraform dùng đúng state của environment đó.
terraform workspace select "$ENVIRONMENT"

echo "📦 Emptying S3 buckets..."

# Lấy AWS Account ID vì tên bucket đang được ghép kèm account id để đảm bảo unique.
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Tự dựng lại tên 2 bucket theo convention đang dùng trong Terraform.
FRONTEND_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-frontend-${AWS_ACCOUNT_ID}"
MEMORY_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-memory-${AWS_ACCOUNT_ID}"

# Bucket S3 cần được xóa hết object trước khi Terraform/AWS có thể xóa bucket.
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
    echo "  Emptying $FRONTEND_BUCKET..."
    aws s3 rm "s3://$FRONTEND_BUCKET" --recursive
else
    echo "  Frontend bucket not found or already empty"
fi

# Tương tự với memory bucket: dọn sạch dữ liệu hội thoại trước khi destroy.
if aws s3 ls "s3://$MEMORY_BUCKET" 2>/dev/null; then
    echo "  Emptying $MEMORY_BUCKET..."
    aws s3 rm "s3://$MEMORY_BUCKET" --recursive
else
    echo "  Memory bucket not found or already empty"
fi

echo "🔥 Running terraform destroy..."

# Production có thể cần thêm biến từ `prod.tfvars`; dev/test dùng biến inline.
# `-auto-approve` giúp script chạy không cần xác nhận thủ công từng lần.
if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
    terraform destroy -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
else
    terraform destroy -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
fi

echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
# Workspace vẫn còn tồn tại sau khi destroy; chỉ là không còn resource bên trong state đó.
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"
