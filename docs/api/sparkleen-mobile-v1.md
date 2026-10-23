# Sparkleen Mobile API v1

REST API untuk aplikasi mobile pelanggan Sparkleen Laundry. Hanya berisi kebutuhan
pelanggan (auth, profil, katalog, transaksi, nota, info outlet). Data karyawan, inventaris,
dan laporan tetap di web kasir.

## Base URL

| Lingkungan | Base URL |
|---|---|
| Lokal (XAMPP) | `http://localhost:8080/api/v1` |
| Railway | `https://<nama-service>.up.railway.app/api/v1` |

## Autentikasi

- Login menghasilkan token opaque 64 karakter hex. Simpan di secure storage perangkat.
- Kirim pada setiap request yang butuh auth:

```
Authorization: Bearer <token>
```

- Token berlaku 30 hari dan diperpanjang otomatis setiap kali dipakai.
- Logout me-revoke token yang sedang dipakai.
- PIN, token, dan hash tidak pernah dikembalikan oleh API maupun ditulis ke log.

## Format response

Sukses:

```json
{ "data": {}, "meta": {} }
```

`meta` hanya ada pada endpoint daftar: `{page, per_page, total, last_page}`.

Gagal:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data yang dikirim belum valid.",
    "fields": { "pin": ["PIN harus 6 digit angka."] }
  }
}
```

Aturan data:

- Uang selalu integer rupiah, contoh `42000`.
- Tanggal ISO-8601 dengan offset `+07:00`, contoh `2026-10-21T09:00:00+07:00`.
- Endpoint transaksi hanya mengembalikan data milik pelanggan pemilik token. ID milik
  pelanggan lain menghasilkan `404 NOT_FOUND` (bukan 403).

## Endpoint

| Method | Path | Auth | Keterangan |
|---|---|---|---|
| POST | `/auth/register` | - | Daftar akun baru |
| POST | `/auth/activate` | - | Aktivasi pelanggan lama dengan nomor nota |
| POST | `/auth/login` | - | Login nomor telepon + PIN |
| POST | `/auth/logout` | Bearer | Cabut token aktif |
| GET | `/me` | Bearer | Profil + poin + total transaksi |
| PATCH | `/me` | Bearer | Ubah nama dan alamat |
| GET | `/layanan` | Bearer | Daftar layanan aktif |
| GET | `/outlet` | Bearer | Info outlet |
| GET | `/transaksi` | Bearer | Riwayat transaksi (pagination) |
| GET | `/transaksi/{id}` | Bearer | Detail + item + timeline + PIN pengambilan |
| GET | `/transaksi/{id}/nota` | Bearer | Data nota digital (tanpa PIN pengambilan) |

### POST /auth/register

Body:

```json
{
  "nama": "Budi Santoso",
  "no_telp": "081298765432",
  "alamat": "Jl. Merdeka No. 10",
  "pin": "654321"
}
```

Validasi: `nama` 3–100 karakter, `alamat` minimal 5 karakter, `pin` tepat 6 digit angka,
nomor telepon dinormalisasi ke format `62...`. Nomor yang sudah terdaftar (dalam format
apa pun) menghasilkan `409 PHONE_TAKEN`.

Response `201`:

```json
{
  "data": {
    "token": "<64 karakter hex>",
    "expires_at": "2026-11-22 10:00:00",
    "pelanggan": {
      "id_pelanggan": 12,
      "kode_pelanggan": "PLG012",
      "nama": "Budi Santoso",
      "no_telp": "6281298765432",
      "alamat": "Jl. Merdeka No. 10",
      "poin": 0,
      "total_transaksi": 0
    }
  }
}
```

### POST /auth/activate

Untuk pelanggan lama yang belum punya PIN. `no_nota` harus milik nomor telepon tersebut.

```json
{
  "no_telp": "081298765432",
  "no_nota": "LAU/20261021/0001",
  "pin": "654321"
}
```

Response sama dengan register. Akun yang sudah punya PIN → `409 AUTH_ALREADY_ACTIVATED`.
Nomor/nota tidak cocok → `422 ACTIVATION_FAILED`.

### POST /auth/login

```json
{ "no_telp": "081298765432", "pin": "654321" }
```

Response sama dengan register. Pesan gagal selalu generik
(`401 AUTH_INVALID_CREDENTIALS`) agar tidak membocorkan nomor terdaftar.

### POST /auth/logout

Tanpa body. Response `204 No Content`. Token tidak bisa dipakai lagi setelahnya.

### GET /me

```json
{
  "data": {
    "id_pelanggan": 12,
    "kode_pelanggan": "PLG012",
    "nama": "Budi Santoso",
    "no_telp": "6281298765432",
    "alamat": "Jl. Merdeka No. 10",
    "poin": 15,
    "total_transaksi": 4
  }
}
```

### PATCH /me

Hanya `nama` dan `alamat` yang diproses. Field lain (termasuk `no_telp`) diabaikan.
Response berisi profil terbaru.

### GET /layanan

```json
{
  "data": [
    { "id_layanan": 1, "nama_layanan": "Cuci Kering", "harga_per_kg": 7000, "estimasi_hari": 2 }
  ]
}
```

Hanya layanan dengan `is_aktif = 1`, diurutkan berdasarkan nama.

### GET /outlet

```json
{
  "data": {
    "nama": "Sparkleen Laundry",
    "no_wa": "6281234567890",
    "alamat": "Jl. Contoh No. 1",
    "jam_buka": "08:00",
    "jam_tutup": "21:00"
  }
}
```

Nilai diambil dari `Config\Outlet`, dapat dioverride lewat `.env` (`outlet.nama`, dst).

### GET /transaksi

Query: `status=aktif|selesai|semua` (default `semua`), `page` (default 1),
`per_page` (default 20, maksimal 50).

`aktif` = `menunggu`, `proses`, `setrika`. `selesai` = `selesai`, `diambil`.

```json
{
  "data": [
    {
      "id_transaksi": 87,
      "no_nota": "LAU/20261021/0001",
      "tgl_masuk": "2026-10-21T09:00:00+07:00",
      "tgl_selesai_estimasi": "2026-10-23T09:00:00+07:00",
      "total_berat": 3.5,
      "grand_total": 24500,
      "status": "proses",
      "status_label": "Dicuci"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 1, "last_page": 1 }
}
```

### GET /transaksi/{id}

`{id}` adalah `id_transaksi` numerik, bukan `no_nota`.

```json
{
  "data": {
    "id_transaksi": 87,
    "no_nota": "LAU/20261021/0001",
    "tgl_masuk": "2026-10-21T09:00:00+07:00",
    "tgl_selesai_estimasi": "2026-10-23T09:00:00+07:00",
    "tgl_selesai_aktual": null,
    "total_berat": 3.5,
    "total_biaya": 24500,
    "diskon": 0,
    "grand_total": 24500,
    "status": "proses",
    "status_label": "Dicuci",
    "status_pembayaran": "belum",
    "metode_pembayaran": null,
    "pin_pengambilan": "4821",
    "items": [
      {
        "id_detail": 1,
        "id_layanan": 1,
        "nama_layanan": "Cuci Kering",
        "berat": 3.5,
        "harga_satuan": 7000,
        "subtotal": 24500
      }
    ],
    "pembayaran": [
      { "id_pembayaran": 1, "tgl_bayar": "2026-10-21T09:15:00+07:00", "nominal_bayar": 24500, "metode": "cash", "status": "lunas" }
    ],
    "timeline": [
      { "status": "menunggu", "label": "Diterima", "at": "2026-10-21T09:00:00+07:00", "state": "done" },
      { "status": "proses", "label": "Dicuci", "at": "2026-10-21T13:00:00+07:00", "state": "current" },
      { "status": "setrika", "label": "Disetrika", "at": null, "state": "pending" },
      { "status": "selesai", "label": "Siap Diambil", "at": null, "state": "pending" },
      { "status": "diambil", "label": "Selesai", "at": null, "state": "pending" }
    ]
  }
}
```

`state` bernilai `done`, `current`, atau `pending`. `at` diambil dari `tb_status_log`
(null bila belum terjadi).

### GET /transaksi/{id}/nota

Data terstruktur untuk render nota digital. **Tidak** memuat `pin_pengambilan`.

```json
{
  "data": {
    "outlet": { "nama": "Sparkleen Laundry", "no_wa": "6281234567890", "alamat": "Jl. Contoh No. 1" },
    "no_nota": "LAU/20261021/0001",
    "tanggal": "2026-10-21T09:00:00+07:00",
    "items": [
      { "id_detail": 1, "id_layanan": 1, "nama_layanan": "Cuci Kering", "berat": 3.5, "harga_satuan": 7000, "subtotal": 24500 }
    ],
    "subtotal": 24500,
    "diskon": 0,
    "grand_total": 24500,
    "metode": "cash",
    "status_pembayaran": "belum"
  }
}
```

## Kode error

| HTTP | Code | Arti |
|---|---|---|
| 401 | `AUTH_REQUIRED` | Header `Authorization` tidak ada / format salah |
| 401 | `AUTH_INVALID_TOKEN` | Token tidak dikenal, sudah dicabut, atau kedaluwarsa |
| 401 | `AUTH_INVALID_CREDENTIALS` | Nomor telepon atau PIN salah |
| 403 | `ACCOUNT_INACTIVE` | Akun dinonaktifkan kasir/admin |
| 404 | `NOT_FOUND` | Transaksi tidak ada atau bukan milik pelanggan |
| 409 | `PHONE_TAKEN` | Nomor telepon sudah terdaftar |
| 409 | `AUTH_NOT_ACTIVATED` | Akun belum punya PIN, harus aktivasi |
| 409 | `AUTH_ALREADY_ACTIVATED` | Aktivasi ulang padahal PIN sudah ada |
| 422 | `VALIDATION_ERROR` | Input tidak valid, lihat `error.fields` |
| 422 | `ACTIVATION_FAILED` | Kombinasi nomor telepon + nomor nota tidak cocok |
| 429 | `AUTH_BLOCKED` | Terlalu banyak percobaan login gagal |
| 500 | `INTERNAL_ERROR` | Kesalahan server |

## Rate limit login

- Maksimal 5 percobaan gagal per kombinasi IP + nomor telepon.
- Setelah melewati batas, login dikunci selama 60 detik
  (`Config\AuthThrottle::$maxAttempts` dan `$lockoutSeconds`).
- Response `429` menyertakan `error.fields.retry_after` berisi sisa detik.

## Catatan implementasi

- Path memakai ID numerik karena `no_nota` mengandung `/` yang ditolak Apache.
- `tb_transaksi` tidak diubah strukturnya; API hanya membaca.
- Migrasi yang ditambahkan: kolom PIN/login pada `tb_pelanggan` dan tabel `tb_api_token`.
- Reset PIN dilakukan kasir dari web (`POST /pelanggan/reset-pin/{id}`), lalu pelanggan
  aktivasi ulang memakai nomor nota terakhir.
