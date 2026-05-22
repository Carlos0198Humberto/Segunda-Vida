from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime, time
import uuid


class HabitCreate(BaseModel):
    name: str
    description: Optional[str] = None
    habit_type: str  # positive, negative
    frequency: str = "daily"
    target_count: int = 1
    icon: str = "star"
    color: str = "#6B4EFF"
    reminder_time: Optional[time] = None


class HabitUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    reminder_time: Optional[time] = None
    is_active: Optional[bool] = None
    target_count: Optional[int] = None


class HabitResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    habit_type: str
    frequency: str
    target_count: int
    icon: str
    color: str
    reminder_time: Optional[time]
    is_active: bool
    current_streak: int
    longest_streak: int
    completed_today: bool = False
    completion_rate_7days: float = 0.0
    created_at: datetime

    model_config = {"from_attributes": True}


class HabitLogCreate(BaseModel):
    habit_id: uuid.UUID
    completed_at: date
    count: int = 1
    notes: Optional[str] = None


class HabitLogResponse(BaseModel):
    id: uuid.UUID
    habit_id: uuid.UUID
    completed_at: date
    count: int
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class HabitSummary(BaseModel):
    total_habits: int
    active_habits: int
    completed_today: int
    best_streak: int
    habits: List[HabitResponse]
