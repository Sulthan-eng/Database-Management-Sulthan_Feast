"""Titik masuk aplikasi FastAPI "Sulthan Feast".

Tahap 1: hanya GET /menu untuk membuktikan alur
FastAPI -> db.py -> procedure -> MySQL berjalan.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import call_read, tutup_semua_pool


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    tutup_semua_pool()


app = FastAPI(title="Sulthan Feast API", lifespan=lifespan)


@app.get("/menu")
def lihat_menu():
    """Daftar menu untuk customer (tanpa HPP dan margin), hanya harga jual."""
    return call_read("customer", "sp_lihat_menu_customer")