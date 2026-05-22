from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
import uuid


class AccountCreate(BaseModel):
    name: str
    account_type: str = "checking"
    current_balance: float = 0
    currency: str = "USD"
    is_primary: bool = False
    color: str = "#6B4EFF"
    icon: str = "account_balance_wallet"


class AccountUpdate(BaseModel):
    name: Optional[str] = None
    account_type: Optional[str] = None
    current_balance: Optional[float] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    is_primary: Optional[bool] = None


class AccountResponse(BaseModel):
    id: uuid.UUID
    name: str
    account_type: str
    current_balance: float
    currency: str
    is_primary: bool
    color: str
    icon: str
    created_at: datetime

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    name: str
    icon: str = "category"
    color: str = "#6B4EFF"
    category_type: str  # income, expense
    parent_id: Optional[uuid.UUID] = None


class CategoryResponse(BaseModel):
    id: uuid.UUID
    name: str
    icon: str
    color: str
    category_type: str
    parent_id: Optional[uuid.UUID]

    model_config = {"from_attributes": True}


class TransactionCreate(BaseModel):
    account_id: uuid.UUID
    category_id: Optional[uuid.UUID] = None
    amount: float
    transaction_type: str  # income, expense, transfer
    description: Optional[str] = None
    date: date
    is_recurring: bool = False
    recurring_frequency: Optional[str] = None
    notes: Optional[str] = None


class TransactionUpdate(BaseModel):
    category_id: Optional[uuid.UUID] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    date: Optional[date] = None
    notes: Optional[str] = None


class TransactionResponse(BaseModel):
    id: uuid.UUID
    account_id: uuid.UUID
    category_id: Optional[uuid.UUID]
    amount: float
    transaction_type: str
    description: Optional[str]
    date: date
    is_recurring: bool
    recurring_frequency: Optional[str]
    notes: Optional[str]
    created_at: datetime
    category: Optional[CategoryResponse] = None

    model_config = {"from_attributes": True}


class BudgetCreate(BaseModel):
    category_id: uuid.UUID
    amount: float
    period: str = "monthly"
    year: int
    month: Optional[int] = None


class BudgetResponse(BaseModel):
    id: uuid.UUID
    category_id: uuid.UUID
    amount: float
    period: str
    year: int
    month: Optional[int]
    spent: Optional[float] = None
    remaining: Optional[float] = None
    category: Optional[CategoryResponse] = None

    model_config = {"from_attributes": True}


class FinancialSummary(BaseModel):
    total_income: float
    total_expenses: float
    net_savings: float
    top_expense_categories: List[dict]
    monthly_trend: List[dict]
