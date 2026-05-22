from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    dashboard,
    finances,
    savings,
    habits,
    time_tracking,
    health,
    learning,
    rewards,
    planning,
    analytics,
    skills,
    nutrition,
    diary,
    vault,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
api_router.include_router(finances.router, prefix="/finances", tags=["Finances"])
api_router.include_router(savings.router, prefix="/savings", tags=["Savings"])
api_router.include_router(habits.router, prefix="/habits", tags=["Habits"])
api_router.include_router(time_tracking.router, prefix="/time", tags=["Time Tracking"])
api_router.include_router(health.router, prefix="/health", tags=["Health & Wellness"])
api_router.include_router(learning.router, prefix="/learning", tags=["Learning"])
api_router.include_router(rewards.router, prefix="/rewards", tags=["Rewards"])
api_router.include_router(planning.router, prefix="/planning", tags=["Planning"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
api_router.include_router(skills.router, prefix="/skills", tags=["Skills"])
api_router.include_router(nutrition.router, prefix="/nutrition", tags=["Nutrition"])
api_router.include_router(diary.router, prefix="/diary", tags=["Diary"])
api_router.include_router(vault.router, prefix="/vault", tags=["Vault"])
