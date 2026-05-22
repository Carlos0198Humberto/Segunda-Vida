from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date
import uuid

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.finance import Account, Transaction, Category, Budget
from app.schemas.finance import (
    AccountCreate, AccountUpdate, AccountResponse,
    CategoryCreate, CategoryResponse,
    TransactionCreate, TransactionUpdate, TransactionResponse,
    BudgetCreate, BudgetResponse, FinancialSummary,
)

router = APIRouter()

# ── Accounts ─────────────────────────────────────────────────────────────────

@router.get("/accounts", response_model=List[AccountResponse])
def list_accounts(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Account).filter(Account.user_id == current_user.id, Account.is_active == True).all()


@router.post("/accounts", response_model=AccountResponse, status_code=201)
def create_account(payload: AccountCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = Account(user_id=current_user.id, **payload.model_dump())
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.put("/accounts/{account_id}", response_model=AccountResponse)
def update_account(account_id: uuid.UUID, payload: AccountUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(account, field, value)
    db.commit()
    db.refresh(account)
    return account


@router.delete("/accounts/{account_id}", status_code=204)
def delete_account(account_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    account.is_active = False
    db.commit()

# ── Categories ────────────────────────────────────────────────────────────────

_DEFAULT_CATEGORIES = [
    # Expense categories
    {"name": "Alimentos",               "icon": "restaurant",        "color": "#FF6B6B", "category_type": "expense"},
    {"name": "Comida rápida",           "icon": "fastfood",          "color": "#FF9F43", "category_type": "expense"},
    {"name": "Hogar",                   "icon": "home",              "color": "#4ECDC4", "category_type": "expense"},
    {"name": "Energía / Luz",           "icon": "bolt",              "color": "#FFEAA7", "category_type": "expense"},
    {"name": "Internet / Teléfono",     "icon": "wifi",              "color": "#74B9FF", "category_type": "expense"},
    {"name": "Universidad",             "icon": "school",            "color": "#A29BFE", "category_type": "expense"},
    {"name": "Medicamentos / Salud",    "icon": "medication",        "color": "#55EFC4", "category_type": "expense"},
    {"name": "Transporte",              "icon": "directions_car",    "color": "#FDCB6E", "category_type": "expense"},
    {"name": "Ropa",                    "icon": "checkroom",         "color": "#E17055", "category_type": "expense"},
    {"name": "Entretenimiento",         "icon": "movie",             "color": "#DDA0DD", "category_type": "expense"},
    {"name": "Gym / Deporte",           "icon": "fitness_center",    "color": "#00B894", "category_type": "expense"},
    {"name": "Otros gastos",            "icon": "more_horiz",        "color": "#B2BEC3", "category_type": "expense"},
    # Income categories
    {"name": "Salario",                 "icon": "work",              "color": "#00B894", "category_type": "income"},
    {"name": "Freelance",               "icon": "laptop",            "color": "#6B4EFF", "category_type": "income"},
    {"name": "Otros ingresos",          "icon": "attach_money",      "color": "#00D4AA", "category_type": "income"},
]

def _seed_default_categories(db: Session, user_id):
    existing = db.query(Category).filter(Category.user_id == user_id).count()
    if existing == 0:
        for cat in _DEFAULT_CATEGORIES:
            db.add(Category(user_id=user_id, **cat))
        db.commit()

@router.get("/categories", response_model=List[CategoryResponse])
def list_categories(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    _seed_default_categories(db, current_user.id)
    return db.query(Category).filter(Category.user_id == current_user.id).all()


@router.post("/categories", response_model=CategoryResponse, status_code=201)
def create_category(payload: CategoryCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    category = Category(user_id=current_user.id, **payload.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.delete("/categories/{category_id}", status_code=204)
def delete_category(category_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    cat = db.query(Category).filter(Category.id == category_id, Category.user_id == current_user.id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(cat)
    db.commit()

# ── Transactions ──────────────────────────────────────────────────────────────

@router.get("/transactions", response_model=List[TransactionResponse])
def list_transactions(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    transaction_type: Optional[str] = None,
    account_id: Optional[uuid.UUID] = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(Transaction).filter(Transaction.user_id == current_user.id)
    if start_date:
        q = q.filter(Transaction.date >= start_date)
    if end_date:
        q = q.filter(Transaction.date <= end_date)
    if transaction_type:
        q = q.filter(Transaction.transaction_type == transaction_type)
    if account_id:
        q = q.filter(Transaction.account_id == account_id)
    return q.order_by(Transaction.date.desc()).offset(offset).limit(limit).all()


@router.post("/transactions", response_model=TransactionResponse, status_code=201)
def create_transaction(payload: TransactionCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == payload.account_id, Account.user_id == current_user.id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    transaction = Transaction(user_id=current_user.id, **payload.model_dump())
    db.add(transaction)

    # Update account balance
    if payload.transaction_type == "income":
        account.current_balance = float(account.current_balance) + payload.amount
    elif payload.transaction_type == "expense":
        account.current_balance = float(account.current_balance) - payload.amount

    db.commit()
    db.refresh(transaction)
    return transaction


@router.put("/transactions/{transaction_id}", response_model=TransactionResponse)
def update_transaction(transaction_id: uuid.UUID, payload: TransactionUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id, Transaction.user_id == current_user.id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(transaction, field, value)
    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: uuid.UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id, Transaction.user_id == current_user.id).first()
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    account = db.query(Account).filter(Account.id == transaction.account_id).first()
    if account:
        if transaction.transaction_type == "income":
            account.current_balance = float(account.current_balance) - float(transaction.amount)
        elif transaction.transaction_type == "expense":
            account.current_balance = float(account.current_balance) + float(transaction.amount)
    db.delete(transaction)
    db.commit()

# ── Budgets ───────────────────────────────────────────────────────────────────

@router.get("/budgets", response_model=List[BudgetResponse])
def list_budgets(year: int, month: Optional[int] = None, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    q = db.query(Budget).filter(Budget.user_id == current_user.id, Budget.year == year)
    if month:
        q = q.filter(Budget.month == month)
    budgets = q.all()

    result = []
    for budget in budgets:
        spent = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == current_user.id,
            Transaction.category_id == budget.category_id,
            Transaction.transaction_type == "expense",
            Transaction.date >= date(year, month or 1, 1),
        ).scalar() or 0
        br = BudgetResponse.model_validate(budget)
        br.spent = float(spent)
        br.remaining = float(budget.amount) - float(spent)
        result.append(br)
    return result


@router.post("/budgets", response_model=BudgetResponse, status_code=201)
def create_budget(payload: BudgetCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    budget = Budget(user_id=current_user.id, **payload.model_dump())
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget
