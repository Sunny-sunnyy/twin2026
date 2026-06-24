# Twin

AI Digital Twin project for Week 2 of the AI Engineer Production Track.

The project is currently complete through Day 2:

- Day 1: local twin with file-based memory
- Day 2: deployment to AWS with S3, Lambda, API Gateway, and static frontend hosting

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
├── frontend/
│   ├── app/
│   ├── components/
│   ├── public/
│   ├── next.config.ts
│   └── package.json
├── memory/
├── week2/
│   ├── day1.md
│   ├── day1_summary.md
│   ├── day2.md
│   ├── day2_summary.md
│   ├── day3.md
│   ├── day4.md
│   └── day5.md
└── README.md
```

## Tech Stack

- Frontend: Next.js 16, React 19, TypeScript, Tailwind CSS
- Backend: FastAPI, OpenAI Python SDK, `boto3`, `pypdf`, `mangum`
- Python package manager: `uv`
- Local memory: JSON files in `memory/`
- Cloud deployment: AWS Lambda, API Gateway, S3 static hosting, S3 memory bucket

## Day 1

### Goal

Build a local AI Digital Twin that can chat through a Next.js frontend, call a FastAPI backend, and persist conversation history locally.

### Day 1 Architecture

1. The user sends a message from the frontend chat UI.
2. The frontend calls `POST /chat` on the FastAPI backend.
3. The backend loads the twin personality and conversation history.
4. The backend sends system prompt + history + user message to OpenAI.
5. The assistant response is saved into `memory/<session_id>.json`.

### Day 1 Local Setup

Backend environment:

```env
OPENAI_API_KEY=your_openai_api_key_here
CORS_ORIGINS=http://localhost:3000
```

Run backend:

```bash
cd backend
uv sync
uv run server.py
```

Run frontend:

```bash
cd frontend
npm install
npm run dev
```

Local URLs:

- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000`

## Day 2

### Goal

Upgrade the twin from a local-only app to an AWS deployment with:

- richer personal context from `backend/data/`
- Lambda-compatible FastAPI backend
- S3-based conversation memory
- API Gateway for HTTP access
- static frontend export hosted on S3

### Day 2 Architecture

1. The browser loads the static Next.js export from S3 hosting.
2. The chat UI sends `POST /chat` to API Gateway.
3. API Gateway invokes AWS Lambda through `backend/lambda_handler.py`.
4. Lambda runs the FastAPI app from `backend/server.py`.
5. The backend reads prompt context from `backend/data/`.
6. Conversation history is loaded from and saved to the S3 memory bucket.
7. OpenAI generates the reply and the frontend renders it.

### Day 2 Backend Changes

- `backend/resources.py` loads `facts.json`, `summary.txt`, `style.txt`, and `linkedin.pdf`
- `backend/context.py` builds the richer system prompt
- `backend/server.py` supports `USE_S3` and `S3_BUCKET`
- `backend/lambda_handler.py` exposes the Mangum handler for Lambda
- `backend/deploy.py` builds `lambda-deployment.zip` using the AWS Lambda Python container

### Day 2 Frontend Changes

- `frontend/next.config.ts` uses `output: "export"` for static deployment
- `frontend/components/twin.tsx` calls the deployed API Gateway `/chat` endpoint
- production assets are built with `npm run build` and uploaded from `frontend/out/`

### AWS Environment Variables

Lambda requires:

```env
OPENAI_API_KEY=your_openai_api_key_here
CORS_ORIGINS=*
USE_S3=true
S3_BUCKET=your-memory-bucket-name
```

Project root `.env` for local AWS-related workflow:

```env
AWS_ACCOUNT_ID=your_aws_account_id
DEFAULT_AWS_REGION=your_region
OPENAI_API_KEY=your_openai_api_key
PROJECT_NAME=twin
```

### Deployment Workflow

Build Lambda package:

```bash
cd backend
uv sync
uv run deploy.py
```

Build static frontend:

```bash
cd frontend
npm install
npm run build
```

Upload static export to S3:

```bash
aws s3 sync out/ s3://your-frontend-bucket/ --delete
```

### Deployed Endpoints

Current project deployment used:

- API root: `https://r7ewqxjlke.execute-api.ap-southeast-1.amazonaws.com/`
- API health: `https://r7ewqxjlke.execute-api.ap-southeast-1.amazonaws.com/health`
- Frontend website: `http://twin-frontend-487592470523.s3-website-ap-southeast-1.amazonaws.com/`

### API Endpoints

#### `GET /`

Returns service metadata:

```json
{
  "message": "AI Digital Twin API",
  "memory_enabled": true,
  "storage": "S3"
}
```

#### `GET /health`

Returns basic health information:

```json
{
  "status": "healthy",
  "use_s3": true
}
```

#### `POST /chat`

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

#### `GET /conversation/{session_id}`

Returns stored conversation history for one session.

## Important Files

- `backend/server.py`: FastAPI app, OpenAI call, local/S3 memory logic
- `backend/context.py`: dynamic system prompt
- `backend/resources.py`: personal context loader
- `backend/lambda_handler.py`: Lambda entrypoint via Mangum
- `backend/deploy.py`: Lambda packaging script
- `frontend/components/twin.tsx`: chat interface and API call
- `frontend/next.config.ts`: static export configuration
- `memory/`: local conversation files for Day 1
- `week2/day1.md`: original Day 1 lesson
- `week2/day2.md`: original Day 2 lesson
- `week2/day1_summary.md`: Day 1 study notes
- `week2/day2_summary.md`: Day 2 study notes

## Known Constraints

- `CORS_ORIGINS=*` is acceptable for the lab but should be narrowed for a real deployment.
- Conversation storage in S3 is simple and works for the course, but it is not a multi-user production design.
- The deployed frontend is a static export, so dynamic Next.js server features are intentionally not used.
- There is no automated test suite yet for backend or frontend behavior.

## Next README Updates

Future updates should extend this README with Day 3 to Day 5 as the project moves from OpenAI-on-AWS infrastructure toward more advanced AWS-native production patterns.
