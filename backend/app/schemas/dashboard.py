from pydantic import BaseModel
from typing import Optional, List
from datetime import date


class DashboardResponse(BaseModel):
    # Financial
    total_balance: float
    monthly_income: float
    monthly_expenses: float
    monthly_savings_rate: float

    # Savings
    total_saved: float
    total_savings_target: float
    savings_progress: float
    top_fund_name: Optional[str]
    top_fund_progress: Optional[float]

    # Habits
    habits_completed_today: int
    total_active_habits: int
    best_streak: int

    # Health
    today_water_ml: int
    water_goal_ml: int
    water_percentage: float
    last_sleep_hours: Optional[float]
    sleep_goal_hours: float

    # Productivity
    productive_hours_today: float
    study_hours_week: float

    # Learning
    active_learning_items: int
    learning_hours_week: float

    # Motivational
    motivational_message: str
    insights: List[str]

    # Quick stats
    current_date: date
    streak_days: int
