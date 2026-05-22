import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Date, Numeric, Integer, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class VaultProfile(Base):
    """A protected profile (nephew or any private person being tracked)."""
    __tablename__ = "vault_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    birth_date = Column(Date, nullable=True)
    relationship_label = Column(String(50), nullable=True)  # sobrino, hijo, amigo...
    avatar_emoji = Column(String(10), default="👶")
    pin_hash = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="vault_profiles")
    records = relationship("VaultRecord", back_populates="profile", cascade="all, delete-orphan")


class VaultRecord(Base):
    """A life record entry for a vault profile."""
    __tablename__ = "vault_records"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("vault_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Event info
    event_date = Column(Date, nullable=False, index=True)
    event_type = Column(String(30), nullable=False, default="milestone")
    # milestone, health, measure, memory, school, first_time, trip, achievement, other
    title = Column(String(200), nullable=False)
    notes = Column(Text, nullable=True)
    emoji = Column(String(10), nullable=True)

    # Physical measurements (optional)
    weight_kg = Column(Numeric(5, 2), nullable=True)
    height_cm = Column(Numeric(5, 1), nullable=True)

    # Media (stored as comma-separated base64 or URLs)
    photo_url = Column(Text, nullable=True)

    # Age at event (computed or stored)
    age_years = Column(Integer, nullable=True)
    age_months = Column(Integer, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    profile = relationship("VaultProfile", back_populates="records")
