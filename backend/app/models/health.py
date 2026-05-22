import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Date, Numeric, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class MealLog(Base):
    __tablename__ = "meal_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    meal_type = Column(String(20), nullable=False)  # breakfast, lunch, dinner, snack
    calories = Column(Integer, nullable=True)
    protein_g = Column(Numeric(6, 1), nullable=True)
    carbs_g = Column(Numeric(6, 1), nullable=True)
    fat_g = Column(Numeric(6, 1), nullable=True)
    cost = Column(Numeric(10, 2), nullable=True)
    date = Column(Date, nullable=False, index=True)
    is_healthy = Column(Boolean, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="meal_logs")


class HydrationLog(Base):
    __tablename__ = "hydration_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount_ml = Column(Integer, nullable=False)
    logged_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    date = Column(Date, nullable=False, index=True)

    user = relationship("User", back_populates="hydration_logs")


class SleepLog(Base):
    __tablename__ = "sleep_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    bed_time = Column(DateTime(timezone=True), nullable=False)
    wake_time = Column(DateTime(timezone=True), nullable=False)
    duration_hours = Column(Numeric(4, 2), nullable=True)
    quality = Column(Integer, nullable=True)  # 1-5
    notes = Column(Text, nullable=True)
    date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="sleep_logs")


class MoodLog(Base):
    __tablename__ = "mood_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    mood = Column(Integer, nullable=False)  # 1-5
    energy_level = Column(Integer, nullable=True)  # 1-5
    notes = Column(Text, nullable=True)
    logged_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    date = Column(Date, nullable=False, index=True)

    user = relationship("User", back_populates="mood_logs")


class GymSession(Base):
    __tablename__ = "gym_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    duration_minutes = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="gym_sessions")
