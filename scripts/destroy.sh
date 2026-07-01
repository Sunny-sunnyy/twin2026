#!/bin/bash
# Script xóa hạ tầng của một environment cụ thể.
# Tham số 1 là environment bắt buộc: dev | test | prod
# Tham số 2 là project name, mặc định là `twin`.
set -e

# Kiểm tra đầu vào để tránh xóa nhầm khi quên truyền environment.
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "Available environments: dev, test, prod"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_NAME=${2:-twin}

echo "🗑️ Preparing to destroy ${PROJECT_NAME}-${ENVIRONMENT} infrastructure..."

# Đi vào thư mục terraform để mọi lệnh init/workspace/destroy chạy đúng chỗ.
cd "$(dirname "$0")/../terraform"

# Lấy account id và region để trỏ đúng remote state trên S3.
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}

# Kết nối Terraform với backend S3 đang chứa state của environment cần xóa.
# Nếu không init đúng backend, Terraform có thể không nhìn thấy state thật để destroy.
echo "🔧 Initializing Terraform with S3 backend..."
terraform init -input=false \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=twin-terraform-locks" \
  -backend-config="encrypt=true"

# Mỗi environment có một workspace riêng. Nếu workspace không tồn tại thì không nên destroy.
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Error: Workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list
    exit 1
fi

# Chọn đúng workspace trước khi destroy để không đụng nhầm state môi trường khác.
terraform workspace select "$ENVIRONMENT"

echo "📦 Emptying S3 buckets..."

# Tự dựng lại tên bucket theo convention của Day 4/Day 5.
# Việc empty bucket trước là cần thiết vì S3 bucket có object bên trong thì Terraform/AWS không xóa được.
FRONTEND_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-frontend-${AWS_ACCOUNT_ID}"
MEMORY_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-memory-${AWS_ACCOUNT_ID}"

# Nếu bucket frontend còn tồn tại, xóa sạch toàn bộ static files trước.
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
    echo "  Emptying $FRONTEND_BUCKET..."
    aws s3 rm "s3://$FRONTEND_BUCKET" --recursive
else
    echo "  Frontend bucket not found or already empty"
fi

# Nếu bucket memory còn tồn tại, xóa sạch conversation history trước.
if aws s3 ls "s3://$MEMORY_BUCKET" 2>/dev/null; then
    echo "  Emptying $MEMORY_BUCKET..."
    aws s3 rm "s3://$MEMORY_BUCKET" --recursive
else
    echo "  Memory bucket not found or already empty"
fi

echo "🔥 Running terraform destroy..."

# Một số flow destroy trên GitHub Actions vẫn cần file zip Lambda tồn tại để Terraform đọc metadata.
# Nếu file thật không còn, tạo file giả tối thiểu để quá trình destroy không vỡ ở bước đọc package.
if [ ! -f "../backend/lambda-deployment.zip" ]; then
    echo "Creating dummy lambda package for destroy operation..."
    echo "dummy" | zip ../backend/lambda-deployment.zip -
fi

# Prod có thể dùng thêm file biến riêng; dev/test dùng biến inline.
if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
    terraform destroy -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
else
    terraform destroy -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
fi

echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
# Workspace không tự bị xóa sau destroy; state chỉ trở thành rỗng.
# Nếu muốn dọn sạch hoàn toàn phần local/remote workspace, chạy thêm các lệnh bên dưới.
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"
