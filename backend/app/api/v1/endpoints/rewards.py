from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.reward import Reward, RewardClaim
from app.schemas.reward import RewardCreate, RewardResponse

router = APIRouter()


@router.get("", response_model=List[RewardResponse])
def list_rewards(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Reward).filter(Reward.user_id == current_user.id).order_by(Reward.is_unlocked.desc()).all()


@router.post("", response_model=RewardResponse, status_code=201)
def create_reward(payload: RewardCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    reward = Reward(user_id=current_user.id, **payload.model_dump())
    db.add(reward)
    db.commit()
    db.refresh(reward)
    return reward


@router.post("/{reward_id}/unlock", response_model=RewardResponse)
def unlock_reward(reward_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    reward = db.query(Reward).filter(Reward.id == reward_id, Reward.user_id == current_user.id).first()
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    reward.is_unlocked = True
    reward.unlocked_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(reward)
    return reward


@router.post("/{reward_id}/claim", response_model=RewardResponse)
def claim_reward(reward_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    reward = db.query(Reward).filter(Reward.id == reward_id, Reward.user_id == current_user.id).first()
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    if not reward.is_unlocked:
        raise HTTPException(status_code=400, detail="Reward not yet unlocked")
    if reward.is_claimed:
        raise HTTPException(status_code=400, detail="Reward already claimed")

    reward.is_claimed = True
    reward.claimed_at = datetime.now(timezone.utc)

    claim = RewardClaim(reward_id=reward_id)
    db.add(claim)
    db.commit()
    db.refresh(reward)
    return reward


@router.delete("/{reward_id}", status_code=204)
def delete_reward(reward_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    reward = db.query(Reward).filter(Reward.id == reward_id, Reward.user_id == current_user.id).first()
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    db.delete(reward)
    db.commit()
