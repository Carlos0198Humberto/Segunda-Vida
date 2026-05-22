"""
Script de inicio rápido para desarrollo local.
Crea la BD y lanza el servidor en un solo paso.
"""
import os
import sys

# Configurar SQLite local
os.environ.setdefault("DATABASE_URL", "sqlite:///./segunda_vida.db")
os.environ.setdefault("SECRET_KEY", "dev-secret-key-segunda-vida-local-2024")
os.environ.setdefault("ENVIRONMENT", "development")

# Crear tablas
print("🚀 Segunda Vida — Iniciando...")
from app.core.database import engine, Base
from app.models import *  # noqa

Base.metadata.create_all(bind=engine)
print("✅ Base de datos lista")
print("🌐 Servidor en: http://localhost:8000")
print("📚 Documentación: http://localhost:8000/docs")
print("⏹️  Detener: Ctrl+C\n")

# Lanzar servidor
import uvicorn
uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
