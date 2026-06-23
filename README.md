# Twin

AI Digital Twin project for Week 2 of the AI Engineer Production Track.

This README currently documents only `day1`. New sections for `day2` to `day5` should be appended below in later study sessions.

## Day 1

### Goal

Build a local AI Digital Twin that can:

- chat through a Next.js frontend
- call a FastAPI backend
- use a personality file from `backend/me.txt`
- persist conversation history in the `memory/` folder

### What Day 1 Covers

- Next.js App Router project structure
- chat UI with React and Tailwind CSS
- FastAPI backend for AI chat
- OpenAI API integration
- why stateless chat is limited
- basic file-based memory for session persistence

### Current Project Structure

```text
twin/
├── backend/
│   ├── me.txt
│   ├── pyproject.toml
│   ├── requirements.txt
│   ├── server.py
│   └── uv.lock
├── frontend/
│   ├── app/
│   ├── components/
│   ├── public/
│   └── package.json
├── memory/
├── week2/
│   ├── day1.md
│   ├── day1_summary.md
│   ├── day2.md
│   ├── day3.md
│   ├── day4.md
│   └── day5.md
└── README.md
```

### Tech Stack

- Frontend: Next.js 16, React 19, TypeScript, Tailwind CSS
- Backend: FastAPI, Uvicorn, OpenAI Python SDK, python-dotenv
- Python package manager: `uv`
- Memory storage: local JSON files in `memory/`

### How The App Works

1. The user sends a message from the frontend chat UI.
2. The frontend calls `POST /chat` on the FastAPI backend.
3. The backend loads the twin personality from `backend/me.txt`.
4. The backend loads prior messages for the active `session_id` from `memory/<session_id>.json`.
5. The backend sends personality + conversation history + latest user message to the OpenAI API.
6. The assistant reply is returned to the frontend and saved back to the memory file.

### Day 1 Learning Note

The original lesson introduces the problem of stateless chat first, then adds memory.  
This repo is already at the improved Day 1 state: conversation memory is implemented in `backend/server.py`.

### Setup

#### 1. Backend

Create `backend/.env` with:

```env
OPENAI_API_KEY=your_openai_api_key_here
CORS_ORIGINS=http://localhost:3000
```

Install dependencies:

```bash
cd backend
uv sync
```

Run the API server:

```bash
cd backend
uv run server.py
```

The backend runs on `http://localhost:8000`.

#### 2. Frontend

Install dependencies:

```bash
cd frontend
npm install
```

Run the development server:

```bash
cd frontend
npm run dev
```

The frontend runs on `http://localhost:3000`.

### API Endpoints

#### `GET /`

Health-style root message for the API.

#### `GET /health`

Returns basic API health status.

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

#### `GET /sessions`

Returns saved local chat sessions from the `memory/` directory.

### Important Files

- `backend/server.py`: FastAPI server, OpenAI call, memory load/save logic
- `backend/me.txt`: digital twin personality prompt
- `frontend/components/twin.tsx`: chat interface and client-side session handling
- `frontend/app/page.tsx`: landing page that renders the twin UI
- `memory/`: local JSON conversation history
- `week2/day1.md`: original lesson notes
- `week2/day1_summary.md`: summarized study notes

### Known Constraints

- Memory is file-based, so it is suitable for local learning, not production.
- The frontend currently calls `http://localhost:8000/chat` directly.
- Session history is stored locally and not tied to authentication.
- There is no test suite yet for backend or frontend behavior.

### Next README Updates

When continuing with later lessons, append new sections below this file in the format:

- `## Day 2`
- `## Day 3`
- `## Day 4`
- `## Day 5`
