import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.core.database import Base


class Reward(Base):
    __tablename__ = "rewards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String(50), default="emoji_events")
    color = Column(String(7), default="#FFD700")
    points_required = Column(Integer, default=100)
    # condition_type: savings_goal, habit_streak, productivity_hours, manual
    condition_type = Column(String(30), nullable=False, default="manual")
    condition_value = Column(JSONB, nullable=True)  # {"fund_id": "...", "target": 1000}
    is_unlocked = Column(Boolean, default=False)
    unlocked_at = Column(DateTime(timezone=True), nullable=True)
    is_claimed = Column(Boolean, default=False)
    claimed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="rewards")
    claims = relationship("RewardClaim", back_populates="reward", cascade="all, delete-orphan")


class RewardClaim(Base):
    __tablename__ = "reward_claims"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    reward_id = Column(UUID(as_uuid=True), ForeignKey("rewards.id", ondelete="CASCADE"), nullable=False, index=True)
    claimed_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    notes = Column(Text, nullable=True)

    reward = relationship("Reward", back_populates="claims")
