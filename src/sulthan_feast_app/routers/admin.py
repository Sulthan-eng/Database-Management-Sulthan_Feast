"""Endpoint admin. Memakai akun MySQL app_admin.

POST /login terbuka; semua endpoint /admin/... wajib token JWT.
(Jalur /login dipertahankan seperti kode lama atas keputusan pengguna;
dokumen v6 mengusulkan /admin/login.)
"""

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, field_validator

from ..db import call_read, call_write
from ..respons import rapikan
from ..security import admin_saat_ini, buat_token, hash_password, verify_password

router = APIRouter(tags=["Admin"])

# Pilihan status persis seperti ENUM di database. Pydantic hanya mengecek
# bentuk (salah ketik langsung 422); alur transisi tetap divalidasi procedure.
StatusReservasi = Literal["pending", "confirmed", "berlangsung", "selesai", "cancelled"]
StatusRuangan = Literal["Tersedia", "Sedang Dipakai", "Pemeliharaan", "Nonaktif"]


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
    return rapikan(call_read("admin", "sp_lihat_menu_admin"))


# ---------------------------------------------------------------- Kategori

class KategoriInput(BaseModel):
    """Isi permintaan tambah/ubah kategori. Validasi nama ada di procedure."""

    kategori: str


@router.get("/admin/kategori", dependencies=[Depends(admin_saat_ini)])
def lihat_kategori_admin():
    """Daftar kategori menu (admin)."""
    return rapikan(call_read("admin", "sp_lihat_kategori_menu"))


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
    """Isi permintaan tambah ruangan. Validasi nama ada di procedure."""

    ruangan: str = Field(examples=["VIP Room"])
    deskripsi: str | None = Field(
        default=None, examples=["Ruangan untuk menghabiskan waktu bersama keluarga."]
    )


class RuanganUbah(BaseModel):
    """Isi permintaan ubah ruangan. sp_ubah_ruangan wajib menerima status."""

    ruangan: str = Field(examples=["VIP Room"])
    deskripsi: str | None = Field(default=None)
    status_ruangan: StatusRuangan = Field(examples=["Pemeliharaan"])


@router.get("/admin/ruangan", dependencies=[Depends(admin_saat_ini)])
def lihat_ruangan_admin():
    """Daftar ruangan (admin)."""
    return rapikan(call_read("admin", "sp_lihat_ruangan"))


@router.post(
    "/admin/ruangan",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(admin_saat_ini)],
)
def tambah_ruangan(data: RuanganInput):
    call_write("admin", "sp_tambah_ruangan", [data.ruangan, data.deskripsi])
    return {"pesan": "Ruangan berhasil ditambahkan"}


@router.put("/admin/ruangan/{id_ruangan}", dependencies=[Depends(admin_saat_ini)])
def ubah_ruangan(id_ruangan: int, data: RuanganUbah):
    # Urutan sama persis dengan sp_ubah_ruangan di file SQL.
    call_write(
        "admin",
        "sp_ubah_ruangan",
        [id_ruangan, data.ruangan, data.deskripsi, data.status_ruangan],
    )
    return {"pesan": "Ruangan berhasil diubah"}


@router.delete("/admin/ruangan/{id_ruangan}", dependencies=[Depends(admin_saat_ini)])
def hapus_ruangan(id_ruangan: int):
    """Hapus ruangan. Ditolak database jika ruangan punya riwayat reservasi;
    dalam kasus itu ubah statusnya menjadi Nonaktif."""
    call_write("admin", "sp_hapus_ruangan", [id_ruangan])
    return {"pesan": "Ruangan berhasil dihapus"}


# --------------------------------------------------------------- Reservasi

class StatusInput(BaseModel):
    """Status baru reservasi. Alur transisi yang boleh dicek procedure."""

    status: StatusReservasi = Field(examples=["confirmed"])


@router.get("/admin/reservasi", dependencies=[Depends(admin_saat_ini)])
def lihat_reservasi():
    """Semua reservasi beserta data customer dan ruangan."""
    return rapikan(call_read("admin", "sp_lihat_reservasi"))


# Rute statis dideklarasikan SEBELUM rute dinamis di bawahnya.
@router.get("/admin/reservasi/aktif", dependencies=[Depends(admin_saat_ini)])
def lihat_reservasi_aktif():
    """Reservasi aktif: yang berlangsung, atau pending/confirmed
    yang waktu_selesai-nya masih di masa depan."""
    return rapikan(call_read("admin", "sp_lihat_reservasi_aktif"))


@router.put(
    "/admin/reservasi/{id_reservasi}/status",
    dependencies=[Depends(admin_saat_ini)],
)
def ubah_status_reservasi(id_reservasi: int, data: StatusInput):
    """Ubah status. Perubahan otomatis tercatat di log lewat trigger."""
    call_write("admin", "sp_ubah_status_reservasi", [id_reservasi, data.status])
    return {"pesan": "Status reservasi berhasil diubah"}


@router.get(
    "/admin/reservasi/{id_reservasi}/log",
    dependencies=[Depends(admin_saat_ini)],
)
def lihat_log_satu_reservasi(id_reservasi: int):
    """Riwayat perubahan status satu reservasi (urut id_log terbaru dulu).
    ID yang tidak ada menghasilkan daftar kosong, bukan error."""
    return rapikan(
        call_read("admin", "sp_lihat_log_status_reservasi", [id_reservasi])
    )


@router.get("/admin/log-status", dependencies=[Depends(admin_saat_ini)])
def lihat_semua_log():
    """Seluruh riwayat perubahan status. None terkirim sebagai NULL,
    artinya semua log (lihat procedure)."""
    return rapikan(call_read("admin", "sp_lihat_log_status_reservasi", [None]))


# -------------------------------------------------------------------- User
class UserBaru(BaseModel):
    """Akun admin baru. Password di-hash di sini; database hanya menerima hash."""

    username: str = Field(examples=["admin2"])
    password: str = Field(min_length=8, examples=["PasswordKuat123"])

    @field_validator("password")
    @classmethod
    def batasi_72_byte(cls, nilai: str) -> str:
        if len(nilai.encode("utf-8")) > 72:
            raise ValueError("Password maksimal 72 byte")
        return nilai


@router.get("/admin/user", dependencies=[Depends(admin_saat_ini)])
def lihat_user():
    """Daftar akun admin (tanpa hash password)."""
    return rapikan(call_read("admin", "sp_lihat_user"))


@router.post(
    "/admin/user",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(admin_saat_ini)],
)
def tambah_user(data: UserBaru):
    # sp_tambah_user mengembalikan id_user lewat SELECT LAST_INSERT_ID().
    hasil = call_write(
        "admin", "sp_tambah_user", [data.username, hash_password(data.password)]
    )
    id_baru = hasil[0]["id_user"] if hasil else None
    return {"pesan": "User berhasil ditambahkan", "id_user": id_baru}


@router.delete("/admin/user/{id_user}")
def hapus_user(id_user: int, admin: dict = Depends(admin_saat_ini)):
    # Admin tidak boleh menghapus akun yang sedang dipakainya sendiri.
    if id_user == admin["id_user"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tidak bisa menghapus akun yang sedang digunakan",
        )
    call_write("admin", "sp_hapus_user", [id_user])
    return {"pesan": "User berhasil dihapus"}
