# Sulthan Feast App

API reservasi rumah makan "Sulthan Feast" berbasis **FastAPI + MySQL**.
Seluruh akses database dilakukan lewat `CALL procedure` (stored procedure),
tidak ada query `SELECT/INSERT/UPDATE/DELETE` langsung dari kode Python.


## Fitur

**Publik (tanpa login, akun DB `app_customer`):**

- Lihat menu customer (tanpa HPP/margin)
- Cari menu berdasarkan awalan nama
- Lihat kategori menu dan ruangan
- Buat reservasi

**Admin (login JWT, akun DB `app_admin`):**

- Login (`POST /login`) -> JWT Bearer, kedaluwarsa 60 menit
- CRUD kategori menu, menu, ruangan
- Lihat semua reservasi + ubah status (`pending`, `confirmed`, `cancelled`)
- Lihat log perubahan status reservasi
- Ubah nama customer, kelola user admin

## Tech Stack

- Python >= 3.12
- FastAPI, Uvicorn
- mysql-connector-python (connection pool)
- bcrypt (hash password), PyJWT, python-dotenv
- Manajemen dependensi: `uv`

## Struktur Proyek

```text
.
├── src/sulthan_feast_app/
│   ├── main.py        # FastAPI app, registrasi router publik + admin
│   ├── config.py      # Baca .env, dataclass Settings
│   ├── db.py          # 2 connection pool (customer/admin), helper call_read/call_write
│   ├── security.py    # bcrypt hash/verify, buat/validasi JWT
│   ├── errors.py      # Mapping MySQLError -> HTTP (45000 => 400, 1452 => 400)
│   └── routers/
│       ├── publik.py  # GET /menu, /menu/cari, /kategori, /ruangan, POST /reservasi
│       └── admin.py   # POST /login, /admin/* (menu, kategori, ruangan, reservasi, user)
├── .env.example       # Contoh konfigurasi (salin menjadi .env)
├── pyproject.toml
└── README.md
```

Prinsip keamanan di `src/sulthan_feast_app/db.py`:

- Pool `customer` -> user MySQL `app_customer`, hanya untuk endpoint publik.
- Pool `admin` -> user MySQL `app_admin`, untuk login + endpoint `/admin/*`.
- Transaksi (`COMMIT`/`ROLLBACK`) diatur di dalam procedure, Python memakai `autocommit=True`.

## Prasyarat

1. Python 3.12 + `uv` terinstal.
2. MySQL/MariaDB berjalan dengan database + 2 user yang sudah punya hak `EXECUTE` pada procedure yang dibutuhkan.

## Instalasi

```bash
uv sync
cp .env.example .env
# lalu isi .env sesuai kredensial lokal
```

Isi `.env` (lihat `.env.example`):

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
uv run uvicorn sulthan_feast_app.main:app --reload --app-dir src
```

Lalu buka:

- Swagger UI: <http://127.0.0.1:8000/docs>
- OpenAPI JSON: <http://127.0.0.1:8000/openapi.json>

## Daftar Endpoint

### Publik (`routers/publik.py`)

| Method | Path | Procedure | Keterangan |
| ------ | ---- | --------- | ---------- |
| GET | `/menu` | `sp_lihat_menu_customer` | Menu tanpa HPP/margin |
| GET | `/menu/cari?keyword=...` | `sp_cari_menu` | `LIKE 'keyword%'` |
| GET | `/kategori` | `sp_lihat_kategori_menu` | Daftar kategori |
| GET | `/ruangan` | `sp_lihat_ruangan` | Daftar ruangan |
| POST | `/reservasi` | `sp_buat_reservasi` | Body: `nama, no_wa, tanggal, jam, jumlah_orang, id_ruangan, deskripsi?` |

Contoh buat reservasi:

```json
{
  "nama": "Farizan",
  "no_wa": "081255556666",
  "tanggal": "2026-11-26",
  "jam": "20:30:00",
  "jumlah_orang": 8,
  "id_ruangan": 5,
  "deskripsi": { "acara": "ulang tahun", "request": ["kursi bayi", "kue"] }
}
```

### Admin (`routers/admin.py`)

Login dulu:

```bash
curl -X POST http://127.0.0.1:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"PasswordKuat123"}'
# -> {"access_token":"...","token_type":"bearer"}
```

Pakai token untuk request berikutnya:

```bash
curl http://127.0.0.1:8000/admin/menu -H "Authorization: Bearer <token>"
```

| Method | Path | Procedure |
| ------ | ---- | --------- |
| POST | `/login` | `sp_verifikasi_login` |
| GET | `/admin/menu` | `sp_lihat_menu_admin` |
| GET/POST | `/admin/kategori` | `sp_lihat_kategori_menu`, `sp_tambah_kategori_menu` |
| PUT/DELETE | `/admin/kategori/{id}` | `sp_ubah_kategori_menu`, `sp_hapus_kategori_menu` (`hapus_menu=true` untuk cascade) |
| POST | `/admin/menu` | `sp_tambah_menu` |
| PUT/DELETE | `/admin/menu/{id}` | `sp_ubah_menu`, `sp_hapus_menu` |
| GET/POST | `/admin/ruangan` | `sp_lihat_ruangan`, `sp_tambah_ruangan` |
| PUT/DELETE | `/admin/ruangan/{id}` | `sp_ubah_ruangan`, `sp_hapus_ruangan` |
| GET | `/admin/reservasi` | `sp_lihat_reservasi` |
| PUT | `/admin/reservasi/{id}/status` | `sp_ubah_status_reservasi` |
| GET | `/admin/reservasi/log?id_reservasi?` | `sp_lihat_log_status_reservasi` |
| PUT | `/admin/customer/{id}` | `sp_ubah_nama_customer` |
| GET/POST | `/admin/user` | `sp_lihat_user`, `sp_tambah_user` (password di-hash bcrypt di API) |
| DELETE | `/admin/user/{id}` | `sp_hapus_user` (tidak bisa hapus diri sendiri) |

Aturan khusus yang sudah diimplementasi di API:

- Password dibatasi 72 byte (batas bcrypt), min 8 karakter saat tambah user.
- Login gagal (username salah / password salah) selalu menjawab `401 "Username atau password salah"`.
- Endpoint admin tanpa token menjawab `401 "Token tidak valid atau sudah kedaluwarsa"`.
- Error `SIGNAL SQLSTATE '45000'` dari procedure diteruskan sebagai `400` apa adanya.
- Error FK `1452` (mis. `id_kategori_menu` / `id_ruangan` tidak ada) menjadi `400`.

## Pengembangan Selanjutnya

- [ ] Menambahkan folder `sql/` berisi seluruh query.
- [ ] Menambahkan tes otomatis untuk endpoint publik/admin.
- [ ] Menambahkan penanganan error `23000` (duplikat/foreign key saat hapus).
