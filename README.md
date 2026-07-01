# Twin

AI Digital Twin project built during Week 2 of the AI Engineer Production Track.

The repo is now implemented through `week2/day4.md`:
- Day 1: local chat app with file-based memory
- Day 2: AWS deployment shape with Lambda, API Gateway, S3, CloudFront
- Day 3: backend migrated from OpenAI to AWS Bedrock
- Day 4: infrastructure moved into Terraform with deploy/destroy scripts

## What This Project Does

This project lets a visitor chat with a "digital twin" backed by:
- a Next.js frontend chat UI
- a FastAPI backend
- profile context loaded from local files in `backend/data/`
- conversation memory stored either in local JSON files or S3
- AWS Bedrock for model inference in the current backend code

## Current Architecture

### Local Development

1. The frontend sends `POST /chat` requests to the backend.
2. `backend/context.py` builds the system prompt from profile data.
3. `backend/server.py` sends the conversation to AWS Bedrock.
4. Conversation history is stored in `memory/` when `USE_S3=false`.

### Cloud Deployment

1. The frontend is statically exported with Next.js.
2. Static files are uploaded to an S3 frontend bucket.
3. CloudFront serves the public website.
4. API Gateway routes requests to AWS Lambda.
5. Lambda runs the FastAPI app through Mangum.
6. Conversation memory is stored in an S3 memory bucket.
7. Infrastructure is provisioned with Terraform.

## Project Structure

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
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── week2/
│   ├── day1.md
│   ├── day1_summary.md
│   ├── day2.md
│   ├── day2_summary.md
│   ├── day3.md
│   ├── day3_summary.md
│   ├── day4.md
│   ├── day4_summary.md
│   └── day5.md
└── README.md
```

## Tech Stack

- Frontend: Next.js 16, React 19, TypeScript, Tailwind CSS 4
- Backend: FastAPI, boto3, Mangum, pypdf, python-dotenv
- Python package manager: `uv`
- Infrastructure: Terraform + AWS provider
- Cloud services: Lambda, API Gateway v2, S3, CloudFront, IAM, Bedrock
- Packaging: Docker-based Lambda zip build in `backend/deploy.py`

## Key Files

- `backend/server.py`: FastAPI app, Bedrock calls, memory load/save
- `backend/context.py`: system prompt assembly
- `backend/resources.py`: loads `facts.json`, `summary.txt`, `style.txt`, `linkedin.pdf`
- `backend/lambda_handler.py`: Lambda entrypoint via Mangum
- `backend/deploy.py`: creates `lambda-deployment.zip`
- `frontend/components/twin.tsx`: chat UI and API request flow
- `terraform/main.tf`: AWS infrastructure definition
- `terraform/outputs.tf`: values consumed after apply
- `scripts/deploy.sh`: end-to-end deploy flow
- `scripts/destroy.sh`: end-to-end destroy flow

## Prerequisites

Install these tools before working with the repo:
- `uv`
- Node.js + npm
- Docker
- Terraform
- AWS CLI

You also need:
- valid AWS credentials available to Terraform and `boto3`
- Bedrock model access or quota for the selected `BEDROCK_MODEL_ID`

## Backend Setup

From `backend/`:

```bash
uv sync
```

Optional local environment variables:

```env
DEFAULT_AWS_REGION=ap-southeast-1
BEDROCK_MODEL_ID=global.amazon.nova-2-lite-v1:0
CORS_ORIGINS=http://localhost:3000
USE_S3=false
MEMORY_DIR=../memory
```

Run the backend:

```bash
cd backend
uv run server.py
```

Backend default URL:

```text
http://localhost:8000
```

## Frontend Setup

From `frontend/`:

```bash
npm install
npm run dev
```

Frontend default URL:

```text
http://localhost:3000
```

The frontend reads:
- `NEXT_PUBLIC_API_URL` if provided
- otherwise falls back to `http://localhost:8000`

## Local Development Flow

Start backend first:

```bash
cd backend
uv run server.py
```

Then start frontend:

```bash
cd frontend
npm install
npm run dev
```

With this setup:
- frontend runs on `http://localhost:3000`
- backend runs on `http://localhost:8000`
- memory is stored locally in `memory/` if `USE_S3=false`

## Lambda Packaging

The backend deploy artifact is built with Docker so dependencies match the Lambda runtime:

```bash
cd backend
uv run deploy.py
```

This creates:

```text
backend/lambda-deployment.zip
```

## Terraform Infrastructure

The Terraform code provisions:
- S3 memory bucket
- S3 frontend bucket with website hosting
- IAM role and policy attachments for Lambda
- Lambda function for the FastAPI backend
- API Gateway HTTP API
- CloudFront distribution
- optional custom-domain support inputs

Important implementation details:
- workspace-based environment separation: `dev`, `test`, `prod`
- resource names use `project_name` + `environment`
- bucket names include AWS account ID for uniqueness
- Lambda waits on CloudFront because its CORS env var depends on the CloudFront domain

## Deploy

The simplest deploy path is the shell script:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev
```

Custom project name:

```bash
./scripts/deploy.sh dev my-twin
```

What the script does:
1. Builds `backend/lambda-deployment.zip`
2. Runs `terraform init`
3. Selects or creates the Terraform workspace
4. Runs `terraform apply`
5. Writes `frontend/.env.production`
6. Builds the frontend
7. Syncs static files to the frontend S3 bucket

For `prod`, the script uses `prod.tfvars` if present:

```bash
./scripts/deploy.sh prod
```

## Destroy

Destroy a specific environment:

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh dev
```

What the script does:
1. Selects the requested Terraform workspace
2. Empties the frontend and memory S3 buckets
3. Runs `terraform destroy`

After destroy, the workspace still exists. If you want to remove it too:

```bash
cd terraform
terraform workspace select default
terraform workspace delete dev
```

## Terraform Commands

Useful direct commands:

```bash
cd terraform
terraform init
terraform validate
terraform workspace list
terraform workspace select dev
terraform plan -var="project_name=twin" -var="environment=dev"
terraform apply -var="project_name=twin" -var="environment=dev"
terraform output
```

## API Surface

### `GET /`

Returns service metadata:
- current storage mode
- active Bedrock model id

### `GET /health`

Returns health information:
- backend status
- `USE_S3` mode
- configured Bedrock model

### `POST /chat`

Request:

```json
{
  "message": "Hello",
  "session_id": "optional-session-id"
}
```

Response:

```json
{
  "response": "Assistant reply",
  "session_id": "session-id"
}
```

### `GET /conversation/{session_id}`

Returns stored conversation history for a given session.

## Personalization Data

The twin persona is built from:
- `backend/data/facts.json`
- `backend/data/summary.txt`
- `backend/data/style.txt`
- `backend/data/linkedin.pdf`

If `linkedin.pdf` is missing, `resources.py` falls back gracefully.

## Environment Variables

Most important backend variables:

```env
DEFAULT_AWS_REGION=ap-southeast-1
AWS_REGION=ap-southeast-1
BEDROCK_MODEL_ID=global.amazon.nova-2-lite-v1:0
CORS_ORIGINS=http://localhost:3000
USE_S3=false
S3_BUCKET=
MEMORY_DIR=../memory
```

Frontend production variable:

```env
NEXT_PUBLIC_API_URL=https://your-api-id.execute-api.region.amazonaws.com
```

## Known Constraints

- Public deployment details should be treated as environment-specific, not hardcoded documentation.
- `backend/server.py` uses Bedrock, but `backend/pyproject.toml` still includes `openai` as a dependency. That is now stale.
- `backend/pyproject.toml` declares `requires-python = ">=3.13"` while the Lambda package is built for Python 3.12. That mismatch should be cleaned up.
- `scripts/destroy.sh` checks bucket existence with `aws s3 ls`, which prints bucket contents before deletion.
- The Terraform flow depends on valid AWS credentials and working Bedrock access/quota.
- There is no automated test suite yet for backend, frontend, or Terraform validation in CI.
- Conversation memory in S3 is acceptable for the course project, but not a strong multi-user production memory design.

## Course Progress Mapping

- `week2/day1.md`: local twin and JSON memory
- `week2/day2.md`: AWS deployment pattern
- `week2/day3.md`: Bedrock migration
- `week2/day4.md`: Terraform and deployment automation
- `week2/day5.md`: not implemented in this repo yet

## Next Logical Improvements

- remove stale `openai` dependency from backend metadata
- align Python version metadata with the Lambda runtime
- add `.env.example` files for backend and frontend
- add CI checks for `terraform validate`, backend import sanity, and frontend lint
- move Terraform state to a remote backend for team-safe usage
