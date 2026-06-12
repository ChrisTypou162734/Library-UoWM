from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "uowm_library"
    firebase_credentials_path: str = "firebase-credentials.json"
    firebase_storage_bucket: str = ""
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    base_url: str = "http://localhost:8000"

    # ── Auth ──────────────────────────────────────────────────────────────────
    secret_key: str = "change-this-to-a-random-secret-in-production"
    admin_username: str = "admin"
    # Δημιούργησε hash με: python scripts/gen_password.py yourpassword
    admin_password_hash: str = "$2b$12$placeholder_run_gen_password_script"

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
