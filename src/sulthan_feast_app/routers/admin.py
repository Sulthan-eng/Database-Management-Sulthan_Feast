"""Endpoint admin. Memakai akun MySQL app_admin.

/login terbuka; semua endpoint /admin/... wajib token JWT.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, field_validator

from ..db import call_read, call_write
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


# ---------------------------------------------------------------- Kategori

class KategoriInput(BaseModel):
    """Isi permintaan tambah/ubah kategori. Validasi nama ada di procedure."""

    kategori: str


@router.get("/admin/kategori", dependencies=[Depends(admin_saat_ini)])
def lihat_kategori_admin():
    """Daftar kategori menu (admin)."""
    return call_read("admin", "sp_lihat_kategori_menu")


@router.post(
    "/admin/kategori",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(admin_saat_ini)],
)
def tambah_kategori(data: KategoriInput):
    call_write("admin", "sp_tambah_kategori_menu", [data.kategori])
    return {"pesan": "Kategori berhasil ditambahkan"}


@router.put("/admin/kategori/{id_kategori}", dependencies=[Depends(admin_saat_ini)])
def ubah_kategori(id_kategori: int, data: KategoriInput):
    call_write("admin", "sp_ubah_kategori_menu", [id_kategori, data.kategori])
    return {"pesan": "Kategori berhasil diubah"}


@router.delete("/admin/kategori/{id_kategori}", dependencies=[Depends(admin_saat_ini)])
def hapus_kategori(id_kategori: int, hapus_menu: bool = False):
    """Hapus kategori. Jika masih dipakai menu, tambahkan ?hapus_menu=true
    untuk ikut menghapus menu-menu di dalamnya (default: ditolak)."""
    call_write("admin", "sp_hapus_kategori_menu", [id_kategori, hapus_menu])
    return {"pesan": "Kategori berhasil dihapus"}