import uuid
from datetime import datetime, date, timezone
from sqlalchemy import Column, String, Float, Integer, DateTime, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.models.base import Base


class BodyMetric(Base):
    __tablename__ = "body_metrics"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, default=date.today, nullable=False)
    weight_kg = Column(Float)
    height_cm = Column(Float)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class FoodLog(Base):
    __tablename__ = "food_logs_nutrition"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, default=date.today, nullable=False)
    food_name = Column(String(100), nullable=False)
    category = Column(String(50))  # carbs, protein, legumes, veggies, fruits, dairy, treats
    servings = Column(Float, default=1.0)
    meal_time = Column(String(20))  # breakfast, lunch, dinner, snack
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
