# Twin

AI Digital Twin project for Week 2 of the AI Engineer Production Track.

This repo is complete through `week2/day3.md`.

Current status:
- Day 1: local twin with file-based memory
- Day 2: AWS deployment with Lambda, API Gateway, S3, and static frontend hosting
- Day 3: Bedrock migration implemented in the repo backend
- Live CDN deployment: still using the Day 2 OpenAI path with `gpt-4.1-nano` because Bedrock access is not available yet

## Architecture Overview

### Day 1

Local development architecture:

1. Next.js frontend sends a message to `POST /chat`.
2. FastAPI backend builds the prompt from the twin persona.
3. The model generates a reply.
4. Conversation history is saved into local JSON files in `memory/`.

### Day 2

AWS deployment architecture:

1. Static frontend is exported from Next.js and hosted on S3.
2. CloudFront or S3 website hosting serves the frontend.
3. The chat UI calls API Gateway.
4. API Gateway invokes AWS Lambda through `backend/lambda_handler.py`.
5. Lambda runs the FastAPI app in `backend/server.py`.
6. Conversation memory is stored in S3 instead of local files.
7. The deployed Day 2 runtime uses OpenAI `gpt-4.1-nano`.

### Day 3

Repo backend architecture:

1. `backend/server.py` initializes `bedrock-runtime` via `boto3`.
2. `backend/context.py` builds a richer system prompt from structured profile data.
3. `backend/resources.py` loads `facts.json`, `summary.txt`, `style.txt`, and `linkedin.pdf`.
4. `call_bedrock()` sends conversation history to Bedrock using `converse()`.
5. Conversation state remains compatible with S3-backed memory.

Important distinction:
- The repo backend reflects the Day 3 Bedrock migration.
- The currently accessible CDN deployment still points to the Day 2 OpenAI-backed API until Bedrock permissions are available.

## Project Structure

```text
twin/
├── backend/
│   ├── context.py
│   ├── data/
│   │   ├── facts.json
│   │   ├── linkedin.pdf
│   │   ├── style.txt
│   │   └── summary.txt
│   ├── deploy.py
│   ├── lambda_handler.py
│   ├── me.txt
│   ├── pyproject.toml
│   ├── requirements.txt
│   ├── resources.py
│   ├── server.py
│   └── uv.lock
├── day3/
│   ├── pic1.png
│   ├── pic2.png
│   ├── pic3.png
│   └── pic4.png
├── frontend/
│   ├── app/
│   ├── components/
│   ├── public/
│   ├── next.config.ts
│   └── package.json
├── week2/
│   ├── day1.md
│   ├── day1_summary.md
│   ├── day2.md
│   ├── day2_summary.md
│   ├── day3.md
│   ├── day3_summary.md
│   ├── day4.md
│   └── day5.md
└── README.md
```

## Tech Stack

- Frontend: Next.js 16, React 19, TypeScript, Tailwind CSS 4
- Backend: FastAPI, `boto3`, `pypdf`, `mangum`, `python-dotenv`
- Python package manager: `uv`
- Local memory: JSON files in `memory/`
- Cloud services: AWS Lambda, API Gateway, S3, optional CloudFront
- AI providers across project progression:
  - Day 1-2 and current live deployment: OpenAI `gpt-4.1-nano`
  - Day 3 repo backend: AWS Bedrock with `BEDROCK_MODEL_ID`

## Key Files

- `backend/server.py`: FastAPI app, memory management, Bedrock call path
- `backend/context.py`: system prompt builder using profile context
- `backend/resources.py`: loads profile resources from `backend/data/`
- `backend/lambda_handler.py`: Lambda entrypoint via Mangum
- `backend/deploy.py`: builds `lambda-deployment.zip` for Lambda
- `frontend/components/twin.tsx`: chat UI and API fetch logic
- `frontend/app/page.tsx`: landing page shell
- `week2/day1.md`, `week2/day2.md`, `week2/day3.md`: lesson instructions
- `week2/day1_summary.md`, `week2/day2_summary.md`, `week2/day3_summary.md`: lesson summaries

## Local Development

### Backend

From `backend/`:

```bash
uv sync
uv run server.py
```

For local Bedrock-backed execution, set environment variables such as:

```env
DEFAULT_AWS_REGION=us-east-1
BEDROCK_MODEL_ID=global.amazon.nova-2-lite-v1:0
CORS_ORIGINS=http://localhost:3000
USE_S3=false
MEMORY_DIR=../memory
```

### Frontend

From `frontend/`:

```bash
npm install
npm run dev
```

Default local URLs:
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000`

## Deployment Workflow

### Backend package

From `backend/`:

```bash
uv sync
uv run deploy.py
```

This creates `backend/lambda-deployment.zip` using the AWS Lambda Python container image.

### Frontend static export

From `frontend/`:

```bash
npm install
npm run build
```

The Next.js app uses `output: "export"` in `frontend/next.config.ts`, so the build output can be uploaded to S3 static hosting.

## Deployed Endpoints

Current API and frontend endpoints referenced in the project:

- API root: `https://r7ewqxjlke.execute-api.ap-southeast-1.amazonaws.com/`
- API health: `https://r7ewqxjlke.execute-api.ap-southeast-1.amazonaws.com/health`
- Frontend website: `http://twin-frontend-487592470523.s3-website-ap-southeast-1.amazonaws.com/`

Note:
- These live endpoints currently correspond to the Day 2 deployment path, not the Day 3 Bedrock backend.

## API Surface

### `GET /`

Returns service metadata.

### `GET /health`

Returns backend health information and active model configuration.

### `POST /chat`

Request body:

```json
{
  "message": "Hello",
  "session_id": "optional-session-id"
}
```

Response body:

```json
{
  "response": "Assistant reply",
  "session_id": "session-id"
}
```

### `GET /conversation/{session_id}`

Returns stored conversation history for a session.

## Known Constraints

- Bedrock migration is implemented in code, but the public deployment still falls back to OpenAI because Bedrock access is not currently available.
- `frontend/components/twin.tsx` uses a hard-coded API Gateway URL.
- `CORS_ORIGINS=*` may be acceptable for a lab deployment but should be narrowed for production.
- S3 JSON conversation storage is fine for the course project, but it is not a robust multi-user production memory design.
- There is no automated test suite yet for backend or frontend behavior.

## Course Progress

- `week2/day1.md`: local twin with memory
- `week2/day2.md`: AWS deployment with S3 and Lambda
- `week2/day3.md`: Bedrock migration in the backend code
- `week2/day4.md` and `week2/day5.md`: not implemented yet in this repo
