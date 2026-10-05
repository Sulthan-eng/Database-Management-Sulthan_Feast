"""Endpoint admin. Memakai akun MySQL app_admin.

/login terbuka; semua endpoint /admin/... wajib token JWT.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, field_validator

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


# -------------------------------------------------------------------- Menu

class MenuInput(BaseModel):
    """Isi permintaan tambah/ubah menu. Aturan nama dan harga divalidasi di procedure."""

    nama: str = Field(examples=["Kebab"])
    id_kategori: int = Field(examples=[1])
    deskripsi: str | None = Field(default=None, examples=["Daging sapi berbumbu khas Timur Tengah"])
    harga_pokok_penjualan: float = Field(examples=[20000])
    harga_jual: float = Field(examples=[35000])


def _argumen_menu(data: MenuInput) -> list:
    # Urutan sama dengan parameter sp_tambah_menu / sp_ubah_menu (setelah id_menu).
    return [
        data.nama,
        data.id_kategori,
        data.deskripsi,
        data.harga_pokok_penjualan,
        data.harga_jual,
    ]


@router.post(
    "/admin/menu",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(admin_saat_ini)],
)
def tambah_menu(data: MenuInput):
    call_write("admin", "sp_tambah_menu", _argumen_menu(data))
    return {"pesan": "Menu berhasil ditambahkan"}


@router.put("/admin/menu/{id_menu}", dependencies=[Depends(admin_saat_ini)])
def ubah_menu(id_menu: int, data: MenuInput):
    call_write("admin", "sp_ubah_menu", [id_menu, *_argumen_menu(data)])
    return {"pesan": "Menu berhasil diubah"}


@router.delete("/admin/menu/{id_menu}", dependencies=[Depends(admin_saat_ini)])
def hapus_menu(id_menu: int):
    call_write("admin", "sp_hapus_menu", [id_menu])
    return {"pesan": "Menu berhasil dihapus"}

 
# ----------------------------------------------------------------- Ruangan
 
class RuanganInput(BaseModel):
    """Isi permintaan tambah/ubah ruangan. Validasi nama ada di procedure."""
 
    ruangan: str = Field(examples=["VIP Room"])
    deskripsi: str | None = Field(
        default=None, examples=["Ruangan untuk menghabiskan waktu bersama keluarga."]
    )
 
 
@router.get("/admin/ruangan", dependencies=[Depends(admin_saat_ini)])
def lihat_ruangan_admin():
    """Daftar ruangan (admin)."""
    return call_read("admin", "sp_lihat_ruangan")
 
 
@router.post(
    "/admin/ruangan",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(admin_saat_ini)],
)
def tambah_ruangan(data: RuanganInput):
    call_write("admin", "sp_tambah_ruangan", [data.ruangan, data.deskripsi])
    return {"pesan": "Ruangan berhasil ditambahkan"}
 
 
@router.put("/admin/ruangan/{id_ruangan}", dependencies=[Depends(admin_saat_ini)])
def ubah_ruangan(id_ruangan: int, data: RuanganInput):
    call_write(
        "admin", "sp_ubah_ruangan", [id_ruangan, data.ruangan, data.deskripsi]
    )
    return {"pesan": "Ruangan berhasil diubah"}
 
 
@router.delete("/admin/ruangan/{id_ruangan}", dependencies=[Depends(admin_saat_ini)])
def hapus_ruangan(id_ruangan: int):
    """Hapus ruangan. PERHATIAN: trigger ikut menghapus SEMUA reservasi
    di ruangan ini (riwayat log reservasi tetap tersimpan)."""
    call_write("admin", "sp_hapus_ruangan", [id_ruangan])
    return {"pesan": "Ruangan berhasil dihapus"}