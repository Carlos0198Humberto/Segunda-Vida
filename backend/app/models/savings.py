import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Date, Numeric, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class SavingsFund(Base):
    __tablename__ = "savings_funds"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    target_amount = Column(Numeric(12, 2), nullable=False)
    current_amount = Column(Numeric(12, 2), default=0)
    monthly_contribution = Column(Numeric(12, 2), default=0)
    priority = Column(Integer, default=3)  # 1=highest, 5=lowest
    color = Column(String(7), default="#6B4EFF")
    icon = Column(String(50), default="savings")
    deadline = Column(Date, nullable=True)
    is_achieved = Column(Boolean, default=False)
    achieved_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="savings_funds")
    contributions = relationship("SavingsContribution", back_populates="fund", cascade="all, delete-orphan")


class SavingsContribution(Base):
    __tablename__ = "savings_contributions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    fund_id = Column(UUID(as_uuid=True), ForeignKey("savings_funds.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    date = Column(Date, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    fund = relationship("SavingsFund", back_populates="contributions")
