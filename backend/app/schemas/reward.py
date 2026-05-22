from pydantic import BaseModel
from typing import Optional, Any, Dict
from datetime import datetime
import uuid


class RewardCreate(BaseModel):
    name: str
    description: Optional[str] = None
    icon: str = "emoji_events"
    color: str = "#FFD700"
    points_required: int = 100
    condition_type: str = "manual"  # savings_goal, habit_streak, productivity_hours, manual
    condition_value: Optional[Dict[str, Any]] = None


class RewardResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    icon: str
    color: str
    points_required: int
    condition_type: str
    condition_value: Optional[dict]
    is_unlocked: bool
    unlocked_at: Optional[datetime]
    is_claimed: bool
    claimed_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}
