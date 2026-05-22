from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import uuid


class MealCreate(BaseModel):
    name: str
    meal_type: str  # breakfast, lunch, dinner, snack
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None
    cost: Optional[float] = None
    date: date
    is_healthy: Optional[bool] = None
    notes: Optional[str] = None


class MealResponse(BaseModel):
    id: uuid.UUID
    name: str
    meal_type: str
    calories: Optional[int]
    cost: Optional[float]
    date: date
    is_healthy: Optional[bool]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class HydrationCreate(BaseModel):
    amount_ml: int
    date: date


class HydrationResponse(BaseModel):
    id: uuid.UUID
    amount_ml: int
    logged_at: datetime
    date: date

    model_config = {"from_attributes": True}


class HydrationSummary(BaseModel):
    today_ml: int
    goal_ml: int
    percentage: float
    logs: List[HydrationResponse]


class SleepCreate(BaseModel):
    bed_time: datetime
    wake_time: datetime
    quality: Optional[int] = None  # 1-5
    notes: Optional[str] = None
    date: date


class SleepResponse(BaseModel):
    id: uuid.UUID
    bed_time: datetime
    wake_time: datetime
    duration_hours: Optional[float]
    quality: Optional[int]
    notes: Optional[str]
    date: date
    created_at: datetime

    model_config = {"from_attributes": True}


class MoodCreate(BaseModel):
    mood: int  # 1-5
    energy_level: Optional[int] = None
    notes: Optional[str] = None
    date: date


class MoodResponse(BaseModel):
    id: uuid.UUID
    mood: int
    energy_level: Optional[int]
    notes: Optional[str]
    logged_at: datetime
    date: date

    model_config = {"from_attributes": True}


class GymCreate(BaseModel):
    date: date
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None


class GymResponse(BaseModel):
    id: uuid.UUID
    date: date
    duration_minutes: Optional[int]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class HealthSummary(BaseModel):
    today_water_ml: int
    water_goal_ml: int
    water_percentage: float
    last_sleep_hours: Optional[float]
    sleep_goal_hours: float
    sleep_quality: Optional[int]
    today_calories: int
    today_meals: int
    current_mood: Optional[int]
    gym_days_this_month: int = 0
    health_score: int = 0
