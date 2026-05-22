import random
from typing import List, Optional


_MESSAGES_GENERAL = [
    "Los pequeños pasos diarios construyen vidas extraordinarias.",
    "Tu yo del futuro te está observando — hazlo sentir orgulloso.",
    "Progreso, no perfección. Sigue adelante.",
    "Cada elección de hoy moldea en quién te convertirás mañana.",
    "Estás construyendo una vida que vale la pena vivir.",
    "La constancia es más poderosa que la intensidad.",
    "Un día a la vez. Un hábito a la vez.",
]

_MESSAGES_PRODUCTIVE = [
    "Estás en racha hoy. Mantén ese impulso.",
    "Tu dedicación se nota. Excelente enfoque.",
    "Otra sesión productiva registrada. Eres constante.",
    "Gran trabajo hoy. Tu esfuerzo vale la pena.",
]

_MESSAGES_SLEEP_LOW = [
    "Dormiste menos de 6 horas. El descanso no es un lujo — es combustible.",
    "Considera acostarte temprano esta noche. El sueño es cuando creces.",
    "Tu cuerpo y mente se recuperan mientras duermes. Priorízalo esta noche.",
]

_MESSAGES_SLEEP_GOOD = [
    "Bien descansado. Estás listo para un día fuerte.",
    "Buen sueño anoche. Tu hábito de descanso está dando frutos.",
    "Descansaste bien. Eso marca la diferencia en todo lo que haces.",
]

_MESSAGES_WATER_LOW = [
    "No olvides tomar agua. Tu cerebro funciona con hidratación.",
    "Hora de un vaso de agua. Hábito pequeño, gran impacto.",
    "Tu cuerpo necesita agua para funcionar al máximo. ¡Toma uno ahorita!",
]

_MESSAGES_WATER_GOOD = [
    "Hidratación al día. Tu cuerpo te lo agradece.",
    "Manteniéndote hidratado — una de las cosas más simples que puedes hacer por tu salud.",
]

_MESSAGES_HABITS = [
    "Tus hábitos son tu identidad. Sigue apareciendo.",
    "La consistencia supera la intensidad. Cada racha cuenta.",
    "Completaste todos tus hábitos hoy. Así eres tú ahora.",
    "Día completado. Eso es lo que te separa de los demás.",
]

_MESSAGES_SAVINGS = [
    "Tus ahorros están creciendo. La libertad financiera se construye en silencio, cada día.",
    "Cada contribución acerca tus metas. Mantente comprometido.",
    "Tu progreso de ahorro es real. Cada monto depositado es un voto por tu futuro.",
]

_MESSAGES_LEARNING = [
    "Aprender cada día se acumula con el tiempo. Estás invirtiendo en ti mismo.",
    "Cada página leída, cada lección completada — todo suma.",
    "Tu curiosidad es tu mayor activo. Sigue alimentándola.",
]


def get_motivational_message(context: dict) -> str:
    water_pct = context.get("water_percentage", 0)
    sleep_hours = context.get("sleep_hours")
    sleep_goal = context.get("sleep_goal", 8)
    habits_done = context.get("habits_done", 0)
    total_habits = context.get("total_habits", 0)
    savings_progress = context.get("savings_progress", 0)
    productive_hours = context.get("productive_hours", 0)

    if sleep_hours is not None and sleep_hours < 6:
        return random.choice(_MESSAGES_SLEEP_LOW)

    if water_pct < 30:
        return random.choice(_MESSAGES_WATER_LOW)

    if total_habits > 0 and habits_done >= total_habits:
        return random.choice(_MESSAGES_HABITS)

    if productive_hours >= 4:
        return random.choice(_MESSAGES_PRODUCTIVE)

    if savings_progress >= 50:
        return random.choice(_MESSAGES_SAVINGS)

    if sleep_hours and sleep_hours >= sleep_goal * 0.9:
        return random.choice(_MESSAGES_SLEEP_GOOD)

    return random.choice(_MESSAGES_GENERAL)


def get_insights(context: dict) -> List[str]:
    insights = []
    water_pct = context.get("water_percentage", 0)
    sleep_hours = context.get("sleep_hours")
    sleep_goal = context.get("sleep_goal", 8)
    habits_done = context.get("habits_done", 0)
    total_habits = context.get("total_habits", 0)
    savings_progress = context.get("savings_progress", 0)
    top_fund = context.get("top_fund")
    productive_hours = context.get("productive_hours", 0)
    study_hours_week = context.get("study_hours_week", 0)

    if water_pct < 50:
        insights.append(f"Llevas {int(water_pct)}% de tu meta diaria de agua.")
    elif water_pct >= 100:
        insights.append("¡Meta de agua alcanzada hoy!")

    if sleep_hours is not None:
        if sleep_hours < 6:
            insights.append(f"Dormiste {sleep_hours:.1f}h. Busca {sleep_goal:.0f}h esta noche.")
        elif sleep_hours >= sleep_goal * 0.95:
            insights.append(f"Excelente sueño: {sleep_hours:.1f}h registradas.")

    if total_habits > 0:
        if habits_done == total_habits:
            insights.append("¡Todos los hábitos completados hoy!")
        elif habits_done > 0:
            insights.append(f"{habits_done}/{total_habits} hábitos completados hoy.")

    if savings_progress > 0:
        insights.append(f"Progreso de ahorro total: {savings_progress:.0f}%")

    if top_fund:
        fund_pct = float(top_fund.current_amount) / float(top_fund.target_amount) * 100 if float(top_fund.target_amount) > 0 else 0
        insights.append(f"Fondo {top_fund.name}: {fund_pct:.0f}% alcanzado.")

    if study_hours_week >= 10:
        insights.append(f"Gran semana de estudio: {study_hours_week:.1f}h registradas.")

    return insights[:4]
