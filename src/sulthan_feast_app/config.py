"""Konfigurasi aplikasi. Semua nilai dibaca dari file .env di root proyek."""

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

# config.py ada di src/sulthan_feast_app/, jadi root proyek = tiga tingkat ke atas.
ROOT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(ROOT_DIR / ".env")


def _wajib(nama: str) -> str:
    """Ambil variabel environment; gagal sejak awal jika belum diisi."""
    nilai = os.getenv(nama)
    if not nilai:
        raise RuntimeError(f"Variabel '{nama}' belum diisi di file .env")
    return nilai


@dataclass(frozen=True)
class DBAkun:
    user: str
    password: str


@dataclass(frozen=True)
class Settings:
    db_host: str
    db_port: int
    db_name: str
    db_customer: DBAkun
    db_admin: DBAkun
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_expire_menit: int = 60


def muat_settings() -> Settings:
    return Settings(
        db_host=_wajib("DB_HOST"),
        db_port=int(os.getenv("DB_PORT", "3306")),
        db_name=_wajib("DB_NAME"),
        db_customer=DBAkun(
            user=_wajib("DB_CUSTOMER_USER"),
            password=_wajib("DB_CUSTOMER_PASSWORD"),
        ),
        db_admin=DBAkun(
            user=_wajib("DB_ADMIN_USER"),
            password=_wajib("DB_ADMIN_PASSWORD"),
        ),
        jwt_secret=_wajib("JWT_SECRET"),
    )


settings = muat_settings()