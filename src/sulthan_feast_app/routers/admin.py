"""Endpoint admin. Memakai akun MySQL app_admin.

/login terbuka; semua endpoint /admin/... wajib token JWT.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, field_validator

from ..db import call_read
from ..security import admin_saat_ini, buat_token, verify_password

router = APIRouter(tags=["Admin"])


class LoginRequest(BaseModel):
    username: str
    password: str

    @field_validator("password")
    @classmethod
    def batasi_72_byte(cls, nilai: str) -> str:
        # bcrypt hanya memakai 72 byte pertama dan menolak yang lebih panjang.
        if len(nilai.encode("utf-8")) > 72:
            raise ValueError("Password maksimal 72 byte")
        return nilai


@router.post("/login")
def login(data: LoginRequest):
    baris = call_read("admin", "sp_verifikasi_login", [data.username])

    # Username tidak ada dan password salah dijawab sama persis,
    # supaya tidak bisa dipakai menebak username yang terdaftar.
    if not baris or not verify_password(data.password, baris[0]["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau password salah",
        )

    user = baris[0]
    token = buat_token(user["id_user"], user["username"])
    return {"access_token": token, "token_type": "bearer"}


@router.get("/admin/menu")
def lihat_menu_admin(admin: dict = Depends(admin_saat_ini)):
    """Daftar menu lengkap dengan HPP dan margin (hanya admin)."""
    return call_read("admin", "sp_lihat_menu_admin")