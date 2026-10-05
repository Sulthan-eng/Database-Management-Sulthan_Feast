"""Titik masuk aplikasi FastAPI "Sulthan Feast"."""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import tutup_semua_pool
from .errors import daftarkan_penangan_error
from .routers import publik


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    tutup_semua_pool()


app = FastAPI(title="Sulthan Feast API", lifespan=lifespan)


daftarkan_penangan_error(app)
app.include_router(publik.router)