"""Pemetaan error MySQL ke respons HTTP."""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from mysql.connector import Error as MySQLError


def daftarkan_penangan_error(app: FastAPI) -> None:
    @app.exception_handler(MySQLError)
    async def tangani_error_mysql(request: Request, exc: MySQLError):
        # SIGNAL SQLSTATE '45000' dari procedure = pelanggaran aturan bisnis,
        # pesannya sudah ditulis untuk ditampilkan apa adanya.
        if exc.sqlstate == "45000":
            return JSONResponse(status_code=400, content={"detail": exc.msg})

        # 1452 = FK gagal saat INSERT/UPDATE (mis. id_ruangan tidak ada).
        if exc.errno == 1452:
            return JSONResponse(
                status_code=400,
                content={
                    "detail": "Data yang dirujuk tidak ditemukan (misal id_kategori_menu atau id_ruangan tidak ada)"
                },
            )

        # Pemetaan khusus (mis. 23000 untuk FK) ditambahkan nanti saat dibutuhkan.
        return JSONResponse(
            status_code=500,
            content={"detail": "Terjadi kesalahan pada server"},
        )