from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, datetime, timezone
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.diary import DayEntry
from app.schemas.diary import DayEntryCreate, DayEntryResponse

router = APIRouter()


@router.get("/today", response_model=List[DayEntryResponse])
def get_today_entries(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    return (
        db.query(DayEntry)
        .filter(DayEntry.user_id == current_user.id, DayEntry.date == today)
        .order_by(DayEntry.logged_at.desc())
        .all()
    )


@router.get("/history", response_model=List[DayEntryResponse])
def get_history(
    limit: int = 50,
    day: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(DayEntry).filter(DayEntry.user_id == current_user.id)
    if day:
        q = q.filter(DayEntry.date == day)
    return q.order_by(DayEntry.logged_at.desc()).limit(limit).all()


@router.post("/", response_model=DayEntryResponse, status_code=201)
def create_entry(
    payload: DayEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = DayEntry(
        user_id=current_user.id,
        content=payload.content,
        category=payload.category,
        emoji=payload.emoji,
        date=payload.date or date.today(),
        source="manual",
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
def delete_entry(
    entry_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(DayEntry).filter(DayEntry.id == entry_id, DayEntry.user_id == current_user.id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    db.delete(entry)
    db.commit()
