"""
Crea todas las tablas directamente desde los modelos SQLAlchemy.
Usar para desarrollo local con SQLite.
"""
import os

# Usa SQLite por defecto si no hay DATABASE_URL configurada
if "DATABASE_URL" not in os.environ:
    os.environ["DATABASE_URL"] = "sqlite:///./segunda_vida.db"

from app.core.database import engine, Base
from app.models import *  # noqa - registra todos los modelos

def main():
    print("Creando tablas en:", engine.url)
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas correctamente:")
    for table in Base.metadata.sorted_tables:
        print(f"   - {table.name}")

if __name__ == "__main__":
    main()
