from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime
import uuid


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

    @field_validator("password")
    @classmethod
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    preferred_currency: Optional[str] = None
    timezone: Optional[str] = None
    daily_water_goal_ml: Optional[str] = None
    daily_sleep_goal_hours: Optional[str] = None


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    preferred_currency: str
    timezone: str
    biometric_enabled: bool
    daily_water_goal_ml: str
    daily_sleep_goal_hours: str
    created_at: datetime

    model_config = {"from_attributes": True}


class SetPinRequest(BaseModel):
    pin: str

    @field_validator("pin")
    @classmethod
    def pin_length(cls, v):
        if not v.isdigit() or len(v) != 4:
            raise ValueError("PIN must be exactly 4 digits")
        return v


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    refresh_token: str
