from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date, timedelta
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.time_entry import TimeEntry
from app.schemas.time_entry import TimeEntryCreate, TimeEntryResponse, TimeReport

router = APIRouter()

PRODUCTIVE_CATEGORIES = {"productive", "study", "learning", "reading", "exercise"}
WASTED_CATEGORIES = {"wasted", "phone", "entertainment"}


@router.get("/entries", response_model=List[TimeEntryResponse])
def list_entries(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(TimeEntry).filter(TimeEntry.user_id == current_user.id)
    if start_date:
        q = q.filter(TimeEntry.date >= start_date)
    if end_date:
        q = q.filter(TimeEntry.date <= end_date)
    if category:
        q = q.filter(TimeEntry.category == category)
    return q.order_by(TimeEntry.date.desc(), TimeEntry.created_at.desc()).all()


@router.post("/entries", response_model=TimeEntryResponse, status_code=201)
def create_entry(payload: TimeEntryCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    entry = TimeEntry(user_id=current_user.id, **payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/entries/{entry_id}", status_code=204)
def delete_entry(entry_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    from fastapi import HTTPException
    entry = db.query(TimeEntry).filter(TimeEntry.id == entry_id, TimeEntry.user_id == current_user.id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    db.delete(entry)
    db.commit()


@router.get("/report/weekly", response_model=TimeReport)
def weekly_report(
    week_start: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not week_start:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    return _build_report(db, current_user.id, week_start, week_end, "weekly")


@router.get("/report/monthly", response_model=TimeReport)
def monthly_report(
    year: int,
    month: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    start = date(year, month, 1)
    import calendar
    last_day = calendar.monthrange(year, month)[1]
    end = date(year, month, last_day)
    return _build_report(db, current_user.id, start, end, "monthly")


def _build_report(db, user_id, start: date, end: date, period: str) -> TimeReport:
    entries = db.query(TimeEntry).filter(
        TimeEntry.user_id == user_id,
        TimeEntry.date >= start,
        TimeEntry.date <= end,
    ).all()

    cat_totals: dict = {}
    for e in entries:
        cat_totals[e.category] = cat_totals.get(e.category, 0) + e.duration_minutes

    total_minutes = sum(cat_totals.values())
    productive_min = sum(v for k, v in cat_totals.items() if k in PRODUCTIVE_CATEGORIES)
    wasted_min = sum(v for k, v in cat_totals.items() if k in WASTED_CATEGORIES)

    days = (end - start).days + 1
    productivity_score = (productive_min / total_minutes * 100) if total_minutes > 0 else 0

    return TimeReport(
        period=period,
        productive_hours=round(productive_min / 60, 1),
        study_hours=round(cat_totals.get("study", 0) / 60, 1),
        entertainment_hours=round(cat_totals.get("entertainment", 0) / 60, 1),
        phone_hours=round(cat_totals.get("phone", 0) / 60, 1),
        wasted_hours=round(wasted_min / 60, 1),
        reading_hours=round(cat_totals.get("reading", 0) / 60, 1),
        learning_hours=round(cat_totals.get("learning", 0) / 60, 1),
        total_tracked_hours=round(total_minutes / 60, 1),
        productivity_score=round(productivity_score, 1),
        breakdown=[{"category": k, "hours": round(v / 60, 1), "minutes": v} for k, v in cat_totals.items()],
        daily_average=round(total_minutes / 60 / days, 1),
    )
