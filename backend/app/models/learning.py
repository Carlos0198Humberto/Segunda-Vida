import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Date, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class LearningItem(Base):
    __tablename__ = "learning_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    item_type = Column(String(20), nullable=False)  # book, course, topic, video, podcast
    description = Column(Text, nullable=True)
    author = Column(String(150), nullable=True)
    url = Column(String(500), nullable=True)
    status = Column(String(20), default="planned")  # planned, in_progress, completed, paused
    progress_percentage = Column(Integer, default=0)
    total_pages = Column(Integer, nullable=True)
    current_page = Column(Integer, nullable=True)
    total_lessons = Column(Integer, nullable=True)
    current_lesson = Column(Integer, nullable=True)
    started_at = Column(Date, nullable=True)
    completed_at = Column(Date, nullable=True)
    rating = Column(Integer, nullable=True)  # 1-5
    notes = Column(Text, nullable=True)
    total_hours = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="learning_items")
    sessions = relationship("LearningSession", back_populates="learning_item", cascade="all, delete-orphan")


class LearningSession(Base):
    __tablename__ = "learning_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    learning_item_id = Column(UUID(as_uuid=True), ForeignKey("learning_items.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    duration_minutes = Column(Integer, nullable=False)
    date = Column(Date, nullable=False)
    pages_covered = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    learning_item = relationship("LearningItem", back_populates="sessions")
