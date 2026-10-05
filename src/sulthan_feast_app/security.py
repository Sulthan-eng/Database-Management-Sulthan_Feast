"""Hashing password (bcrypt) dan token JWT untuk admin."""

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .config import settings

# auto_error=False supaya kita sendiri yang menjawab 401 (bukan 403 bawaan).
_skema_bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    """Hash bcrypt (60 karakter) yang siap dikirim ke sp_tambah_user."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(
            password.encode("utf-8"), password_hash.encode("utf-8")
        )
    except ValueError:
        # Hash di database bukan bcrypt valid (mis. hash dummy): anggap tidak cocok.
        return False


def buat_token(id_user: int, username: str) -> str:
    sekarang = datetime.now(timezone.utc)
    payload = {
        "sub": str(id_user),  # PyJWT mewajibkan 'sub' bertipe string
        "username": username,
        "iat": sekarang,
        "exp": sekarang + timedelta(minutes=settings.jwt_expire_menit),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def admin_saat_ini(
    kredensial: HTTPAuthorizationCredentials | None = Depends(_skema_bearer),
) -> dict:
    """Dependency untuk endpoint admin: wajib token JWT yang valid."""
    galat = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token tidak valid atau sudah kedaluwarsa",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if kredensial is None:
        raise galat
    try:
        payload = jwt.decode(
            kredensial.credentials,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return {"id_user": int(payload["sub"]), "username": payload["username"]}
    except (jwt.PyJWTError, KeyError, ValueError):
        raise galat