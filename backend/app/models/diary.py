import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Date, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy import ForeignKey
from app.core.database import Base


class DayEntry(Base):
    __tablename__ = "day_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    content = Column(String(300), nullable=False)
    category = Column(String(30), nullable=False, default="personal")
    # entertainment, social, sport, culture, rest, personal, food, work, other
    emoji = Column(String(10), nullable=True)
    source = Column(String(20), nullable=False, default="manual")
    # manual, habit, gym, sleep, water, finance
    source_ref_id = Column(String(100), nullable=True)
    date = Column(Date, nullable=False, index=True)
    logged_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="day_entries")
