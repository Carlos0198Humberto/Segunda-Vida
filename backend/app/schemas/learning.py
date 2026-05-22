from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import uuid


class LearningItemCreate(BaseModel):
    title: str
    item_type: str  # book, course, topic, video, podcast
    description: Optional[str] = None
    author: Optional[str] = None
    url: Optional[str] = None
    total_pages: Optional[int] = None
    total_lessons: Optional[int] = None
    notes: Optional[str] = None


class LearningItemUpdate(BaseModel):
    title: Optional[str] = None
    status: Optional[str] = None
    progress_percentage: Optional[int] = None
    current_page: Optional[int] = None
    current_lesson: Optional[int] = None
    rating: Optional[int] = None
    notes: Optional[str] = None


class LearningItemResponse(BaseModel):
    id: uuid.UUID
    title: str
    item_type: str
    description: Optional[str]
    author: Optional[str]
    status: str
    progress_percentage: int
    total_pages: Optional[int]
    current_page: Optional[int]
    total_lessons: Optional[int]
    current_lesson: Optional[int]
    started_at: Optional[date]
    completed_at: Optional[date]
    rating: Optional[int]
    notes: Optional[str]
    total_hours: int
    created_at: datetime

    model_config = {"from_attributes": True}


class LearningSessionCreate(BaseModel):
    learning_item_id: uuid.UUID
    duration_minutes: int
    date: date
    pages_covered: Optional[int] = None
    notes: Optional[str] = None


class LearningSessionResponse(BaseModel):
    id: uuid.UUID
    learning_item_id: uuid.UUID
    duration_minutes: int
    date: date
    pages_covered: Optional[int]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class LearningSummary(BaseModel):
    total_items: int
    completed_items: int
    in_progress_items: int
    total_hours: float
    weekly_hours: float
    current_streak_days: int
