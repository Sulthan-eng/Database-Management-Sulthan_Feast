"""Endpoint publik (customer, tanpa login). Memakai akun MySQL app_customer."""

import json
from datetime import date, time
from typing import Any

from fastapi import APIRouter, status
from pydantic import BaseModel, Field

from ..db import call_read, call_write

router = APIRouter(tags=["Publik"])


class ReservasiBaru(BaseModel):
    """Isi permintaan reservasi. Aturan bisnis divalidasi di procedure."""
 
    nama: str = Field(examples=["Farizan"])
    no_wa: str = Field(examples=["081255556666"])
    tanggal: date = Field(examples=["2026-11-26"])
    jam: time = Field(examples=["20:30:00"])
    jumlah_orang: int = Field(examples=[8])
    id_ruangan: int = Field(examples=[5])
    deskripsi: dict[str, Any] | None = Field(
        default=None,
        description="Data tambahan bebas (JSON), isinya boleh bervariasi.",
        examples=[{"acara": "ulang tahun", "request": ["kursi bayi", "kue"]}],
    )


@router.get("/menu")
def lihat_menu():
    """Daftar menu untuk customer (tanpa HPP dan margin)."""
    return call_read("customer", "sp_lihat_menu_customer")


@router.get("/menu/cari")
def cari_menu(keyword: str):
    """Cari menu berdasarkan awalan nama (LIKE 'keyword%', memakai idx_menu_nama)."""
    return call_read("customer", "sp_cari_menu", [keyword])


@router.get("/kategori")
def lihat_kategori():
    """Daftar kategori menu."""
    return call_read("customer", "sp_lihat_kategori_menu")


@router.get("/ruangan")
def lihat_ruangan():
    """Daftar ruangan."""
    return call_read("customer", "sp_lihat_ruangan")


@router.post("/reservasi", status_code=status.HTTP_201_CREATED)
def buat_reservasi(data: ReservasiBaru):
    """Buat reservasi baru. Customer tidak perlu login."""
    deskripsi = (
        None
        if data.deskripsi is None
        else json.dumps(data.deskripsi, ensure_ascii=False)
    )
    hasil = call_write(
        "customer",
        "sp_buat_reservasi",
        [
            data.nama,
            data.no_wa,
            data.tanggal.isoformat(),
            data.jam.isoformat(),
            data.jumlah_orang,
            data.id_ruangan,
            deskripsi,
        ],
    )
    return {"pesan": "Reservasi berhasil dibuat", "data": hasil}