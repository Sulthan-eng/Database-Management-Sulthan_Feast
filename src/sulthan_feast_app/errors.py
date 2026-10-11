"""Pemetaan error MySQL ke respons HTTP.

Semua aturan bisnis dari database keluar lewat SIGNAL SQLSTATE '45000',
jadi pesannya sudah berbahasa Indonesia dan bisa diteruskan apa adanya.
Error lain (FK, CHECK, ENUM, GRANT) dipetakan ke kode HTTP yang pas
supaya tidak bocor detail internal ke klien.
"""

import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from mysql.connector import Error as MySQLError

logger = logging.getLogger(__name__)

# Pesan ramah untuk tiap CHECK yang ada di database.
# Nama constraint diambil dari pesan error MySQL (errno 3819).
_PESAN_CHECK = {
    "chk_menu_harga": "Harga jual harus lebih besar dari harga pokok dan HPP tidak boleh negatif",
    "chk_reservasi_jumlah_orang": "Jumlah orang harus lebih dari 0",
    "chk_reservasi_durasi": "Waktu selesai harus setelah waktu mulai",
    "chk_customer_no_wa": "Nomor WhatsApp harus diawali 08 dan 10-13 digit",
}


def petakan_mysql_error(exc: MySQLError) -> tuple[int, str]:
    """Kembalikan (status_http, detail) untuk satu error MySQL."""
    pesan = exc.msg or ""
    pesan_kecil = pesan.lower()

    # 45000 = SIGNAL dari procedure (aturan bisnis dilanggar).
    if exc.sqlstate == "45000":
        # "tidak ditemukan" berarti datanya memang tidak ada -> 404.
        if "tidak ditemukan" in pesan_kecil:
            return 404, pesan
        return 400, pesan

    # 3819 = CHECK constraint dilanggar. Nama constraint ada di pesan.
    if exc.errno == 3819:
        for nama, pesan_ramah in _PESAN_CHECK.items():
            if nama in pesan_kecil:
                return 400, pesan_ramah
        return 400, "Nilai tidak memenuhi syarat (CHECK constraint)"

    # 1452 = FK gagal (mis. id_kategori / id_ruangan tidak ada).
    if exc.errno == 1452:
        return 400, "Data rujukan tidak ditemukan"

    # 1048 = kolom NOT NULL diisi NULL (mis. nama kosong setelah NULLIF/TRIM).
    if exc.errno == 1048:
        return 400, "Kolom wajib diisi / tidak boleh kosong"

    # 1265 = data terpotong, mis. string bukan anggota ENUM.
    if exc.errno == 1265:
        return 400, "Nilai tidak valid"

    # Selain itu = masalah server (GRANT salah, procedure hilang, dll).
    # Klien hanya dapat pesan umum; detail dicatat di log server.
    return 500, "Terjadi kesalahan pada server"


def daftarkan_penangan_error(app: FastAPI) -> None:
    @app.exception_handler(MySQLError)
    async def tangani_error_mysql(request: Request, exc: MySQLError):
        status_http, detail = petakan_mysql_error(exc)
        if status_http == 500:
            # Ini berarti konfigurasi salah (GRANT / nama procedure),
            # bukan salah pengguna, jadi wajib terlihat di log server.
            logger.error(
                "MySQL errno=%s sqlstate=%s path=%s msg=%s",
                exc.errno,
                exc.sqlstate,
                request.url.path,
                exc.msg,
            )
        return JSONResponse(status_code=status_http, content={"detail": detail})