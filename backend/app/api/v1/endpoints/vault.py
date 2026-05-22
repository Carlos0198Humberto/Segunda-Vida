from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.security import hash_password, verify_password
from app.models.user import User
from app.models.vault import VaultProfile, VaultRecord
from app.schemas.vault import (
    VaultProfileCreate, VaultProfileResponse,
    VaultRecordCreate, VaultRecordResponse,
)

router = APIRouter()


# ── Profiles ──────────────────────────────────────────────────────────────────

@router.get("/profiles", response_model=List[VaultProfileResponse])
def list_profiles(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(VaultProfile).filter(VaultProfile.user_id == current_user.id).all()


@router.post("/profiles", response_model=VaultProfileResponse, status_code=201)
def create_profile(
    payload: VaultProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    pin_hash = hash_password(payload.pin) if payload.pin else None
    profile = VaultProfile(
        user_id=current_user.id,
        name=payload.name,
        birth_date=payload.birth_date,
        relationship_label=payload.relationship_label,
        avatar_emoji=payload.avatar_emoji or "👶",
        pin_hash=pin_hash,
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.post("/profiles/{profile_id}/verify-pin")
def verify_pin(
    profile_id: uuid.UUID,
    pin: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = db.query(VaultProfile).filter(
        VaultProfile.id == profile_id,
        VaultProfile.user_id == current_user.id,
    ).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    if profile.pin_hash and not verify_password(pin, profile.pin_hash):
        raise HTTPException(status_code=403, detail="Invalid PIN")
    return {"ok": True}


@router.delete("/profiles/{profile_id}", status_code=204)
def delete_profile(
    profile_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = db.query(VaultProfile).filter(
        VaultProfile.id == profile_id,
        VaultProfile.user_id == current_user.id,
    ).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    db.delete(profile)
    db.commit()


# ── Records ───────────────────────────────────────────────────────────────────

@router.get("/profiles/{profile_id}/records", response_model=List[VaultRecordResponse])
def list_records(
    profile_id: uuid.UUID,
    year: Optional[int] = None,
    event_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify ownership
    profile = db.query(VaultProfile).filter(
        VaultProfile.id == profile_id,
        VaultProfile.user_id == current_user.id,
    ).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    q = db.query(VaultRecord).filter(VaultRecord.profile_id == profile_id)
    if year:
        q = q.filter(func.extract('year', VaultRecord.event_date) == year)
    if event_type:
        q = q.filter(VaultRecord.event_type == event_type)
    return q.order_by(VaultRecord.event_date.desc()).all()


@router.post("/profiles/{profile_id}/records", response_model=VaultRecordResponse, status_code=201)
def create_record(
    profile_id: uuid.UUID,
    payload: VaultRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = db.query(VaultProfile).filter(
        VaultProfile.id == profile_id,
        VaultProfile.user_id == current_user.id,
    ).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    # Auto-compute age if birth_date available
    age_years = payload.age_years
    age_months = payload.age_months
    if profile.birth_date and (age_years is None or age_months is None):
        delta_days = (payload.event_date - profile.birth_date).days
        age_years = delta_days // 365
        remaining = delta_days % 365
        age_months = remaining // 30

    record = VaultRecord(
        profile_id=profile_id,
        user_id=current_user.id,
        event_date=payload.event_date,
        event_type=payload.event_type,
        title=payload.title,
        notes=payload.notes,
        emoji=payload.emoji,
        weight_kg=payload.weight_kg,
        height_cm=payload.height_cm,
        photo_url=payload.photo_url,
        age_years=age_years,
        age_months=age_months,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.delete("/profiles/{profile_id}/records/{record_id}", status_code=204)
def delete_record(
    profile_id: uuid.UUID,
    record_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = db.query(VaultRecord).filter(
        VaultRecord.id == record_id,
        VaultRecord.profile_id == profile_id,
        VaultRecord.user_id == current_user.id,
    ).first()
    if not record:
        raise HTTPException(status_code=404, detail="Record not found")
    db.delete(record)
    db.commit()


@router.get("/profiles/{profile_id}/timeline")
def get_timeline(
    profile_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns all records grouped by year for timeline view."""
    profile = db.query(VaultProfile).filter(
        VaultProfile.id == profile_id,
        VaultProfile.user_id == current_user.id,
    ).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    records = db.query(VaultRecord).filter(
        VaultRecord.profile_id == profile_id
    ).order_by(VaultRecord.event_date).all()

    grouped: dict = {}
    for r in records:
        year = str(r.event_date.year)
        if year not in grouped:
            grouped[year] = []
        grouped[year].append({
            "id": str(r.id),
            "event_date": r.event_date.isoformat(),
            "event_type": r.event_type,
            "title": r.title,
            "notes": r.notes,
            "emoji": r.emoji,
            "weight_kg": float(r.weight_kg) if r.weight_kg else None,
            "height_cm": float(r.height_cm) if r.height_cm else None,
            "photo_url": r.photo_url,
            "age_years": r.age_years,
            "age_months": r.age_months,
        })

    return {
        "profile": {
            "id": str(profile.id),
            "name": profile.name,
            "birth_date": profile.birth_date.isoformat() if profile.birth_date else None,
            "avatar_emoji": profile.avatar_emoji,
        },
        "timeline": grouped,
        "total_records": len(records),
    }
