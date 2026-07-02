# Twin

An AI Digital Twin project from Week 2 of the AI Engineer Production Track.

This repo contains:
- a Next.js chat frontend
- a FastAPI backend
- personalized context loaded from local profile files
- conversation memory stored locally or in S3
- AWS Bedrock inference
- Terraform infrastructure for AWS deployment

## Status

The project is implemented through the Week 2 build sequence:
- Day 1: local chat app with file-based memory
- Day 2: AWS deployment architecture with Lambda, API Gateway, S3, and CloudFront
- Day 3: backend migrated from OpenAI to AWS Bedrock
- Day 4: infrastructure moved to Terraform with deploy and destroy scripts
- Day 5: repo and remote-state deployment flow prepared; GitHub Actions workflow files are not in this repo yet

## Architecture

### Local

1. The frontend sends `POST /chat` to the FastAPI backend.
2. `backend/resources.py` loads structured profile data from `backend/data/`.
3. `backend/context.py` builds the system prompt.
4. `backend/server.py` sends the conversation to AWS Bedrock.
5. Memory is stored in `memory/` when `USE_S3=false`.

### AWS

1. The frontend is statically exported by Next.js.
2. Static assets are uploaded to an S3 frontend bucket.
3. CloudFront serves the public site.
4. API Gateway HTTP API invokes AWS Lambda.
5. Lambda runs the FastAPI app through Mangum.
6. Conversation memory is stored in an S3 memory bucket.
7. Terraform provisions and updates the infrastructure.

## Repository Layout

```text
twin/
├── backend/
│   ├── context.py
│   ├── data/
│   ├── deploy.py
│   ├── lambda_handler.py
│   ├── pyproject.toml
│   ├── requirements.txt
│   ├── resources.py
│   ├── server.py
│   └── uv.lock
├── frontend/
│   ├── app/
│   ├── components/
│   ├── public/
│   ├── next.config.ts
│   └── package.json
├── scripts/
│   ├── deploy.sh
│   └── destroy.sh
├── terraform/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── week2/
│   ├── day1.md
│   ├── day2.md
│   ├── day2_summary.md
│   ├── day3.md
│   ├── day3_summary.md
│   ├── day4.md
│   ├── day4_summary.md
│   ├── day5.md
│   └── day5_summary.md
└── README.md
```

## Tech Stack

- Frontend: Next.js 16, React 19, TypeScript, Tailwind CSS 4
- Backend: FastAPI, boto3, Mangum, pypdf, python-dotenv
- Python package manager: `uv`
- Infrastructure: Terraform
- AWS services: Bedrock, Lambda, API Gateway v2, S3, CloudFront, IAM
- Lambda packaging: Docker-based zip build in `backend/deploy.py`

## Important Files

- `backend/server.py`: API routes, memory load/save, Bedrock call
- `backend/context.py`: system prompt builder
- `backend/resources.py`: loads `facts.json`, `summary.txt`, `style.txt`, `linkedin.pdf`
- `backend/lambda_handler.py`: Lambda entrypoint
- `backend/deploy.py`: builds `lambda-deployment.zip`
- `frontend/components/twin.tsx`: chat UI and API request flow
- `frontend/next.config.ts`: static export configuration
- `terraform/main.tf`: AWS resources
- `terraform/outputs.tf`: deploy outputs consumed by scripts
- `scripts/deploy.sh`: full deploy flow
- `scripts/destroy.sh`: teardown flow

## Prerequisites

Install:
- `uv`
- Python 3.13 for local backend development
- Node.js and npm
- Docker
- Terraform
- AWS CLI

You also need:
- valid AWS credentials for `aws`, Terraform, and `boto3`
- Bedrock access and quota for the configured model
- personal context files in `backend/data/`

Required backend data files:
- `backend/data/facts.json`
- `backend/data/summary.txt`
- `backend/data/style.txt`
- `backend/data/linkedin.pdf`

## Environment Variables

Example project-level variables are in `.env.example`:

```env
AWS_ACCOUNT_ID=your_12_digit_account_id
DEFAULT_AWS_REGION=us-east-1
PROJECT_NAME=twin
```

Typical local backend variables:

```env
DEFAULT_AWS_REGION=ap-southeast-1
BEDROCK_MODEL_ID=global.amazon.nova-2-lite-v1:0
CORS_ORIGINS=http://localhost:3000
USE_S3=false
MEMORY_DIR=../memory
```

The frontend reads:
- `NEXT_PUBLIC_API_URL` when provided
- otherwise `http://localhost:8000`

## Local Development

### 1. Start the backend

```bash
cd backend
uv sync
uv run server.py
```

Backend URL:

```text
http://localhost:8000
```

### 2. Start the frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend URL:

```text
http://localhost:3000
```

With this setup:
- chat requests go from frontend to local FastAPI
- Bedrock is still used for inference
- conversation memory is stored in `memory/` when `USE_S3=false`

## API Endpoints

- `GET /`: basic service metadata
- `GET /health`: health and runtime config
- `POST /chat`: send a user message and get a reply
- `GET /conversation/{session_id}`: fetch saved conversation history

Example chat payload:

```json
{
  "message": "Tell me about your AI engineering background",
  "session_id": "optional-session-id"
}
```

## Lambda Packaging

Build the Lambda artifact with Docker:

```bash
cd backend
uv run deploy.py
```

This creates:

```text
backend/lambda-deployment.zip
```

Notes:
- local backend development uses Python 3.13 via `pyproject.toml`
- the Lambda package is built against the AWS Lambda Python 3.12 runtime image

## Terraform Infrastructure

Terraform provisions:
- S3 memory bucket
- S3 frontend bucket with website hosting
- IAM role and policy attachments for Lambda
- Lambda function for the FastAPI backend
- API Gateway HTTP API
- CloudFront distribution
- optional custom-domain resources when enabled

Key implementation details:
- environments are separated by Terraform workspaces: `dev`, `test`, `prod`
- resource names are built from `project_name` and `environment`
- S3 bucket names include the AWS account ID for global uniqueness
- Lambda CORS configuration depends on the CloudFront domain name
- `terraform/backend.tf` is set up for an S3 backend configured by the deploy scripts

## Deploy

The main deploy path is:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev
```

Custom project prefix:

```bash
./scripts/deploy.sh dev my-twin
```

What the script does:
1. Builds `backend/lambda-deployment.zip`
2. Runs `terraform init` against the S3 remote backend
3. Selects or creates the workspace
4. Applies Terraform
5. Writes `frontend/.env.production`
6. Builds the statically exported frontend
7. Syncs the frontend build to S3
8. Prints the CloudFront and API URLs

Before first remote-state deploy, the following AWS resources must already exist:
- `twin-terraform-state-<aws-account-id>` S3 bucket
- `twin-terraform-locks` DynamoDB table

Those bootstrap resources are referenced by the scripts, but the bootstrap Terraform files are not included in this repo.

## Destroy

Destroy one environment:

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh dev
```

The destroy script:
1. Reconnects Terraform to the correct remote state
2. Selects the target workspace
3. Empties the frontend and memory buckets
4. Runs `terraform destroy`
5. Leaves workspace deletion as a manual follow-up step

To remove the workspace after destroy:

```bash
cd terraform
terraform workspace select default
terraform workspace delete dev
```

## Learning Notes

The `week2/` folder contains the course notes used to build this project:
- `day1.md` to `day5.md`: daily implementation notes
- `day2_summary.md` to `day5_summary.md`: structured study summaries

Use them as project history, not as the source of truth over the actual code.

## Known Gaps

- No `.github/workflows/` files are currently present, so CI/CD is not yet fully implemented in-repo
- Remote Terraform state bootstrap resources are assumed to exist already
- The backend depends on local profile files in `backend/data/`; without them, the app will not start correctly
