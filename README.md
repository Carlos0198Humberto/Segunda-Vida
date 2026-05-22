# Segunda Vida — Personal Life Operating System

A production-ready full-stack personal life OS built with Flutter + FastAPI.

---

## Architecture

```
segunda-vida/
├── backend/              # FastAPI + PostgreSQL
│   ├── app/
│   │   ├── api/v1/      # REST endpoints
│   │   ├── core/        # Config, DB, Security
│   │   ├── models/      # SQLAlchemy models
│   │   ├── schemas/     # Pydantic schemas
│   │   └── services/    # Business logic
│   ├── alembic/         # DB migrations
│   └── main.py
├── frontend/             # Flutter app
│   └── lib/
│       ├── core/        # Theme, routing, storage, network
│       ├── features/    # Feature modules (clean arch)
│       └── shared/      # Shared widgets
└── docker-compose.yml
```

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x, Riverpod, Material 3, fl_chart, Hive |
| Backend | FastAPI, SQLAlchemy 2, Alembic, JWT |
| Database | PostgreSQL 16 |
| Cache | Hive (local), Redis (optional) |
| Auth | JWT + PIN + Biometric |
| Charts | fl_chart |
| Deployment | Docker + Docker Compose |

---

## Quick Start

### 1. Clone and configure

```bash
cp .env.example .env
# Edit .env with your values
```

### 2. Start with Docker (recommended)

```bash
docker-compose up -d
```

Backend will be at: `http://localhost:8000`  
API docs: `http://localhost:8000/docs`

### 3. Run backend locally (without Docker)

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set up PostgreSQL, then run migrations:
alembic upgrade head

# Start the server:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Run Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

For a specific platform:
```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
```

---

## Modules

| # | Module | Features |
|---|---|---|
| 1 | Dashboard | Balance, habits, water, sleep, savings, motivation |
| 2 | Finance | Accounts, income/expenses, categories, budgets |
| 3 | Savings | Fund goals, contributions, progress, ETA |
| 4 | Habits | Streaks, positive/negative tracking, reminders |
| 5 | Planning | Weekly planner, daily schedule, task completion |
| 6 | Time Tracking | Productive/study/wasted hours, weekly report |
| 7 | Health | Hydration, sleep log, meals, mood |
| 8 | Rewards | Create rewards, unlock when goals achieved |
| 9 | Learning | Books, courses, sessions, progress |
| 10 | Analytics | Finance trends, habit heatmap, yearly overview |

---

## API Endpoints Summary

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/dashboard
GET    /api/v1/finances/transactions
POST   /api/v1/finances/transactions
GET    /api/v1/savings
POST   /api/v1/savings
POST   /api/v1/savings/{id}/contribute
GET    /api/v1/habits
POST   /api/v1/habits/log
GET    /api/v1/planning/current
POST   /api/v1/planning/items
GET    /api/v1/health/hydration/today
POST   /api/v1/health/hydration
POST   /api/v1/health/sleep
GET    /api/v1/time/report/weekly
GET    /api/v1/learning
POST   /api/v1/learning/sessions
GET    /api/v1/rewards
POST   /api/v1/rewards/{id}/claim
GET    /api/v1/analytics/overview
```

---

## Database Schema

Core tables:
- `users` — accounts, settings, goals
- `accounts` + `transactions` + `categories` + `budgets` — finance
- `savings_funds` + `savings_contributions` — savings
- `habits` + `habit_logs` — habit tracking
- `time_entries` — time tracking
- `meal_logs` + `hydration_logs` + `sleep_logs` + `mood_logs` — health
- `learning_items` + `learning_sessions` — learning
- `rewards` + `reward_claims` — rewards
- `weekly_plans` + `daily_plan_items` — planning

---

## Environment Variables

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/segunda_vida
SECRET_KEY=your-secret-key-min-32-chars
ACCESS_TOKEN_EXPIRE_MINUTES=1440
ENVIRONMENT=development
```

---

## Production Deployment

1. Set `ENVIRONMENT=production` in `.env`
2. Use a strong `SECRET_KEY`
3. Set up PostgreSQL with proper credentials
4. Run: `docker-compose up -d --build`
5. Run migrations: `docker exec segunda_vida_backend alembic upgrade head`

---

## Future: AI Integration (Ollama + Qwen)

The architecture is prepared for local AI. When ready:

```bash
# Install Ollama
ollama pull qwen2.5:7b

# Set in .env:
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5:7b
```

The `motivation_service.py` is designed for plug-in AI enhancement.

---

## Philosophy

> *Segunda Vida* — "Second Life" in Spanish.  
> The app exists to help you build the life you actually want, one small decision at a time.

---

*Built with Flutter, FastAPI, and PostgreSQL.*
