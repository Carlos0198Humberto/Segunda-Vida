from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date, datetime, timezone
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.health import MealLog, HydrationLog, SleepLog, MoodLog, GymSession
from app.schemas.health import (
    MealCreate, MealResponse,
    HydrationCreate, HydrationResponse, HydrationSummary,
    SleepCreate, SleepResponse,
    MoodCreate, MoodResponse, HealthSummary,
    GymCreate, GymResponse,
)

router = APIRouter()

# ── Meals ─────────────────────────────────────────────────────────────────────

@router.get("/meals", response_model=List[MealResponse])
def list_meals(day: Optional[date] = None, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    q = db.query(MealLog).filter(MealLog.user_id == current_user.id)
    if day:
        q = q.filter(MealLog.date == day)
    return q.order_by(MealLog.date.desc()).all()


@router.post("/meals", response_model=MealResponse, status_code=201)
def create_meal(payload: MealCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    meal = MealLog(user_id=current_user.id, **payload.model_dump())
    db.add(meal)
    db.commit()
    db.refresh(meal)
    return meal


@router.delete("/meals/{meal_id}", status_code=204)
def delete_meal(meal_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    meal = db.query(MealLog).filter(MealLog.id == meal_id, MealLog.user_id == current_user.id).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
    db.delete(meal)
    db.commit()

# ── Hydration ──────────────────────────────────────────────────────────────────

@router.get("/hydration/today", response_model=HydrationSummary)
def hydration_today(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    logs = db.query(HydrationLog).filter(
        HydrationLog.user_id == current_user.id,
        HydrationLog.date == today,
    ).order_by(HydrationLog.logged_at).all()

    total = sum(l.amount_ml for l in logs)
    goal = int(current_user.daily_water_goal_ml)

    return HydrationSummary(
        today_ml=total,
        goal_ml=goal,
        percentage=round(total / goal * 100, 1) if goal > 0 else 0,
        logs=logs,
    )


@router.post("/hydration", response_model=HydrationResponse, status_code=201)
def log_hydration(payload: HydrationCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    log = HydrationLog(user_id=current_user.id, **payload.model_dump())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

# ── Sleep ──────────────────────────────────────────────────────────────────────

@router.get("/sleep", response_model=List[SleepResponse])
def list_sleep(limit: int = 14, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(SleepLog).filter(SleepLog.user_id == current_user.id).order_by(SleepLog.date.desc()).limit(limit).all()


@router.post("/sleep", response_model=SleepResponse, status_code=201)
def log_sleep(payload: SleepCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    duration = (payload.wake_time - payload.bed_time).total_seconds() / 3600
    log = SleepLog(
        user_id=current_user.id,
        bed_time=payload.bed_time,
        wake_time=payload.wake_time,
        duration_hours=round(duration, 2),
        quality=payload.quality,
        notes=payload.notes,
        date=payload.date,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.delete("/sleep/{log_id}", status_code=204)
def delete_sleep(log_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    log = db.query(SleepLog).filter(SleepLog.id == log_id, SleepLog.user_id == current_user.id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Sleep log not found")
    db.delete(log)
    db.commit()

# ── Mood ───────────────────────────────────────────────────────────────────────

@router.post("/mood", response_model=MoodResponse, status_code=201)
def log_mood(payload: MoodCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    log = MoodLog(user_id=current_user.id, **payload.model_dump())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

# ── Gym ────────────────────────────────────────────────────────────────────────

@router.get("/gym", response_model=List[GymResponse])
def list_gym_sessions(limit: int = 30, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(GymSession).filter(GymSession.user_id == current_user.id).order_by(GymSession.date.desc()).limit(limit).all()


@router.post("/gym", response_model=GymResponse, status_code=201)
def log_gym_session(payload: GymCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    session = GymSession(user_id=current_user.id, **payload.model_dump())
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.delete("/gym/{session_id}", status_code=204)
def delete_gym_session(session_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    session = db.query(GymSession).filter(GymSession.id == session_id, GymSession.user_id == current_user.id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Gym session not found")
    db.delete(session)
    db.commit()

# ── Summary ────────────────────────────────────────────────────────────────────

def _compute_health_score(water_pct: float, sleep_hours: Optional[float], sleep_goal: float, gym_days: int) -> int:
    score = 0
    # Water: up to 30 points
    score += min(30, int(water_pct * 0.3))
    # Sleep: up to 35 points
    if sleep_hours is not None:
        sleep_ratio = min(1.0, sleep_hours / sleep_goal) if sleep_goal > 0 else 0
        score += int(sleep_ratio * 35)
    # Gym: up to 35 points (target 12 sessions/month = 100%)
    score += min(35, int(gym_days / 12 * 35))
    return min(100, score)


@router.get("/summary", response_model=HealthSummary)
def health_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()

    water_today = db.query(func.sum(HydrationLog.amount_ml)).filter(
        HydrationLog.user_id == current_user.id, HydrationLog.date == today,
    ).scalar() or 0
    water_goal = int(current_user.daily_water_goal_ml)
    water_pct = round(water_today / water_goal * 100, 1) if water_goal > 0 else 0

    last_sleep = db.query(SleepLog).filter(
        SleepLog.user_id == current_user.id,
    ).order_by(SleepLog.date.desc()).first()
    sleep_hours = float(last_sleep.duration_hours) if last_sleep and last_sleep.duration_hours else None
    sleep_goal = float(current_user.daily_sleep_goal_hours)

    today_meals = db.query(MealLog).filter(MealLog.user_id == current_user.id, MealLog.date == today).all()
    today_calories = sum(m.calories or 0 for m in today_meals)

    last_mood = db.query(MoodLog).filter(
        MoodLog.user_id == current_user.id, MoodLog.date == today,
    ).order_by(MoodLog.logged_at.desc()).first()

    gym_days = db.query(func.count(GymSession.id)).filter(
        GymSession.user_id == current_user.id,
        GymSession.date >= date(today.year, today.month, 1),
    ).scalar() or 0

    health_score = _compute_health_score(water_pct, sleep_hours, sleep_goal, gym_days)

    return HealthSummary(
        today_water_ml=water_today,
        water_goal_ml=water_goal,
        water_percentage=water_pct,
        last_sleep_hours=sleep_hours,
        sleep_goal_hours=sleep_goal,
        sleep_quality=last_sleep.quality if last_sleep else None,
        today_calories=today_calories,
        today_meals=len(today_meals),
        current_mood=last_mood.mood if last_mood else None,
        gym_days_this_month=gym_days,
        health_score=health_score,
    )
