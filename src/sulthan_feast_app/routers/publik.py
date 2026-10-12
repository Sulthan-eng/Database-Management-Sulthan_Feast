"""Endpoint publik (customer, tanpa login). Memakai akun MySQL app_customer."""

import json
from datetime import datetime

from fastapi import APIRouter, Query, status
from pydantic import BaseModel, ConfigDict, Field

from ..db import call_read, call_write
from ..respons import rapikan

router = APIRouter(tags=["Publik"])


class Catatan(BaseModel):
    """Isi kolom JSON reservasi.catatan.

    MySQL hanya memeriksa JSON valid, jadi kunci yang boleh ada
    dibatasi di sini. Jangan masukkan data yang sudah punya kolom
    sendiri (waktu, jumlah orang, ruangan, nama, no WA).
    """

    model_config = ConfigDict(extra="forbid")

    acara: str | None = None
    request: list[str] = []
    alergi: list[str] = []
    pantangan: list[str] = []
    catatan_lain: str | None = None


class ReservasiBaru(BaseModel):
    """Isi permintaan reservasi.

    Di sini hanya bentuk (tipe) yang dicek. Aturan bisnis
    (mulai harus di masa depan, selesai > mulai, ruangan bisa
    dipesan, tidak bentrok) divalidasi database di sp_buat_reservasi,
    sengaja tidak diduplikasi di Python.
    """

    nama: str = Field(examples=["Farizan"])
    no_wa: str = Field(examples=["081255556666"])
    waktu_reservasi: datetime = Field(examples=["2026-12-20 19:00:00"])
    waktu_selesai: datetime = Field(examples=["2026-12-20 21:00:00"])
    jumlah_orang: int = Field(examples=[8])
    id_ruangan: int = Field(examples=[5])
    catatan: Catatan | None = Field(default=None)


@router.get("/menu")
def lihat_menu():
    """Daftar menu untuk customer (tanpa HPP dan margin)."""
    return rapikan(call_read("customer", "sp_lihat_menu_customer"))


@router.get("/menu/cari")
def cari_menu(keyword: str):
    """Cari menu yang namanya diawali keyword (memakai idx_menu_nama)."""
    return rapikan(call_read("customer", "sp_cari_menu", [keyword]))


@router.get("/kategori")
def lihat_kategori():
    """Daftar kategori menu."""
    return rapikan(call_read("customer", "sp_lihat_kategori_menu"))


@router.get("/ruangan")
def lihat_ruangan():
    """Daftar ruangan dengan kondisi fisik SAAT INI.

    'Sedang Dipakai' hanya berarti ada tamu di dalamnya sekarang,
    ruangan itu tetap bisa dipesan untuk waktu lain.
    """
    return rapikan(call_read("customer", "sp_lihat_ruangan"))


@router.get("/ruangan/jadwal")
def lihat_jadwal_ruangan(
    id_ruangan: int | None = Query(
        default=None,
        description="ID ruangan; kosongkan untuk jadwal semua ruangan",
    ),
):
    """Jadwal terisi suatu ruangan (slot pending/confirmed/berlangsung/selesai
    yang belum lewat). Slot cancelled dan yang sudah lewat tidak muncul."""
    # None terkirim sebagai NULL, artinya semua ruangan (lihat procedure).
    return rapikan(call_read("customer", "sp_lihat_jadwal_ruangan", [id_ruangan]))


@router.post("/reservasi", status_code=status.HTTP_201_CREATED)
def buat_reservasi(data: ReservasiBaru):
    """Buat reservasi baru. Customer tidak perlu login."""
    catatan_json = (
        None
        if data.catatan is None
        else json.dumps(data.catatan.model_dump(), ensure_ascii=False)
    )
    # Urutan sama persis dengan parameter sp_buat_reservasi di file SQL.
    call_write(
        "customer",
        "sp_buat_reservasi",
        [
            data.nama,
            data.no_wa,
            data.waktu_reservasi,
            data.waktu_selesai,
            data.jumlah_orang,
            data.id_ruangan,
            catatan_json,
        ],
    )
    return {"pesan": "Reservasi berhasil dibuat"}