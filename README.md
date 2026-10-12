# Sulthan Feast App

API reservasi rumah makan "Sulthan Feast" berbasis **FastAPI + MySQL**.
Seluruh akses database dilakukan lewat `CALL procedure` (stored procedure),
tidak ada query `SELECT/INSERT/UPDATE/DELETE` langsung dari kode Python.

## Fitur

**Publik (tanpa login, akun DB `app_customer`):**

- Lihat menu customer (tanpa HPP/margin)
- Cari menu berdasarkan awalan nama
- Lihat kategori menu dan ruangan (kondisi fisik saat ini)
- Lihat jadwal terisi suatu ruangan
- Buat reservasi

**Admin (login JWT, akun DB `app_admin`):**

- Login (`POST /login`) -> JWT Bearer, kedaluwarsa 60 menit
- CRUD kategori menu, menu, ruangan
- Lihat semua reservasi + yang aktif + ubah status
  (`pending`, `confirmed`, `berlangsung`, `selesai`, `cancelled`)
- Lihat log perubahan status reservasi
- Kelola user admin
- Tidak ada pengelolaan customer: nama customer hanya berubah
  lewat upsert saat reservasi dibuat

## Tech Stack

- Python >= 3.12
- FastAPI, Uvicorn
- mysql-connector-python (connection pool)
- bcrypt (hash password), PyJWT, python-dotenv
- Manajemen dependensi: `uv`

## Struktur Proyek

```text
.
├── sql/                     # Sumber kebenaran database (tabel, function,
│                            # index, view, procedure, trigger, grant)
├── src/sulthan_feast_app/
│   ├── main.py              # FastAPI app, registrasi router publik + admin
│   ├── config.py            # Baca .env, dataclass Settings
│   ├── db.py                # 2 connection pool (customer/admin), helper call_read/call_write
│   ├── respons.py           # Satu tempat konversi respons (Decimal, datetime, catatan)
│   ├── security.py          # bcrypt hash/verify, buat/validasi JWT
│   ├── errors.py            # Mapping MySQLError -> HTTP (45000, 3819, 1048, ...)
│   └── routers/
│       ├── publik.py        # GET /menu, /menu/cari, /kategori, /ruangan,
│       │                    # /ruangan/jadwal, POST /reservasi
│       └── admin.py         # POST /login, /admin/* (menu, kategori, ruangan,
│                            # reservasi, log-status, user)
├── .env.example             # Contoh konfigurasi (salin menjadi .env)
├── pyproject.toml
└── README.md
```

Prinsip keamanan di `src/sulthan_feast_app/db.py`:

- Pool `customer` -> user MySQL `app_customer`, hanya untuk endpoint publik.
- Pool `admin` -> user MySQL `app_admin`, untuk login + endpoint `/admin/*`.
- Kedua akun hanya punya hak `EXECUTE` pada procedure (lihat `sql/User_Privilege.sql`).
- Transaksi (`COMMIT`/`ROLLBACK`) diatur di dalam procedure, Python memakai `autocommit=True`.

## Prasyarat

1. Python 3.12 + `uv` terinstal.
2. MySQL 8 berjalan dengan database + 2 user yang sudah punya hak `EXECUTE`
   pada procedure yang dibutuhkan (jalankan file-file di `sql/` lewat koneksi
   pemilik DB, bukan lewat akun `app_*`).

## Instalasi

```bash
uv sync
cp .env.example .env
# lalu isi .env sesuai kredensial lokal
```

Isi `.env` (lihat `.env.example`; jangan commit file ini):

```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=sulthan_feast
DB_CUSTOMER_USER=app_customer
DB_CUSTOMER_PASSWORD='IsiAku'
DB_ADMIN_USER=app_admin
DB_ADMIN_PASSWORD='IsiAku'
JWT_SECRET='IsiSaya'
```

## Menjalankan

```bash
uv run fastapi dev src/sulthan_feast_app/main.py
```

Lalu buka:

- Swagger UI: <http://127.0.0.1:8000/docs>
- OpenAPI JSON: <http://127.0.0.1:8000/openapi.json>

## Daftar Endpoint

### Publik (`routers/publik.py`, pool `customer`, tanpa auth)

| Method | Path | Procedure | Keterangan |
| ------ | ---- | --------- | ---------- |
| GET | `/menu` | `sp_lihat_menu_customer` | Menu tanpa HPP/margin |
| GET | `/menu/cari?keyword=...` | `sp_cari_menu` | Nama diawali keyword (`LIKE 'keyword%'`) |
| GET | `/kategori` | `sp_lihat_kategori_menu` | Daftar kategori |
| GET | `/ruangan` | `sp_lihat_ruangan` | Kondisi fisik saat ini; `Sedang Dipakai` tetap bisa dipesan untuk waktu lain |
| GET | `/ruangan/jadwal?id_ruangan=...` | `sp_lihat_jadwal_ruangan` | Slot terisi; tanpa `id_ruangan` = semua ruangan |
| POST | `/reservasi` | `sp_buat_reservasi` | Body: `nama, no_wa, waktu_reservasi, waktu_selesai, jumlah_orang, id_ruangan, catatan?` |

Contoh buat reservasi:

```json
{
  "nama": "Farizan",
  "no_wa": "081255556666",
  "waktu_reservasi": "2026-12-20 19:00:00",
  "waktu_selesai": "2026-12-20 21:00:00",
  "jumlah_orang": 8,
  "id_ruangan": 5,
  "catatan": { "acara": "ulang tahun", "request": ["kursi bayi"], "alergi": [] }
}
```

Kunci `catatan` yang boleh ada: `acara`, `request`, `alergi`,
`pantangan`, `catatan_lain`. Kunci lain ditolak API (422).
Tips JSON: tulis angka nol sebagai `0`, bukan `0000`
(angka berawalan nol tidak valid dalam JSON).

### Admin (`routers/admin.py`, pool `admin`, wajib JWT kecuali login)

Login dulu:

```bash
curl -X POST http://127.0.0.1:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"PasswordKuat123"}'
# -> {"access_token":"...","token_type":"bearer"}
```

Pakai token untuk request berikutnya (di Swagger: tombol Authorize,
tempel token tanpa kata "Bearer"):

```bash
curl http://127.0.0.1:8000/admin/menu -H "Authorization: Bearer <token>"
```

| Method | Path | Procedure |
| ------ | ---- | --------- |
| POST | `/login` | `sp_verifikasi_login` |
| GET | `/admin/menu` | `sp_lihat_menu_admin` |
| POST | `/admin/menu` | `sp_tambah_menu` |
| PUT/DELETE | `/admin/menu/{id}` | `sp_ubah_menu`, `sp_hapus_menu` |
| GET/POST | `/admin/kategori` | `sp_lihat_kategori_menu`, `sp_tambah_kategori_menu` |
| PUT/DELETE | `/admin/kategori/{id}` | `sp_ubah_kategori_menu`, `sp_hapus_kategori_menu` (`?hapus_menu=true` ikut menghapus menu di dalamnya) |
| GET/POST | `/admin/ruangan` | `sp_lihat_ruangan`, `sp_tambah_ruangan` |
| PUT/DELETE | `/admin/ruangan/{id}` | `sp_ubah_ruangan` (body wajib ada `status_ruangan`), `sp_hapus_ruangan` (ditolak jika punya riwayat reservasi -> jadikan `Nonaktif`) |
| GET | `/admin/reservasi` | `sp_lihat_reservasi` |
| GET | `/admin/reservasi/aktif` | `sp_lihat_reservasi_aktif` |
| PUT | `/admin/reservasi/{id}/status` | `sp_ubah_status_reservasi` (salah satu dari 5 status) |
| GET | `/admin/reservasi/{id}/log` | `sp_lihat_log_status_reservasi` (satu reservasi) |
| GET | `/admin/log-status` | `sp_lihat_log_status_reservasi` (semua log) |
| GET/POST | `/admin/user` | `sp_lihat_user`, `sp_tambah_user` (password di-hash bcrypt di API, respons mengembalikan `id_user`) |
| DELETE | `/admin/user/{id}` | `sp_hapus_user` (tidak bisa hapus akun sendiri / user terakhir) |

Catatan: dokumen perancangan mengusulkan `POST /admin/login`,
tapi kode memakai `POST /login` (konvensi lama yang dipertahankan).

Aturan khusus yang sudah diimplementasi di API:

- Password dibatasi 72 byte (batas bcrypt), min 8 karakter saat tambah user.
- Login gagal (username salah / password salah) selalu menjawab `401 "Username atau password salah"`.
- Endpoint admin tanpa token menjawab `401 "Token tidak valid atau sudah kedaluwarsa"`.
- Pydantic hanya memvalidasi bentuk (tipe, `Literal` status, kunci `catatan`); aturan bisnis ada di database.
- Pemetaan error database (`errors.py`): `45000` -> 400 apa adanya
  ("tidak ditemukan" -> 404); CHECK `3819` -> 400 pesan Indonesia
  (harga, jumlah orang, durasi, format WA); `1048`/`1265`/`1452` -> 400;
  `1370`/`1142`/`1305`/lainnya -> 500 + log server.

## Catatan Zona Waktu

Datetime dikirim apa adanya tanpa informasi zona (waktu lokal restoran),
sedangkan `NOW()` di MySQL memakai zona waktu server. Keduanya konsisten
selama aplikasi dan server database berada di zona yang sama; jika server
berbeda zona, selaraskan dulu (`SELECT @@time_zone`) sebelum menguji
aturan "waktu reservasi harus di masa depan".

