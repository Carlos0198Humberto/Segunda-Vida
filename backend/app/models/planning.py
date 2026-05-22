import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Date, Integer, ForeignKey, Text, Time
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
from app.core.database import Base


class WeeklyPlan(Base):
    __tablename__ = "weekly_plans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    week_start = Column(Date, nullable=False)  # Monday
    week_end = Column(Date, nullable=False)    # Sunday
    main_goal = Column(String(300), nullable=True)
    notes = Column(Text, nullable=True)
    energy_level = Column(Integer, nullable=True)  # 1-5
    is_reviewed = Column(Boolean, default=False)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    review_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="weekly_plans")
    items = relationship("DailyPlanItem", back_populates="weekly_plan", cascade="all, delete-orphan")


class DailyPlanItem(Base):
    __tablename__ = "daily_plan_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    weekly_plan_id = Column(UUID(as_uuid=True), ForeignKey("weekly_plans.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    time_slot = Column(String(20), nullable=True)  # morning, afternoon, evening, night
    start_time = Column(Time, nullable=True)
    end_time = Column(Time, nullable=True)
    # study, work, exercise, rest, learning, routine, social, creative, admin, free
    activity_type = Column(String(30), default="work")
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    priority = Column(Integer, default=3)  # 1=highest, 5=lowest
    color = Column(String(7), default="#6B4EFF")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    weekly_plan = relationship("WeeklyPlan", back_populates="items")
