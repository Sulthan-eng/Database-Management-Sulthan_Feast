"""Endpoint publik (customer, tanpa login). Memakai akun MySQL app_customer."""

from fastapi import APIRouter

from ..db import call_read

router = APIRouter(tags=["Publik"])


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