from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional
import uuid


class VaultProfileCreate(BaseModel):
    name: str
    birth_date: Optional[date] = None
    relationship_label: Optional[str] = "sobrino"
    avatar_emoji: Optional[str] = "👶"
    pin: Optional[str] = None


class VaultProfileResponse(BaseModel):
    id: uuid.UUID
    name: str
    birth_date: Optional[date]
    relationship_label: Optional[str]
    avatar_emoji: str
    created_at: datetime

    class Config:
        from_attributes = True


class VaultRecordCreate(BaseModel):
    event_date: date
    event_type: str = "milestone"
    title: str
    notes: Optional[str] = None
    emoji: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    photo_url: Optional[str] = None
    age_years: Optional[int] = None
    age_months: Optional[int] = None


class VaultRecordResponse(BaseModel):
    id: uuid.UUID
    profile_id: uuid.UUID
    event_date: date
    event_type: str
    title: str
    notes: Optional[str]
    emoji: Optional[str]
    weight_kg: Optional[float]
    height_cm: Optional[float]
    photo_url: Optional[str]
    age_years: Optional[int]
    age_months: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True
