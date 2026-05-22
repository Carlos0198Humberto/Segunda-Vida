from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List
from datetime import date, timedelta
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.skill import Skill, SkillEntry
from app.schemas.skill import (
    SkillCreate, SkillUpdate, SkillResponse,
    SkillEntryCreate, SkillEntryResponse, SkillSummary,
)

router = APIRouter()


def _enrich(skill: Skill, db: Session, user_id: uuid.UUID) -> SkillResponse:
    today = date.today()
    days_since = (today - skill.start_date).days if skill.start_date else 0

    progress = None
    if skill.target_days and days_since is not None:
        progress = min(100.0, round(skill.total_sessions / max(skill.target_days, 1) * 100, 1))
    elif skill.target_sessions and skill.total_sessions is not None:
        progress = min(100.0, round(skill.total_sessions / skill.target_sessions * 100, 1))

    logged_today = db.query(SkillEntry).filter(
        and_(SkillEntry.skill_id == skill.id, SkillEntry.date == today)
    ).first() is not None

    r = SkillResponse.model_validate(skill)
    r.days_since_start = days_since
    r.progress_pct = progress
    r.logged_today = logged_today
    return r


def _recalculate_streak(skill: Skill, db: Session):
    entries = (
        db.query(SkillEntry.date)
        .filter(SkillEntry.skill_id == skill.id, SkillEntry.completed == True)
        .order_by(SkillEntry.date.desc())
        .all()
    )
    dates = sorted({e.date for e in entries}, reverse=True)
    if not dates:
        skill.current_streak = 0
        return

    streak = 1
    check = dates[0]
    today = date.today()
    if check < today - timedelta(days=1):
        skill.current_streak = 0
        return

    for i in range(1, len(dates)):
        if dates[i] == check - timedelta(days=1):
            streak += 1
            check = dates[i]
        else:
            break

    skill.current_streak = streak
    if streak > skill.longest_streak:
        skill.longest_streak = streak


@router.get("/summary", response_model=SkillSummary)
def get_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    skills = db.query(Skill).filter(Skill.user_id == current_user.id, Skill.is_active == True).all()
    today = date.today()
    sessions_today = db.query(func.count(SkillEntry.id)).filter(
        and_(SkillEntry.user_id == current_user.id, SkillEntry.date == today)
    ).scalar() or 0
    best_streak = max((s.current_streak for s in skills), default=0)

    return SkillSummary(
        total_skills=len(skills),
        active_skills=len([s for s in skills if s.is_active]),
        total_sessions_today=sessions_today,
        best_streak=best_streak,
        skills=[_enrich(s, db, current_user.id) for s in skills],
    )


@router.get("/", response_model=List[SkillResponse])
def list_skills(
    category: str = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    q = db.query(Skill).filter(Skill.user_id == current_user.id)
    if category:
        q = q.filter(Skill.category == category)
    skills = q.order_by(Skill.created_at.desc()).all()
    return [_enrich(s, db, current_user.id) for s in skills]


@router.post("/", response_model=SkillResponse, status_code=201)
def create_skill(
    data: SkillCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = Skill(user_id=current_user.id, **data.model_dump(exclude_none=True))
    if not skill.start_date:
        skill.start_date = date.today()
    db.add(skill)
    db.commit()
    db.refresh(skill)
    return _enrich(skill, db, current_user.id)


@router.patch("/{skill_id}", response_model=SkillResponse)
def update_skill(
    skill_id: uuid.UUID,
    data: SkillUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = db.query(Skill).filter(Skill.id == skill_id, Skill.user_id == current_user.id).first()
    if not skill:
        raise HTTPException(404, "Skill not found")
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(skill, k, v)
    db.commit()
    db.refresh(skill)
    return _enrich(skill, db, current_user.id)


@router.delete("/{skill_id}", status_code=204)
def delete_skill(
    skill_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = db.query(Skill).filter(Skill.id == skill_id, Skill.user_id == current_user.id).first()
    if not skill:
        raise HTTPException(404, "Skill not found")
    db.delete(skill)
    db.commit()


@router.post("/log", response_model=SkillEntryResponse, status_code=201)
def log_entry(
    data: SkillEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = db.query(Skill).filter(Skill.id == data.skill_id, Skill.user_id == current_user.id).first()
    if not skill:
        raise HTTPException(404, "Skill not found")

    entry_date = data.date or date.today()

    existing = db.query(SkillEntry).filter(
        and_(SkillEntry.skill_id == data.skill_id, SkillEntry.date == entry_date)
    ).first()
    if existing:
        for k, v in data.model_dump(exclude_none=True, exclude={"skill_id"}).items():
            setattr(existing, k, v)
        entry = existing
    else:
        entry = SkillEntry(
            user_id=current_user.id,
            date=entry_date,
            **data.model_dump(exclude_none=True),
        )
        db.add(entry)
        skill.total_sessions += 1
        if data.duration_minutes:
            skill.total_minutes += data.duration_minutes

    db.flush()
    _recalculate_streak(skill, db)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/{skill_id}/entries", response_model=List[SkillEntryResponse])
def get_entries(
    skill_id: uuid.UUID,
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    skill = db.query(Skill).filter(Skill.id == skill_id, Skill.user_id == current_user.id).first()
    if not skill:
        raise HTTPException(404, "Skill not found")
    entries = (
        db.query(SkillEntry)
        .filter(SkillEntry.skill_id == skill_id)
        .order_by(SkillEntry.date.desc())
        .limit(limit)
        .all()
    )
    return entries
