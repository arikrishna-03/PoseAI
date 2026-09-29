# PoseMuse Backend - Firebase Cloud Functions (2nd Gen)

Production-ready serverless backend for **PoseMuse**, exposing an HTTPS endpoint that receives camera snapshots, calls Anthropic Claude Vision API, validates anatomical skeletons with Zod, and returns 5-6 structured photo ideas.

---

## 🏗️ Architecture & Security Highlights

- **Firebase Cloud Functions (2nd Gen)**: Built on Google Cloud Run with concurrency, 512 MiB memory, and 60-second execution budget.
- **Strict Secret Management**: The Anthropic API key is stored securely in **Google Cloud Secret Manager** (`defineSecret('ANTHROPIC_API_KEY')`). The mobile app never receives or touches the key.
- **Firebase Anonymous Authentication**: Every incoming request must provide an `Authorization: Bearer <ID_TOKEN>` header verified via `firebase-admin`. Unauthorized requests fail immediately with `401 unauthorized`.
- **Atomic Daily Rate Limiting**: Scans per user are tracked atomically in Firestore (`usage/{uid}_{YYYY-MM-DD}`) using Firestore transactions. Users exceeding 30 scans/day receive `429 rate_limited` with an exact UTC reset timestamp.
- **Dual-Layer In-Memory Protection**: In-memory IP-based sliding window blocks brute-force abuse.
- **Zero Image Retention**: Snapshots are decoded in-memory, validated for JPEG binary signatures, sent to Claude, and garbage collected. Images are never written to disk or database.
- **Anatomical Skeleton Sanity Checks**: Skeletons are verified for correct 17 COCO keypoint ordering, coordinate bounds `[0, 1]` (clamping small overshoots `[-0.05, 1.05]`), vertical posture order (shoulders above hips above knees above ankles with posture exceptions for "sit", "lie", "crouch", "lean", "jump"), and bone length ratios.

---

## 📋 Endpoint Specification

### `POST /generateIdeas`

#### Request Headers:
```http
Authorization: Bearer <Firebase_ID_Token>
Content-Type: application/json
```

#### Request Body (JSON):
```json
{
  "image_base64": "<JPEG base64 string, max 1.5 MB decoded, no data: prefix>",
  "people_count_hint": 1,
  "style_preference": "candid",
  "liked_titles": ["Sunset Backlight", "Coffee Lean"],
  "disliked_titles": ["Stiff Corporate"],
  "language": "en"
}
```

#### Success Response (`200 OK`):
```json
{
  "scene": {
    "location_type": "Outdoor Cafe Patio",
    "lighting": "Warm afternoon side-light",
    "people_count": 1,
    "outfit_summary": "Casual trench coat and dark scarf",
    "props": ["Cast iron table", "Steaming coffee cup", "Brick wall"]
  },
  "ideas": [
    {
      "title": "The Warm Mug Glance",
      "why_it_works": "Frames the subject against the rustic brick wall while steam catches the afternoon side-light.",
      "style": "candid",
      "difficulty": "easy",
      "camera_tips": {
        "height": "eye-level",
        "angle": "45-degree",
        "distance": "medium",
        "orientation": "portrait"
      },
      "expression_tip": "Soft contemplative smile looking over the cup rim.",
      "people": [
        {
          "position": "center",
          "description": "Seated leaning forward slightly with hands cupped around mug.",
          "keypoints": [
            { "x": 0.50, "y": 0.20 },
            ... 17 COCO landmarks total ...
          ]
        }
      ]
    }
  ]
}
```

#### Standard Error Response:
```json
{
  "error": {
    "code": "unauthorized | invalid_request | image_too_large | no_people_found | rate_limited | ai_invalid_response | ai_timeout",
    "message": "Human readable explanation",
    "reset_time": "2026-09-30T00:00:00.000Z"
  }
}
```

---

## ⚙️ Environment Variables & Secrets

| Variable | Type | Default | Description |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | Secret | *Required* | Managed via Firebase Secret Manager |
| `ANTHROPIC_MODEL` | Env Var | `claude-sonnet-5-5` | Model identifier (e.g. `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`) |
| `DAILY_LIMIT` | Env Var | `30` | Maximum allowed scans per user per calendar day |

### 💰 Cost Estimation & Model Selection
- **Claude 3.5 Sonnet (Default: `claude-sonnet-5-5`)**:
  - **Vision Input**: ~1,200 to 1,600 prompt tokens (depending on snapshot aspect ratio).
  - **Output Generation**: ~1,800 to 2,400 completion tokens (5-6 ideas with 17 keypoints each).
  - **Approx. Cost**: ~**$0.025 to $0.04 per scan**. Best visual reasoning and artistic composition quality.
- **Claude 3.5 Haiku (`claude-3-5-haiku-20241022`)**:
  - **Approx. Cost**: ~**$0.005 per scan** (80% cost reduction). Faster latency (1.5-2.5s).
  - To change: Set `ANTHROPIC_MODEL=claude-3-5-haiku-20241022` in `.env` or Firebase environment configuration.

---

## 🧪 Local Testing

### 1. Run Unit Tests (Vitest)
```bash
npm test
```
Runs schema validation, skeleton bounds checking, upside-down pose rejection, and title deduplication tests.

### 2. Run Firebase Emulator Suite
Make sure the Firebase CLI is installed (`npm install -g firebase-tools`):
```bash
# In pose_muse/
firebase emulators:start --only functions,firestore,auth
```

### 3. Test with `curl`
```bash
curl -X POST "http://127.0.0.1:5001/<your-project-id>/us-central1/generateIdeas" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your_firebase_auth_token>" \
  -d '{
    "image_base64": "/9j/4AAQSkZJRgABAQEASABIAAD...",
    "people_count_hint": 1,
    "style_preference": "candid",
    "liked_titles": ["Coffee Lean"],
    "disliked_titles": [],
    "language": "en"
  }'
```

### 4. Run Automated Test Script
```bash
npm run test:request
```

---

## 🚀 Deployment to Firebase Production

### 1. Set the Anthropic Secret
```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
# Enter your Claude API key when prompted
```

### 2. Deploy Functions & Firestore Rules
```bash
npm run build
firebase deploy --only functions
```
The deployed HTTPS endpoint will be outputted:
`https://us-central1-<your-project-id>.cloudfunctions.net/generateIdeas`
