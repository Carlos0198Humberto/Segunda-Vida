from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date
import uuid
from math import ceil

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.savings import SavingsFund, SavingsContribution
from app.schemas.savings import (
    SavingsFundCreate, SavingsFundUpdate, SavingsFundResponse,
    ContributionCreate, ContributionResponse, SavingsSummary,
)

router = APIRouter()


def _build_fund_response(fund: SavingsFund) -> SavingsFundResponse:
    progress = (float(fund.current_amount) / float(fund.target_amount) * 100) if float(fund.target_amount) > 0 else 0
    months_to_goal = None
    if float(fund.monthly_contribution) > 0 and not fund.is_achieved:
        remaining = float(fund.target_amount) - float(fund.current_amount)
        if remaining > 0:
            months_to_goal = ceil(remaining / float(fund.monthly_contribution))
    return SavingsFundResponse(
        id=fund.id,
        name=fund.name,
        description=fund.description,
        target_amount=float(fund.target_amount),
        current_amount=float(fund.current_amount),
        monthly_contribution=float(fund.monthly_contribution),
        priority=fund.priority,
        color=fund.color,
        icon=fund.icon,
        deadline=fund.deadline,
        is_achieved=fund.is_achieved,
        notes=fund.notes,
        progress_percentage=round(progress, 1),
        months_to_goal=months_to_goal,
        created_at=fund.created_at,
    )


@router.get("", response_model=SavingsSummary)
def get_savings_summary(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    funds = db.query(SavingsFund).filter(SavingsFund.user_id == current_user.id).order_by(SavingsFund.priority).all()
    total_saved = sum(float(f.current_amount) for f in funds)
    total_target = sum(float(f.target_amount) for f in funds)
    active = [f for f in funds if not f.is_achieved]
    achieved = [f for f in funds if f.is_achieved]

    return SavingsSummary(
        total_saved=total_saved,
        total_target=total_target,
        overall_progress=round(total_saved / total_target * 100, 1) if total_target > 0 else 0,
        active_funds=len(active),
        achieved_funds=len(achieved),
        funds=[_build_fund_response(f) for f in funds],
    )


@router.post("", response_model=SavingsFundResponse, status_code=201)
def create_fund(payload: SavingsFundCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fund = SavingsFund(user_id=current_user.id, **payload.model_dump())
    db.add(fund)
    db.commit()
    db.refresh(fund)
    return _build_fund_response(fund)


@router.put("/{fund_id}", response_model=SavingsFundResponse)
def update_fund(fund_id: uuid.UUID, payload: SavingsFundUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fund = db.query(SavingsFund).filter(SavingsFund.id == fund_id, SavingsFund.user_id == current_user.id).first()
    if not fund:
        raise HTTPException(status_code=404, detail="Savings fund not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(fund, field, value)
    db.commit()
    db.refresh(fund)
    return _build_fund_response(fund)


@router.delete("/{fund_id}", status_code=204)
def delete_fund(fund_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fund = db.query(SavingsFund).filter(SavingsFund.id == fund_id, SavingsFund.user_id == current_user.id).first()
    if not fund:
        raise HTTPException(status_code=404, detail="Savings fund not found")
    db.delete(fund)
    db.commit()


@router.post("/{fund_id}/contribute", response_model=ContributionResponse, status_code=201)
def add_contribution(fund_id: uuid.UUID, payload: ContributionCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fund = db.query(SavingsFund).filter(SavingsFund.id == fund_id, SavingsFund.user_id == current_user.id).first()
    if not fund:
        raise HTTPException(status_code=404, detail="Savings fund not found")

    contribution = SavingsContribution(fund_id=fund_id, amount=payload.amount, date=payload.date, notes=payload.notes)
    db.add(contribution)

    fund.current_amount = float(fund.current_amount) + payload.amount
    if float(fund.current_amount) >= float(fund.target_amount):
        from datetime import datetime, timezone
        fund.is_achieved = True
        fund.achieved_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(contribution)
    return contribution


@router.get("/{fund_id}/contributions", response_model=List[ContributionResponse])
def list_contributions(fund_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fund = db.query(SavingsFund).filter(SavingsFund.id == fund_id, SavingsFund.user_id == current_user.id).first()
    if not fund:
        raise HTTPException(status_code=404, detail="Savings fund not found")
    return db.query(SavingsContribution).filter(SavingsContribution.fund_id == fund_id).order_by(SavingsContribution.date.desc()).all()
