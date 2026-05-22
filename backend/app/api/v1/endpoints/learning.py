from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date, timedelta
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.learning import LearningItem, LearningSession
from app.schemas.learning import (
    LearningItemCreate, LearningItemUpdate, LearningItemResponse,
    LearningSessionCreate, LearningSessionResponse, LearningSummary,
)

router = APIRouter()


@router.get("", response_model=List[LearningItemResponse])
def list_items(
    status: Optional[str] = None,
    item_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(LearningItem).filter(LearningItem.user_id == current_user.id)
    if status:
        q = q.filter(LearningItem.status == status)
    if item_type:
        q = q.filter(LearningItem.item_type == item_type)
    return q.order_by(LearningItem.created_at.desc()).all()


@router.post("", response_model=LearningItemResponse, status_code=201)
def create_item(payload: LearningItemCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = LearningItem(user_id=current_user.id, **payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.put("/{item_id}", response_model=LearningItemResponse)
def update_item(item_id: uuid.UUID, payload: LearningItemUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = db.query(LearningItem).filter(LearningItem.id == item_id, LearningItem.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Learning item not found")

    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(item, field, value)

    if payload.status == "in_progress" and not item.started_at:
        item.started_at = date.today()
    if payload.status == "completed" and not item.completed_at:
        item.completed_at = date.today()
        item.progress_percentage = 100

    db.commit()
    db.refresh(item)
    return item


@router.delete("/{item_id}", status_code=204)
def delete_item(item_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = db.query(LearningItem).filter(LearningItem.id == item_id, LearningItem.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Learning item not found")
    db.delete(item)
    db.commit()


@router.post("/sessions", response_model=LearningSessionResponse, status_code=201)
def log_session(payload: LearningSessionCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = db.query(LearningItem).filter(LearningItem.id == payload.learning_item_id, LearningItem.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Learning item not found")

    session = LearningSession(user_id=current_user.id, **payload.model_dump())
    db.add(session)

    item.total_hours = (item.total_hours or 0) + round(payload.duration_minutes / 60)
    if payload.pages_covered and item.current_page is not None:
        item.current_page = (item.current_page or 0) + payload.pages_covered
        if item.total_pages and item.current_page >= item.total_pages:
            item.progress_percentage = 100
            item.status = "completed"
            item.completed_at = payload.date
        elif item.total_pages:
            item.progress_percentage = round(item.current_page / item.total_pages * 100)

    if item.status == "planned":
        item.status = "in_progress"
        item.started_at = payload.date

    db.commit()
    db.refresh(session)
    return session


@router.get("/summary", response_model=LearningSummary)
def learning_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())

    items = db.query(LearningItem).filter(LearningItem.user_id == current_user.id).all()
    total_hours = sum(i.total_hours or 0 for i in items)
    completed = sum(1 for i in items if i.status == "completed")
    in_progress = sum(1 for i in items if i.status == "in_progress")

    weekly_minutes = db.query(func.sum(LearningSession.duration_minutes)).filter(
        LearningSession.user_id == current_user.id,
        LearningSession.date >= week_start,
    ).scalar() or 0

    return LearningSummary(
        total_items=len(items),
        completed_items=completed,
        in_progress_items=in_progress,
        total_hours=total_hours,
        weekly_hours=round(weekly_minutes / 60, 1),
        current_streak_days=0,
    )
