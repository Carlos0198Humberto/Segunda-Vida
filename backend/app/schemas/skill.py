from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import date, datetime
import uuid


class SkillCreate(BaseModel):
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    emoji: str = "⭐"
    color: str = "#6B4EFF"
    target_days: Optional[int] = None
    target_sessions: Optional[int] = None
    start_date: Optional[date] = None


class SkillUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    emoji: Optional[str] = None
    color: Optional[str] = None
    target_days: Optional[int] = None
    target_sessions: Optional[int] = None
    is_active: Optional[bool] = None


class SkillResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    description: Optional[str]
    category: Optional[str]
    emoji: str
    color: str
    target_days: Optional[int]
    target_sessions: Optional[int]
    start_date: Optional[date]
    is_active: bool
    current_streak: int
    longest_streak: int
    total_sessions: int
    total_minutes: int
    created_at: datetime
    days_since_start: Optional[int] = None
    progress_pct: Optional[float] = None
    logged_today: bool = False


class SkillEntryCreate(BaseModel):
    skill_id: uuid.UUID
    date: Optional[date] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    quality: Optional[int] = None
    reference: Optional[str] = None


class SkillEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    skill_id: uuid.UUID
    date: date
    completed: bool
    duration_minutes: Optional[int]
    notes: Optional[str]
    quality: Optional[int]
    reference: Optional[str]
    created_at: datetime


class SkillSummary(BaseModel):
    total_skills: int
    active_skills: int
    total_sessions_today: int
    best_streak: int
    skills: List[SkillResponse]
