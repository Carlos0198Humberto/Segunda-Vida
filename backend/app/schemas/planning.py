from pydantic import BaseModel
from typing import Optional, List
from datetime import date, time, datetime
import uuid


class WeeklyPlanCreate(BaseModel):
    week_start: date
    week_end: date
    main_goal: Optional[str] = None
    notes: Optional[str] = None
    energy_level: Optional[int] = None


class WeeklyPlanUpdate(BaseModel):
    main_goal: Optional[str] = None
    notes: Optional[str] = None
    energy_level: Optional[int] = None
    is_reviewed: Optional[bool] = None
    review_notes: Optional[str] = None


class DailyPlanItemCreate(BaseModel):
    weekly_plan_id: uuid.UUID
    date: date
    title: str
    description: Optional[str] = None
    time_slot: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    activity_type: str = "work"
    priority: int = 3
    color: str = "#6B4EFF"


class DailyPlanItemUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    time_slot: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    activity_type: Optional[str] = None
    is_completed: Optional[bool] = None
    priority: Optional[int] = None
    color: Optional[str] = None


class DailyPlanItemResponse(BaseModel):
    id: uuid.UUID
    weekly_plan_id: uuid.UUID
    date: date
    title: str
    description: Optional[str]
    time_slot: Optional[str]
    start_time: Optional[time]
    end_time: Optional[time]
    activity_type: str
    is_completed: bool
    priority: int
    color: str
    created_at: datetime

    model_config = {"from_attributes": True}


class WeeklyPlanResponse(BaseModel):
    id: uuid.UUID
    week_start: date
    week_end: date
    main_goal: Optional[str]
    notes: Optional[str]
    energy_level: Optional[int]
    is_reviewed: bool
    review_notes: Optional[str]
    items: List[DailyPlanItemResponse] = []
    completion_rate: float = 0.0
    created_at: datetime

    model_config = {"from_attributes": True}
