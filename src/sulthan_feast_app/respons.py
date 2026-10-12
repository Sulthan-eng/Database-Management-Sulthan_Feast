"""Perapian hasil procedure untuk respons JSON.

Satu tempat untuk semua konversi, dipakai router publik dan admin:
- Decimal (harga, margin_persen) -> float agar bisa di-JSON-kan
- datetime/date/time -> string ISO 8601
- kolom catatan yang datang sebagai teks JSON -> dict
"""

import json
from datetime import date, datetime, time
from decimal import Decimal


def rapikan_baris(baris: dict) -> dict:
    """Rapikan satu baris hasil procedure (diubah di tempat, lalu dikembalikan)."""
    for kunci, nilai in baris.items():
        if isinstance(nilai, Decimal):
            baris[kunci] = float(nilai)
        elif isinstance(nilai, (datetime, date, time)):
            baris[kunci] = nilai.isoformat()
        elif kunci == "catatan" and isinstance(nilai, (str, bytes, bytearray)):
            # Kolom catatan bertipe JSON; connector sering mengembalikannya
            # sebagai teks, jadi ubah ke dict supaya klien terima objek JSON.
            try:
                baris[kunci] = json.loads(nilai)
            except ValueError:
                pass
    return baris


def rapikan(daftar: list[dict]) -> list[dict]:
    """Rapikan semua baris hasil satu procedure."""
    return [rapikan_baris(b) for b in daftar]
