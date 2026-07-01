#!/bin/bash
# Script deploy end-to-end cho môi trường dev/test/prod trên Mac/Linux.
# Tham số 1 là environment, tham số 2 là project name.
set -e

# Mặc định deploy lên workspace `dev` nếu không truyền tham số.
ENVIRONMENT=${1:-dev}          # dev | test | prod
# Tiền tố tên tài nguyên Terraform, ví dụ: twin-dev, twin-prod.
PROJECT_NAME=${2:-twin}

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."

# 1. Build Lambda package
# Đi về thư mục gốc của project để mọi lệnh phía sau chạy đúng relative path.
cd "$(dirname "$0")/.."        # project root
echo "📦 Building Lambda package..."
# Build file zip Lambda từ backend/deploy.py trước khi Terraform apply.
(cd backend && uv run deploy.py)

# 2. Terraform workspace & apply
# Chuyển vào thư mục Terraform, khởi tạo provider và module nếu chưa có.
cd terraform
terraform init -input=false

# Mỗi environment dùng một workspace riêng để tách state dev/test/prod.
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Production dùng thêm file biến riêng `prod.tfvars`.
# Dev/test dùng giá trị truyền inline để giữ flow đơn giản.
if [ "$ENVIRONMENT" = "prod" ]; then
  TF_APPLY_CMD=(terraform apply -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
fi

echo "🎯 Applying Terraform..."
"${TF_APPLY_CMD[@]}"

# Lấy output từ Terraform để dùng tiếp cho bước deploy frontend.
API_URL=$(terraform output -raw api_gateway_url)
FRONTEND_BUCKET=$(terraform output -raw s3_frontend_bucket)
# Custom domain có thể chưa được cấu hình, nên cho phép lệnh này fail mềm.
CUSTOM_URL=$(terraform output -raw custom_domain_url 2>/dev/null || true)

# 3. Build + deploy frontend
# Frontend cần biết API URL thật sau khi hạ tầng được tạo xong.
cd ../frontend

# Ghi file env production để `next build` nhúng đúng endpoint backend.
echo "📝 Setting API URL for production..."
echo "NEXT_PUBLIC_API_URL=$API_URL" > .env.production

# Build static site rồi sync toàn bộ output lên S3 frontend bucket.
npm install
npm run build
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete
cd ..

# 4. Final messages
# In ra các URL quan trọng để kiểm tra nhanh sau deploy.
echo -e "\n✅ Deployment complete!"
echo "🌐 CloudFront URL : $(terraform -chdir=terraform output -raw cloudfront_url)"
if [ -n "$CUSTOM_URL" ]; then
  echo "🔗 Custom domain  : $CUSTOM_URL"
fi
echo "📡 API Gateway    : $API_URL"
