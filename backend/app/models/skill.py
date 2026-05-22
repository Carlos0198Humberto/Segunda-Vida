import uuid
from datetime import datetime, date, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Date, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base


class Skill(Base):
    __tablename__ = "skills"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    name = Column(String(100), nullable=False)
    description = Column(Text)
    category = Column(String(50))  # language, fitness, spiritual, tech, communication, reading
    emoji = Column(String(10), default="⭐")
    color = Column(String(7), default="#6B4EFF")

    target_days = Column(Integer)
    target_sessions = Column(Integer)

    start_date = Column(Date, default=date.today)
    is_active = Column(Boolean, default=True)

    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    total_sessions = Column(Integer, default=0)
    total_minutes = Column(Integer, default=0)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    entries = relationship("SkillEntry", back_populates="skill", cascade="all, delete-orphan")


class SkillEntry(Base):
    __tablename__ = "skill_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    skill_id = Column(UUID(as_uuid=True), ForeignKey("skills.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    date = Column(Date, nullable=False, default=date.today)
    completed = Column(Boolean, default=True)
    duration_minutes = Column(Integer)
    notes = Column(Text)
    quality = Column(Integer)  # 1-5
    reference = Column(String(200))  # e.g. "Genesis 1-3", "Chapter 5 vocabulary"

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    skill = relationship("Skill", back_populates="entries")
