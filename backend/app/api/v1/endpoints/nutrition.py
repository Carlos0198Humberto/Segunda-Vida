from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import date, timedelta
from pydantic import BaseModel, ConfigDict
import uuid
import calendar as cal_mod

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.nutrition import BodyMetric, FoodLog

router = APIRouter()

# ── Nutritionist-validated daily limits (plate method) ─────────────────────
DAILY_LIMITS = {
    'carbs':   {'label': 'Carbohidratos', 'unit': 'porciones', 'daily': 3, 'goal_min': 2},
    'protein': {'label': 'Proteínas',     'unit': 'porciones', 'daily': 2, 'goal_min': 2},
    'legumes': {'label': 'Legumbres',     'unit': 'tazas',     'daily': 1, 'goal_min': 1},
    'veggies': {'label': 'Verduras',      'unit': 'porciones', 'daily': 3, 'goal_min': 2},
    'fruits':  {'label': 'Frutas',        'unit': 'unidades',  'daily': 3, 'goal_min': 2},
    'dairy':   {'label': 'Lácteos',       'unit': 'porciones', 'daily': 2, 'goal_min': 1},
    'treats':  {'label': 'Antojos',       'unit': 'porciones', 'daily': 1, 'goal_min': 0},
}

WEEKLY_LIMITS = {
    'huevos':    {'category': 'protein', 'weekly': 7,  'label': 'Huevos duros'},
    'chocolate': {'category': 'treats',  'weekly': 2,  'label': 'Chocolate'},
    'pizza':     {'category': 'treats',  'weekly': 1,  'label': 'Pizza'},
    'churros':   {'category': 'treats',  'weekly': 1,  'label': 'Churros'},
}

# Calories per 1 serving — nutritionist estimates
FOOD_CALORIES = {
    'Arroz':      {'kcal': 200, 'carbs_g': 45, 'protein_g': 4,  'fat_g': 0},
    'Tortillas':  {'kcal': 150, 'carbs_g': 30, 'protein_g': 3,  'fat_g': 2},
    'Pan':        {'kcal': 160, 'carbs_g': 30, 'protein_g': 5,  'fat_g': 2},
    'Pasta':      {'kcal': 220, 'carbs_g': 44, 'protein_g': 8,  'fat_g': 1},
    'Carne':      {'kcal': 250, 'carbs_g': 0,  'protein_g': 26, 'fat_g': 15},
    'Pollo':      {'kcal': 200, 'carbs_g': 0,  'protein_g': 30, 'fat_g': 8},
    'Huevo duro': {'kcal': 78,  'carbs_g': 1,  'protein_g': 6,  'fat_g': 5},
    'Frijoles':   {'kcal': 120, 'carbs_g': 20, 'protein_g': 8,  'fat_g': 1},
    'Lentejas':   {'kcal': 115, 'carbs_g': 20, 'protein_g': 9,  'fat_g': 0},
    'Ensalada':   {'kcal': 40,  'carbs_g': 7,  'protein_g': 2,  'fat_g': 1},
    'Verduras':   {'kcal': 50,  'carbs_g': 10, 'protein_g': 2,  'fat_g': 0},
    'Fruta':      {'kcal': 80,  'carbs_g': 20, 'protein_g': 1,  'fat_g': 0},
    'Plátano':    {'kcal': 90,  'carbs_g': 23, 'protein_g': 1,  'fat_g': 0},
    'Leche':      {'kcal': 120, 'carbs_g': 12, 'protein_g': 8,  'fat_g': 5},
    'Queso':      {'kcal': 113, 'carbs_g': 1,  'protein_g': 7,  'fat_g': 9},
    'Chocolate':  {'kcal': 170, 'carbs_g': 20, 'protein_g': 2,  'fat_g': 10},
    'Pizza':      {'kcal': 285, 'carbs_g': 36, 'protein_g': 12, 'fat_g': 10},
    'Churros':    {'kcal': 200, 'carbs_g': 30, 'protein_g': 2,  'fat_g': 8},
}

# Fallback kcal by category when food not in dict
CATEGORY_KCAL = {
    'carbs': 200, 'protein': 220, 'legumes': 120,
    'veggies': 50, 'fruits': 80, 'dairy': 130, 'treats': 250,
}

PRESET_FOODS = [
    {'name': 'Arroz',      'category': 'carbs',   'emoji': '🍚', 'kcal': 200},
    {'name': 'Tortillas',  'category': 'carbs',   'emoji': '🫓', 'kcal': 150},
    {'name': 'Pan',        'category': 'carbs',   'emoji': '🍞', 'kcal': 160},
    {'name': 'Pasta',      'category': 'carbs',   'emoji': '🍝', 'kcal': 220},
    {'name': 'Carne',      'category': 'protein', 'emoji': '🥩', 'kcal': 250},
    {'name': 'Pollo',      'category': 'protein', 'emoji': '🍗', 'kcal': 200},
    {'name': 'Huevo duro', 'category': 'protein', 'emoji': '🥚', 'kcal': 78},
    {'name': 'Frijoles',   'category': 'legumes', 'emoji': '🫘', 'kcal': 120},
    {'name': 'Lentejas',   'category': 'legumes', 'emoji': '🍲', 'kcal': 115},
    {'name': 'Ensalada',   'category': 'veggies', 'emoji': '🥗', 'kcal': 40},
    {'name': 'Verduras',   'category': 'veggies', 'emoji': '🥦', 'kcal': 50},
    {'name': 'Fruta',      'category': 'fruits',  'emoji': '🍎', 'kcal': 80},
    {'name': 'Plátano',    'category': 'fruits',  'emoji': '🍌', 'kcal': 90},
    {'name': 'Leche',      'category': 'dairy',   'emoji': '🥛', 'kcal': 120},
    {'name': 'Queso',      'category': 'dairy',   'emoji': '🧀', 'kcal': 113},
    {'name': 'Chocolate',  'category': 'treats',  'emoji': '🍫', 'kcal': 170},
    {'name': 'Pizza',      'category': 'treats',  'emoji': '🍕', 'kcal': 285},
    {'name': 'Churros',    'category': 'treats',  'emoji': '🍩', 'kcal': 200},
]

DAY_NAMES = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']

# ── Schemas ────────────────────────────────────────────────────────────────

class BodyMetricIn(BaseModel):
    date: Optional[date] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None

class BodyMetricOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    date: date
    weight_kg: Optional[float]
    height_cm: Optional[float]

class FoodLogIn(BaseModel):
    food_name: str
    category: str
    servings: float = 1.0
    meal_time: Optional[str] = None
    date: Optional[date] = None

class FoodLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    food_name: str
    category: str
    servings: float
    meal_time: Optional[str]
    date: date

# ── Helpers ────────────────────────────────────────────────────────────────

def _kcal_for_entry(food_name: str, category: str, servings: float) -> int:
    info = FOOD_CALORIES.get(food_name)
    base = info['kcal'] if info else CATEGORY_KCAL.get(category, 150)
    return round(base * servings)

def _day_summary(entries: list, week_entries: list) -> dict:
    cat_totals: dict = {}
    total_kcal = 0
    total_protein_g = 0
    total_carbs_g = 0
    total_fat_g = 0

    for e in entries:
        cat_totals[e.category] = cat_totals.get(e.category, 0) + e.servings
        kcal = _kcal_for_entry(e.food_name, e.category, e.servings)
        total_kcal += kcal
        macro = FOOD_CALORIES.get(e.food_name)
        if macro:
            total_protein_g += round(macro['protein_g'] * e.servings, 1)
            total_carbs_g += round(macro['carbs_g'] * e.servings, 1)
            total_fat_g += round(macro['fat_g'] * e.servings, 1)

    categories = []
    ok_count = 0
    for cat_key, info in DAILY_LIMITS.items():
        consumed = cat_totals.get(cat_key, 0)
        limit = info['daily']
        goal_min = info['goal_min']
        if consumed > limit:
            status = 'over'
        elif consumed >= goal_min:
            status = 'ok'
            ok_count += 1
        else:
            status = 'none'
        categories.append({
            'key': cat_key, 'label': info['label'], 'unit': info['unit'],
            'consumed': consumed, 'limit': limit, 'goal_min': goal_min, 'status': status,
        })

    score = max(0, 100 - sum(15 for c in categories if c['status'] == 'over')
                       - sum(5 for c in categories if c['status'] == 'none'))

    weekly_treats = []
    for food_key, info in WEEKLY_LIMITS.items():
        count = sum(
            e.servings for e in week_entries
            if e.food_name.lower() == food_key or
               (food_key == 'huevos' and 'huevo' in e.food_name.lower())
        )
        weekly_treats.append({
            'key': food_key, 'label': info['label'], 'consumed': count,
            'weekly_limit': info['weekly'], 'status': 'ok' if count <= info['weekly'] else 'over',
        })

    messages = []
    for c in categories:
        if c['status'] == 'over':
            messages.append(f"Excediste {c['label']}: {c['consumed']} de {c['limit']} {c['unit']} recomendadas")
        elif c['status'] == 'none' and c['goal_min'] > 0:
            messages.append(f"No consumiste {c['label']} hoy")

    return {
        'categories': categories,
        'weekly_treats': weekly_treats,
        'messages': messages,
        'score': score,
        'total_kcal': total_kcal,
        'total_entries': len(entries),
        'macros': {'protein_g': round(total_protein_g, 1), 'carbs_g': round(total_carbs_g, 1), 'fat_g': round(total_fat_g, 1)},
    }

# ── Endpoints ──────────────────────────────────────────────────────────────

@router.post("/body-metric", response_model=BodyMetricOut, status_code=201)
def log_body_metric(data: BodyMetricIn, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    entry_date = data.date or date.today()
    existing = db.query(BodyMetric).filter(
        and_(BodyMetric.user_id == current_user.id, BodyMetric.date == entry_date)
    ).first()
    if existing:
        if data.weight_kg: existing.weight_kg = data.weight_kg
        if data.height_cm: existing.height_cm = data.height_cm
        db.commit(); db.refresh(existing); return existing
    metric = BodyMetric(user_id=current_user.id, date=entry_date,
                        weight_kg=data.weight_kg, height_cm=data.height_cm)
    db.add(metric); db.commit(); db.refresh(metric); return metric

@router.get("/body-metrics", response_model=List[BodyMetricOut])
def get_body_metrics(limit: int = 30, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(BodyMetric).filter(BodyMetric.user_id == current_user.id)\
        .order_by(BodyMetric.date.desc()).limit(limit).all()

@router.get("/body-metric/latest")
def get_latest_metric(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    m = db.query(BodyMetric).filter(BodyMetric.user_id == current_user.id)\
        .order_by(BodyMetric.date.desc()).first()
    if not m:
        return {'weight_kg': None, 'height_cm': None, 'bmi': None, 'water_goal_ml': None,
                'daily_kcal_goal': 2000}
    bmi = round(m.weight_kg / ((m.height_cm / 100) ** 2), 1) if m.weight_kg and m.height_cm else None
    water_ml = int(m.weight_kg * 35) if m.weight_kg else None
    # Harris-Benedict estimate (sedentary baseline)
    kcal_goal = int(m.weight_kg * 30) if m.weight_kg else 2000
    return {'weight_kg': m.weight_kg, 'height_cm': m.height_cm, 'bmi': bmi,
            'water_goal_ml': water_ml, 'daily_kcal_goal': kcal_goal, 'date': m.date}

@router.post("/food-log", response_model=FoodLogOut, status_code=201)
def log_food(data: FoodLogIn, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    entry = FoodLog(user_id=current_user.id, date=data.date or date.today(),
                    food_name=data.food_name, category=data.category,
                    servings=data.servings, meal_time=data.meal_time)
    db.add(entry); db.commit(); db.refresh(entry); return entry

@router.delete("/food-log/{log_id}", status_code=204)
def delete_food_log(log_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    entry = db.query(FoodLog).filter(FoodLog.id == log_id, FoodLog.user_id == current_user.id).first()
    if not entry: raise HTTPException(404, "Not found")
    db.delete(entry); db.commit()

@router.get("/food-log/today")
def get_today_log(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    today = date.today()
    entries = db.query(FoodLog).filter(
        and_(FoodLog.user_id == current_user.id, FoodLog.date == today)
    ).order_by(FoodLog.created_at).all()
    return [{
        'id': str(e.id), 'food_name': e.food_name, 'category': e.category,
        'servings': e.servings, 'meal_time': e.meal_time,
        'kcal': _kcal_for_entry(e.food_name, e.category, e.servings),
    } for e in entries]

@router.get("/summary/today")
def get_today_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    today_entries = db.query(FoodLog).filter(
        and_(FoodLog.user_id == current_user.id, FoodLog.date == today)
    ).all()
    week_entries = db.query(FoodLog).filter(
        and_(FoodLog.user_id == current_user.id, FoodLog.date >= week_start)
    ).all()
    summary = _day_summary(today_entries, week_entries)
    summary['preset_foods'] = PRESET_FOODS
    return summary

@router.get("/summary/week")
def get_week_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Returns Mon–Sun weekly nutrition summary with per-day breakdown."""
    today = date.today()
    week_start = today - timedelta(days=today.weekday())  # Monday
    week_end = week_start + timedelta(days=6)             # Sunday

    week_entries = db.query(FoodLog).filter(
        and_(FoodLog.user_id == current_user.id,
             FoodLog.date >= week_start,
             FoodLog.date <= week_end)
    ).all()

    days = []
    week_total_kcal = 0
    week_scores = []

    for offset in range(7):
        day_date = week_start + timedelta(days=offset)
        day_entries = [e for e in week_entries if e.date == day_date]
        summary = _day_summary(day_entries, week_entries)
        is_past_or_today = day_date <= today
        week_total_kcal += summary['total_kcal']
        if is_past_or_today and summary['total_entries'] > 0:
            week_scores.append(summary['score'])
        days.append({
            'date': day_date.isoformat(),
            'day_name': DAY_NAMES[offset],
            'is_today': day_date == today,
            'is_future': day_date > today,
            'total_kcal': summary['total_kcal'],
            'total_entries': summary['total_entries'],
            'score': summary['score'],
            'macros': summary['macros'],
            'categories': summary['categories'],
        })

    # Weekly treat compliance
    weekly_treats = []
    for food_key, info in WEEKLY_LIMITS.items():
        count = sum(
            e.servings for e in week_entries
            if e.food_name.lower() == food_key or
               (food_key == 'huevos' and 'huevo' in e.food_name.lower())
        )
        weekly_treats.append({
            'key': food_key, 'label': info['label'], 'consumed': count,
            'weekly_limit': info['weekly'], 'status': 'ok' if count <= info['weekly'] else 'over',
        })

    week_score = round(sum(week_scores) / len(week_scores)) if week_scores else 0

    return {
        'week_start': week_start.isoformat(),
        'week_end': week_end.isoformat(),
        'days': days,
        'week_total_kcal': week_total_kcal,
        'week_score': week_score,
        'weekly_treats': weekly_treats,
        'logged_days': sum(1 for d in days if d['total_entries'] > 0 and not d['is_future']),
        'total_days_so_far': sum(1 for d in days if not d['is_future']),
    }

@router.get("/presets")
def get_presets():
    return PRESET_FOODS
