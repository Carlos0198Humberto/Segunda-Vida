from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional
import uuid


class DayEntryCreate(BaseModel):
    content: str
    category: str = "personal"
    emoji: Optional[str] = None
    date: Optional[date] = None


class DayEntryResponse(BaseModel):
    id: uuid.UUID
    content: str
    category: str
    emoji: Optional[str]
    source: str
    date: date
    logged_at: datetime

    class Config:
        from_attributes = True
