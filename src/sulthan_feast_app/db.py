"""Lapisan akses database.

Dua connection pool, masing-masing dengan akun MySQL berbeda:
  - "customer" -> app_customer (endpoint publik)
  - "admin"    -> app_admin    (endpoint admin dan login)

Aplikasi tidak pernah menjalankan SELECT/INSERT/UPDATE/DELETE langsung,
semuanya lewat CALL procedure.
"""

from contextlib import contextmanager
from typing import Any, Iterator, Literal, Sequence

import mysql.connector
from mysql.connector import pooling

from .config import DBAkun, settings

Role = Literal["customer", "admin"]

_pools: dict[Role, pooling.MySQLConnectionPool] = {}


def _buat_pool(role: Role, akun: DBAkun) -> pooling.MySQLConnectionPool:
    return pooling.MySQLConnectionPool(
        pool_name=f"sulthan_{role}",
        pool_size=5,
        host=settings.db_host,
        port=settings.db_port,
        database=settings.db_name,
        user=akun.user,
        password=akun.password,
        charset="utf8mb4",
        autocommit=True,  # transaksi diatur di dalam procedure
    )


def _ambil_pool(role: Role) -> pooling.MySQLConnectionPool:
    """Pool dibuat saat pertama dipakai, bukan saat import."""
    if role not in _pools:
        akun = settings.db_customer if role == "customer" else settings.db_admin
        _pools[role] = _buat_pool(role, akun)
    return _pools[role]


@contextmanager
def _koneksi(role: Role) -> Iterator[Any]:
    conn = _ambil_pool(role).get_connection()
    try:
        yield conn
    finally:
        conn.close()  # untuk koneksi pool, close() = kembalikan ke pool


def _panggil(role: Role, nama_procedure: str, args: Sequence[Any]) -> list[dict]:
    """CALL satu procedure, kembalikan semua baris dari result set (jika ada)."""
    with _koneksi(role) as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.callproc(nama_procedure, list(args))
            baris: list[dict] = []
            for hasil in cursor.stored_results():
                baris.extend(hasil.fetchall())
            return baris
        finally:
            cursor.close()


def call_read(role: Role, nama_procedure: str, args: Sequence[Any] = ()) -> list[dict]:
    """Untuk procedure baca (sp_lihat_*, sp_cari_*, sp_verifikasi_login)."""
    return _panggil(role, nama_procedure, args)


def call_write(role: Role, nama_procedure: str, args: Sequence[Any] = ()) -> list[dict]:
    """Untuk procedure tulis (sp_tambah_*, sp_ubah_*, sp_hapus_*, sp_buat_reservasi).

    Commit/rollback sudah ditangani procedure. Jika procedure melakukan SIGNAL
    atau terjadi error FK, mysql.connector.Error diteruskan ke pemanggil
    (dipetakan ke HTTP error di errors.py nanti).
    """
    return _panggil(role, nama_procedure, args)


def tutup_semua_pool() -> None:
    """Dipanggil saat aplikasi berhenti."""
    _pools.clear()


__all__ = ["call_read", "call_write", "tutup_semua_pool", "Role", "mysql"]