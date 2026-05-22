from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import date, timedelta
import calendar

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.finance import Transaction
from app.models.habit import Habit, HabitLog
from app.models.time_entry import TimeEntry
from app.models.health import SleepLog, HydrationLog, GymSession
from app.models.savings import SavingsFund, SavingsContribution
from app.models.learning import LearningSession
from app.models.diary import DayEntry

router = APIRouter()


@router.get("/overview")
def analytics_overview(
    year: int = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not year:
        year = date.today().year

    monthly_data = []
    for month in range(1, 13):
        month_start = date(year, month, 1)
        last_day = calendar.monthrange(year, month)[1]
        month_end = date(year, month, last_day)

        income = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "income",
            Transaction.date >= month_start,
            Transaction.date <= month_end,
        ).scalar() or 0

        expenses = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "expense",
            Transaction.date >= month_start,
            Transaction.date <= month_end,
        ).scalar() or 0

        productive_min = db.query(func.sum(TimeEntry.duration_minutes)).filter(
            TimeEntry.user_id == current_user.id,
            TimeEntry.category.in_(["productive", "study", "learning"]),
            TimeEntry.date >= month_start,
            TimeEntry.date <= month_end,
        ).scalar() or 0

        habits_done = db.query(HabitLog).join(Habit).filter(
            Habit.user_id == current_user.id,
            HabitLog.completed_at >= month_start,
            HabitLog.completed_at <= month_end,
        ).count()

        learning_min = db.query(func.sum(LearningSession.duration_minutes)).filter(
            LearningSession.user_id == current_user.id,
            LearningSession.date >= month_start,
            LearningSession.date <= month_end,
        ).scalar() or 0

        monthly_data.append({
            "month": month,
            "month_name": calendar.month_abbr[month],
            "income": float(income),
            "expenses": float(expenses),
            "savings": float(income) - float(expenses),
            "productive_hours": round(productive_min / 60, 1),
            "habits_completed": habits_done,
            "learning_hours": round(learning_min / 60, 1),
        })

    return {
        "year": year,
        "monthly": monthly_data,
    }


@router.get("/habits/heatmap")
def habit_heatmap(
    days: int = Query(90, le=365),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    end = date.today()
    start = end - timedelta(days=days)

    habits = db.query(Habit).filter(Habit.user_id == current_user.id, Habit.is_active == True).all()
    habit_ids = [h.id for h in habits]

    logs = db.query(HabitLog).filter(
        HabitLog.habit_id.in_(habit_ids),
        HabitLog.completed_at >= start,
    ).all()

    day_counts: dict = {}
    for log in logs:
        k = log.completed_at.isoformat()
        day_counts[k] = day_counts.get(k, 0) + 1

    total_habits = len(habits)
    heatmap = []
    cursor = start
    while cursor <= end:
        k = cursor.isoformat()
        count = day_counts.get(k, 0)
        heatmap.append({
            "date": k,
            "count": count,
            "intensity": round(count / total_habits, 2) if total_habits > 0 else 0,
        })
        cursor += timedelta(days=1)

    return {"heatmap": heatmap, "total_habits": total_habits}


@router.get("/finance/trends")
def finance_trends(
    months: int = Query(6, le=12),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    data = []
    for i in range(months - 1, -1, -1):
        year = today.year
        month = today.month - i
        while month <= 0:
            month += 12
            year -= 1
        month_start = date(year, month, 1)
        last_day = calendar.monthrange(year, month)[1]
        month_end = date(year, month, last_day)

        income = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "income",
            Transaction.date >= month_start,
            Transaction.date <= month_end,
        ).scalar() or 0

        expenses = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "expense",
            Transaction.date >= month_start,
            Transaction.date <= month_end,
        ).scalar() or 0

        data.append({
            "label": f"{calendar.month_abbr[month]} {year}",
            "income": float(income),
            "expenses": float(expenses),
            "net": float(income) - float(expenses),
        })
    return {"trends": data}


@router.get("/sleep/trends")
def sleep_trends(
    days: int = Query(30, le=90),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    start = date.today() - timedelta(days=days)
    logs = db.query(SleepLog).filter(
        SleepLog.user_id == current_user.id,
        SleepLog.date >= start,
    ).order_by(SleepLog.date).all()

    return {
        "logs": [
            {
                "date": l.date.isoformat(),
                "hours": float(l.duration_hours) if l.duration_hours else 0,
                "quality": l.quality,
            }
            for l in logs
        ],
        "average_hours": round(
            sum(float(l.duration_hours or 0) for l in logs) / len(logs), 1
        ) if logs else 0,
    }


@router.get("/multi-year")
def multi_year(
    years: int = Query(5, le=10),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Year-by-year summary for the last N years."""
    current_year = date.today().year
    result = []
    for y in range(current_year - years + 1, current_year + 1):
        y_start = date(y, 1, 1)
        y_end = date(y, 12, 31)

        income = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "income",
            Transaction.date >= y_start,
            Transaction.date <= y_end,
        ).scalar() or 0

        expenses = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.transaction_type == "expense",
            Transaction.date >= y_start,
            Transaction.date <= y_end,
        ).scalar() or 0

        habits_completed = db.query(HabitLog).join(Habit).filter(
            Habit.user_id == current_user.id,
            HabitLog.completed_at >= y_start,
            HabitLog.completed_at <= y_end,
        ).count()

        productive_min = db.query(func.sum(TimeEntry.duration_minutes)).filter(
            TimeEntry.user_id == current_user.id,
            TimeEntry.category.in_(["productive", "study", "learning"]),
            TimeEntry.date >= y_start,
            TimeEntry.date <= y_end,
        ).scalar() or 0

        gym_sessions = db.query(GymSession).filter(
            GymSession.user_id == current_user.id,
            GymSession.date >= y_start,
            GymSession.date <= y_end,
        ).count()

        learning_min = db.query(func.sum(LearningSession.duration_minutes)).filter(
            LearningSession.user_id == current_user.id,
            LearningSession.date >= y_start,
            LearningSession.date <= y_end,
        ).scalar() or 0

        diary_count = db.query(DayEntry).filter(
            DayEntry.user_id == current_user.id,
            DayEntry.date >= y_start,
            DayEntry.date <= y_end,
        ).count()

        result.append({
            "year": y,
            "income": float(income),
            "expenses": float(expenses),
            "net_savings": float(income) - float(expenses),
            "habits_completed": habits_completed,
            "productive_hours": round(productive_min / 60, 1),
            "gym_sessions": gym_sessions,
            "learning_hours": round(learning_min / 60, 1),
            "diary_entries": diary_count,
        })

    return {"data": result}


@router.get("/weekly-review")
def weekly_review(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())  # Monday
    week_end = today

    habits = db.query(Habit).filter(Habit.user_id == current_user.id, Habit.is_active == True).all()
    total_possible = len(habits) * (today.weekday() + 1)
    habit_completions = db.query(HabitLog).join(Habit).filter(
        Habit.user_id == current_user.id,
        HabitLog.completed_at >= week_start,
        HabitLog.completed_at <= week_end,
    ).count()
    habit_pct = round(habit_completions / total_possible * 100) if total_possible > 0 else 0

    productive_min = db.query(func.sum(TimeEntry.duration_minutes)).filter(
        TimeEntry.user_id == current_user.id,
        TimeEntry.category.in_(["productive", "study", "learning"]),
        TimeEntry.date >= week_start,
        TimeEntry.date <= week_end,
    ).scalar() or 0

    income = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "income",
        Transaction.date >= week_start,
        Transaction.date <= week_end,
    ).scalar() or 0

    expenses = db.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.transaction_type == "expense",
        Transaction.date >= week_start,
        Transaction.date <= week_end,
    ).scalar() or 0

    gym_sessions = db.query(GymSession).filter(
        GymSession.user_id == current_user.id,
        GymSession.date >= week_start,
        GymSession.date <= week_end,
    ).count()

    sleep_logs = db.query(SleepLog).filter(
        SleepLog.user_id == current_user.id,
        SleepLog.date >= week_start,
        SleepLog.date <= week_end,
    ).all()
    avg_sleep = round(
        sum(float(l.duration_hours or 0) for l in sleep_logs) / len(sleep_logs), 1
    ) if sleep_logs else 0

    diary_entries = db.query(DayEntry).filter(
        DayEntry.user_id == current_user.id,
        DayEntry.date >= week_start,
        DayEntry.date <= week_end,
    ).count()

    score = min(100, round(
        habit_pct * 0.4 +
        min(productive_min / 60 / 20 * 100, 100) * 0.2 +
        min(gym_sessions / 3 * 100, 100) * 0.2 +
        (min(avg_sleep / 8 * 100, 100) if avg_sleep > 0 else 50) * 0.2
    ))

    return {
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "habit_pct": habit_pct,
        "habit_completions": habit_completions,
        "productive_hours": round(productive_min / 60, 1),
        "gym_sessions": gym_sessions,
        "avg_sleep": avg_sleep,
        "diary_entries": diary_entries,
        "income": float(income),
        "expenses": float(expenses),
        "net": float(income) - float(expenses),
        "score": score,
    }
