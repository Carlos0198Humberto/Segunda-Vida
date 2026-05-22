from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import date, datetime, timedelta, timezone
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.finance import Account, Transaction
from app.models.savings import SavingsFund
from app.models.habit import Habit, HabitLog
from app.models.health import HydrationLog, SleepLog
from app.models.time_entry import TimeEntry
from app.models.learning import LearningItem, LearningSession
from app.schemas.dashboard import DashboardResponse
from app.services.motivation_service import get_motivational_message, get_insights

router = APIRouter()


@router.get("", response_model=DashboardResponse)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    month_start = today.replace(day=1)
    week_start = today - timedelta(days=today.weekday())

    # Financial summary — compute balance from actual transactions (avoids stale stored values)
    all_income = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income",
    ).scalar() or 0.0

    all_expenses = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense",
    ).scalar() or 0.0

    total_balance = float(all_income) - float(all_expenses)

    monthly_income = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income",
        Transaction.date >= month_start,
    ).scalar() or 0.0

    monthly_expenses = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense",
        Transaction.date >= month_start,
    ).scalar() or 0.0

    savings_rate = ((monthly_income - monthly_expenses) / monthly_income * 100) if monthly_income > 0 else 0

    # Savings
    funds = db.query(SavingsFund).filter(
        SavingsFund.user_id == current_user.id, SavingsFund.is_achieved == False
    ).all()
    total_saved = sum(float(f.current_amount) for f in funds)
    total_target = sum(float(f.target_amount) for f in funds)
    savings_progress = (total_saved / total_target * 100) if total_target > 0 else 0

    top_fund = max(funds, key=lambda f: float(f.current_amount) / float(f.target_amount) if float(f.target_amount) > 0 else 0, default=None)

    # Habits
    active_habits = db.query(Habit).filter(
        Habit.user_id == current_user.id, Habit.is_active == True
    ).all()
    completed_today_logs = db.query(HabitLog).filter(
        HabitLog.habit_id.in_([h.id for h in active_habits]),
        HabitLog.completed_at == today,
    ).all()
    completed_today_ids = {log.habit_id for log in completed_today_logs}
    habits_done_today = len(completed_today_ids)
    best_streak = max((h.current_streak for h in active_habits), default=0)

    # Hydration
    water_today = db.query(func.sum(HydrationLog.amount_ml)).filter(
        HydrationLog.user_id == current_user.id,
        HydrationLog.date == today,
    ).scalar() or 0
    water_goal = int(current_user.daily_water_goal_ml)

    # Sleep
    last_sleep = db.query(SleepLog).filter(
        SleepLog.user_id == current_user.id,
    ).order_by(SleepLog.date.desc()).first()
    sleep_hours = float(last_sleep.duration_hours) if last_sleep and last_sleep.duration_hours else None

    # Time tracking
    productive_today = db.query(func.sum(TimeEntry.duration_minutes)).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.category.in_(["productive", "study", "learning"]),
        TimeEntry.date == today,
    ).scalar() or 0

    study_week = db.query(func.sum(TimeEntry.duration_minutes)).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.category == "study",
        TimeEntry.date >= week_start,
    ).scalar() or 0

    # Learning
    active_items = db.query(LearningItem).filter(
        LearningItem.user_id == current_user.id,
        LearningItem.status == "in_progress",
    ).count()

    learning_week_minutes = db.query(func.sum(LearningSession.duration_minutes)).filter(
        LearningSession.user_id == current_user.id,
        LearningSession.date >= week_start,
    ).scalar() or 0

    # Build context for insights
    context = {
        "water_percentage": (water_today / water_goal * 100) if water_goal > 0 else 0,
        "sleep_hours": sleep_hours,
        "sleep_goal": float(current_user.daily_sleep_goal_hours),
        "habits_done": habits_done_today,
        "total_habits": len(active_habits),
        "savings_progress": savings_progress,
        "top_fund": top_fund,
        "productive_hours": productive_today / 60,
        "study_hours_week": study_week / 60,
    }

    return DashboardResponse(
        total_balance=total_balance,
        monthly_income=float(monthly_income),
        monthly_expenses=float(monthly_expenses),
        monthly_savings_rate=round(savings_rate, 1),
        total_saved=total_saved,
        total_savings_target=total_target,
        savings_progress=round(savings_progress, 1),
        top_fund_name=top_fund.name if top_fund else None,
        top_fund_progress=round(float(top_fund.current_amount) / float(top_fund.target_amount) * 100, 1) if top_fund and float(top_fund.target_amount) > 0 else None,
        habits_completed_today=habits_done_today,
        total_active_habits=len(active_habits),
        best_streak=best_streak,
        today_water_ml=water_today,
        water_goal_ml=water_goal,
        water_percentage=round((water_today / water_goal * 100) if water_goal > 0 else 0, 1),
        last_sleep_hours=sleep_hours,
        sleep_goal_hours=float(current_user.daily_sleep_goal_hours),
        productive_hours_today=round(productive_today / 60, 1),
        study_hours_week=round(study_week / 60, 1),
        active_learning_items=active_items,
        learning_hours_week=round(learning_week_minutes / 60, 1),
        motivational_message=get_motivational_message(context),
        insights=get_insights(context),
        current_date=today,
        streak_days=best_streak,
    )
