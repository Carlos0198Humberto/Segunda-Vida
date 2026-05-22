from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, timedelta, datetime, timezone
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.planning import WeeklyPlan, DailyPlanItem
from app.schemas.planning import (
    WeeklyPlanCreate, WeeklyPlanUpdate, WeeklyPlanResponse,
    DailyPlanItemCreate, DailyPlanItemUpdate, DailyPlanItemResponse,
)

router = APIRouter()


def _enrich_plan(plan: WeeklyPlan) -> WeeklyPlanResponse:
    total = len(plan.items)
    completed = sum(1 for i in plan.items if i.is_completed)
    rate = round(completed / total * 100, 1) if total > 0 else 0.0

    return WeeklyPlanResponse(
        id=plan.id,
        week_start=plan.week_start,
        week_end=plan.week_end,
        main_goal=plan.main_goal,
        notes=plan.notes,
        energy_level=plan.energy_level,
        is_reviewed=plan.is_reviewed,
        review_notes=plan.review_notes,
        items=[DailyPlanItemResponse.model_validate(i) for i in plan.items],
        completion_rate=rate,
        created_at=plan.created_at,
    )


@router.get("", response_model=List[WeeklyPlanResponse])
def list_plans(
    limit: int = Query(8, le=52),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    plans = db.query(WeeklyPlan).filter(
        WeeklyPlan.user_id == current_user.id,
    ).order_by(WeeklyPlan.week_start.desc()).limit(limit).all()
    return [_enrich_plan(p) for p in plans]


@router.get("/current", response_model=WeeklyPlanResponse)
def get_current_week(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    plan = db.query(WeeklyPlan).filter(
        WeeklyPlan.user_id == current_user.id,
        WeeklyPlan.week_start == week_start,
    ).first()

    if not plan:
        plan = WeeklyPlan(user_id=current_user.id, week_start=week_start, week_end=week_end)
        db.add(plan)
        db.commit()
        db.refresh(plan)

    return _enrich_plan(plan)


@router.post("", response_model=WeeklyPlanResponse, status_code=201)
def create_plan(payload: WeeklyPlanCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = db.query(WeeklyPlan).filter(
        WeeklyPlan.user_id == current_user.id,
        WeeklyPlan.week_start == payload.week_start,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Plan already exists for this week")
    plan = WeeklyPlan(user_id=current_user.id, **payload.model_dump())
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return _enrich_plan(plan)


@router.put("/{plan_id}", response_model=WeeklyPlanResponse)
def update_plan(plan_id: uuid.UUID, payload: WeeklyPlanUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    plan = db.query(WeeklyPlan).filter(WeeklyPlan.id == plan_id, WeeklyPlan.user_id == current_user.id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(plan, field, value)
    if payload.is_reviewed:
        plan.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(plan)
    return _enrich_plan(plan)


@router.post("/items", response_model=DailyPlanItemResponse, status_code=201)
def create_item(payload: DailyPlanItemCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    plan = db.query(WeeklyPlan).filter(WeeklyPlan.id == payload.weekly_plan_id, WeeklyPlan.user_id == current_user.id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Weekly plan not found")
    item = DailyPlanItem(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.put("/items/{item_id}", response_model=DailyPlanItemResponse)
def update_item(item_id: uuid.UUID, payload: DailyPlanItemUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = db.query(DailyPlanItem).join(WeeklyPlan).filter(
        DailyPlanItem.id == item_id,
        WeeklyPlan.user_id == current_user.id,
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(item, field, value)
    if payload.is_completed and not item.completed_at:
        item.completed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    item = db.query(DailyPlanItem).join(WeeklyPlan).filter(
        DailyPlanItem.id == item_id,
        WeeklyPlan.user_id == current_user.id,
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
