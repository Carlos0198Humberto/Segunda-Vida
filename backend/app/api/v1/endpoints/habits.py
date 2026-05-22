from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date, timedelta
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.habit import Habit, HabitLog
from app.schemas.habit import (
    HabitCreate, HabitUpdate, HabitResponse,
    HabitLogCreate, HabitLogResponse, HabitSummary,
)

router = APIRouter()


def _enrich_habit(habit: Habit, db: Session) -> HabitResponse:
    today = date.today()
    week_ago = today - timedelta(days=7)

    completed_today = db.query(HabitLog).filter(
        HabitLog.habit_id == habit.id,
        HabitLog.completed_at == today,
    ).first() is not None

    logs_7d = db.query(HabitLog).filter(
        HabitLog.habit_id == habit.id,
        HabitLog.completed_at >= week_ago,
        HabitLog.completed_at <= today,
    ).count()

    return HabitResponse(
        id=habit.id,
        name=habit.name,
        description=habit.description,
        habit_type=habit.habit_type,
        frequency=habit.frequency,
        target_count=habit.target_count,
        icon=habit.icon,
        color=habit.color,
        reminder_time=habit.reminder_time,
        is_active=habit.is_active,
        current_streak=habit.current_streak,
        longest_streak=habit.longest_streak,
        completed_today=completed_today,
        completion_rate_7days=round(logs_7d / 7 * 100, 1),
        created_at=habit.created_at,
    )


def _recalculate_streak(habit: Habit, db: Session):
    today = date.today()
    streak = 0
    check_date = today

    while True:
        log = db.query(HabitLog).filter(
            HabitLog.habit_id == habit.id,
            HabitLog.completed_at == check_date,
        ).first()
        if log:
            streak += 1
            check_date -= timedelta(days=1)
        else:
            break

    habit.current_streak = streak
    if streak > habit.longest_streak:
        habit.longest_streak = streak


@router.get("", response_model=HabitSummary)
def list_habits(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    habits = db.query(Habit).filter(Habit.user_id == current_user.id, Habit.is_active == True).all()
    enriched = [_enrich_habit(h, db) for h in habits]
    completed_today = sum(1 for h in enriched if h.completed_today)
    best_streak = max((h.current_streak for h in enriched), default=0)

    return HabitSummary(
        total_habits=len(habits),
        active_habits=len(habits),
        completed_today=completed_today,
        best_streak=best_streak,
        habits=enriched,
    )


@router.post("", response_model=HabitResponse, status_code=201)
def create_habit(payload: HabitCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    habit = Habit(user_id=current_user.id, **payload.model_dump())
    db.add(habit)
    db.commit()
    db.refresh(habit)
    return _enrich_habit(habit, db)


@router.put("/{habit_id}", response_model=HabitResponse)
def update_habit(habit_id: uuid.UUID, payload: HabitUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    habit = db.query(Habit).filter(Habit.id == habit_id, Habit.user_id == current_user.id).first()
    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(habit, field, value)
    db.commit()
    db.refresh(habit)
    return _enrich_habit(habit, db)


@router.delete("/{habit_id}", status_code=204)
def delete_habit(habit_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    habit = db.query(Habit).filter(Habit.id == habit_id, Habit.user_id == current_user.id).first()
    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")
    habit.is_active = False
    db.commit()


@router.post("/log", response_model=HabitLogResponse, status_code=201)
def log_habit(payload: HabitLogCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    habit = db.query(Habit).filter(Habit.id == payload.habit_id, Habit.user_id == current_user.id).first()
    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")

    existing = db.query(HabitLog).filter(
        HabitLog.habit_id == payload.habit_id,
        HabitLog.completed_at == payload.completed_at,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Habit already logged for this date")

    log = HabitLog(**payload.model_dump())
    db.add(log)
    _recalculate_streak(habit, db)
    db.commit()
    db.refresh(log)
    return log


@router.get("/heatmap")
def habit_heatmap(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Returns last 90 days of habit completions as {date: count} map."""
    today = date.today()
    start = today - timedelta(days=89)

    total_habits = db.query(Habit).filter(
        Habit.user_id == current_user.id,
        Habit.is_active == True,
    ).count()

    logs = db.query(HabitLog).join(Habit).filter(
        Habit.user_id == current_user.id,
        HabitLog.completed_at >= start,
        HabitLog.completed_at <= today,
    ).all()

    counts: dict[str, int] = {}
    for log in logs:
        key = log.completed_at.isoformat()
        counts[key] = counts.get(key, 0) + 1

    return {
        "heatmap": counts,
        "total_habits": total_habits,
        "start": start.isoformat(),
        "end": today.isoformat(),
    }


@router.delete("/log/{log_id}", status_code=204)
def delete_habit_log(log_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    log = db.query(HabitLog).join(Habit).filter(
        HabitLog.id == log_id,
        Habit.user_id == current_user.id,
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    habit = log.habit
    db.delete(log)
    _recalculate_streak(habit, db)
    db.commit()
