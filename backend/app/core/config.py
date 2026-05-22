from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Any
import secrets
import json


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Segunda Vida"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Database
    DATABASE_URL: str = "postgresql://segunda_vida:segunda_vida_secret@localhost:5432/segunda_vida"

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # CORS — in production set to ["*"] or your specific domain
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080", "http://localhost:5000", "*"]
    ALLOWED_HOSTS: List[str] = ["localhost", "127.0.0.1", "*"]

    # AI (Future)
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen2.5:7b"

    @field_validator("CORS_ORIGINS", "ALLOWED_HOSTS", mode="before")
    @classmethod
    def parse_list_field(cls, v: Any) -> Any:
        if isinstance(v, str):
            v = v.strip()
            if v.startswith("["):
                return json.loads(v)
            return [item.strip() for item in v.split(",") if item.strip()]
        return v

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
