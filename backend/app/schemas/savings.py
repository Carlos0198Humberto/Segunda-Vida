from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import uuid


class SavingsFundCreate(BaseModel):
    name: str
    description: Optional[str] = None
    target_amount: float
    current_amount: float = 0
    monthly_contribution: float = 0
    priority: int = 3
    color: str = "#6B4EFF"
    icon: str = "savings"
    deadline: Optional[date] = None
    notes: Optional[str] = None


class SavingsFundUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[float] = None
    monthly_contribution: Optional[float] = None
    priority: Optional[int] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    deadline: Optional[date] = None
    notes: Optional[str] = None


class SavingsFundResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    target_amount: float
    current_amount: float
    monthly_contribution: float
    priority: int
    color: str
    icon: str
    deadline: Optional[date]
    is_achieved: bool
    notes: Optional[str]
    progress_percentage: float
    months_to_goal: Optional[int]
    created_at: datetime

    model_config = {"from_attributes": True}


class ContributionCreate(BaseModel):
    fund_id: uuid.UUID
    amount: float
    date: date
    notes: Optional[str] = None


class ContributionResponse(BaseModel):
    id: uuid.UUID
    fund_id: uuid.UUID
    amount: float
    date: date
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class SavingsSummary(BaseModel):
    total_saved: float
    total_target: float
    overall_progress: float
    active_funds: int
    achieved_funds: int
    funds: List[SavingsFundResponse]
