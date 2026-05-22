from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import uuid


class TimeEntryCreate(BaseModel):
    category: str  # study, phone, productive, wasted, reading, learning, entertainment, exercise
    activity_name: Optional[str] = None
    duration_minutes: int
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    date: date
    notes: Optional[str] = None


class TimeEntryResponse(BaseModel):
    id: uuid.UUID
    category: str
    activity_name: Optional[str]
    duration_minutes: int
    start_time: Optional[datetime]
    end_time: Optional[datetime]
    date: date
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TimeReport(BaseModel):
    period: str
    productive_hours: float
    study_hours: float
    entertainment_hours: float
    phone_hours: float
    wasted_hours: float
    reading_hours: float
    learning_hours: float
    total_tracked_hours: float
    productivity_score: float
    breakdown: List[dict]
    daily_average: float
