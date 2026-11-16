# Sparkleen Mobile API v1

> Status implementasi 10 November 2026: API pelanggan, permintaan jemput/antrean kasir, dan pembayaran pelanggan tersedia lokal pada `feat/customer-payments`. Pembayaran tetap SIMULATION, pembuatan default nonaktif. Notifikasi in-app dan penukaran poin dilanjutkan pada `feat/notifications-loyalty`; push OS belum tersedia. Belum push/deploy. Lihat `docs/customer-payments.md` dan `docs/notifications-and-points.md`.

REST API untuk aplikasi mobile pelanggan Sparkleen Laundry. Hanya berisi kebutuhan
pelanggan (auth, profil, katalog, transaksi, nota, permintaan jemput, pembayaran online,
info outlet). Data karyawan, inventaris, dan laporan tetap di web kasir.

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
- PIN login dan hash tidak dikembalikan API. Token hanya dikirim saat autentikasi; PIN/token/hash tidak boleh ditulis ke log. PIN pengambilan hanya tersedia di detail transaksi milik pelanggan.

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
- Endpoint transaksi dan permintaan hanya mengembalikan data milik pelanggan pemilik token.
  ID milik pelanggan lain menghasilkan `404 NOT_FOUND` (bukan 403).
- Nominal uang selalu dihitung server; tidak ada endpoint yang menerima angka rupiah dari
  klien (lihat Catatan implementasi).

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
| GET | `/transaksi/{id}` | Bearer | Detail + item + timeline + sisa tagihan + PIN pengambilan |
| GET | `/transaksi/{id}/nota` | Bearer | Data nota digital (tanpa PIN pengambilan) |
| POST | `/permintaan` | Bearer | Buat permintaan jemput baru |
| GET | `/permintaan` | Bearer | Daftar permintaan jemput (pagination) |
| GET | `/permintaan/{id}` | Bearer | Detail satu permintaan |
| POST | `/permintaan/{id}/batal` | Bearer | Batalkan permintaan yang masih menunggu |
| POST | `/transaksi/{id}/pembayaran` | Bearer | Buat / ambil ulang intent pembayaran online |
| GET | `/transaksi/{id}/pembayaran` | Bearer | Status tagihan online (polling) |
| POST | `/transaksi/{id}/pembayaran/sinkronisasi` | Bearer | Periksa gateway dan rekonsiliasi status bertanda tangan |
| POST | `/transaksi/{id}/pembayaran/batal` | Bearer | Batalkan intent pembayaran online |

### Notifikasi dan loyalitas (tahap 4)

Semua endpoint memerlukan bearer pelanggan. Data difilter berdasarkan akun token.

| Method | Path | Hasil/body |
|---|---|---|
| GET | `/notifikasi` | List + meta page/last_page/unread_count/latest_id |
| GET | `/notifikasi/ringkasan` | unread_count/latest_id |
| POST | `/notifikasi/{id}/baca` | Tanpa body; idempotent |
| POST | `/notifikasi/baca-semua` | `{"through_id":123}`; hanya sampai cutoff |
| GET | `/loyalitas` | balance, point_value, history; pagination meta |
| GET | `/transaksi/{id}/poin` | Preview order_id/no_nota/balance/grand_total/earned_points/max_points/can_redeem/reason/redemption |
| POST | `/transaksi/{id}/poin` | `{"points":20,"expected_grand_total":35000,"request_id":"client-random-key-16-to-64"}`; response preview 200 |

Nilai poin Rp300, final dihitung server. Penukaran sekali/order, sebelum pembayaran
pertama, belum diambil, tanpa referensi/attempt online. Total yang berubah 409
ORDER_CHANGED; saldo/syarat berubah 409 POINTS_UNAVAILABLE; reuse key dengan isi
berbeda 409 IDEMPOTENCY_CONFLICT. Retry identik tidak mengurangi poin kedua kali.
Penyesuaian earned akibat grand total turun ditampilkan pada konfirmasi/riwayat.

Notifikasi adalah inbox tersimpan, bukan push OS. Item: id, category, title, body,
target_type (order/pickup/loyalty), target_id nullable, read_at, created_at. Tidak
memuat PIN atau URL bebas. Riwayat poin berisi id, order_id, no_nota, delta,
balance_after, reason, created_at; hanya event sejak fitur diaktifkan. Lihat
`docs/notifications-and-points.md` untuk pengalaman pengguna dan batas pengujian.

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
    "expires_at": "2026-11-22T10:00:00+07:00",
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

Untuk pelanggan lama yang belum punya PIN. `no_nota` harus merupakan nota terakhir yang belum dihapus milik nomor telepon tersebut.

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

Nilai diambil dari `Config\Outlet`, dapat dioverride lewat `.env` (`outlet.nama`, `outlet.noWa`, `outlet.alamat`, `outlet.jamBuka`, `outlet.jamTutup`).

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
    "sisa_tagihan": 24500,
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

`sisa_tagihan` (integer rupiah, tidak pernah negatif) adalah `grand_total` dikurangi total
`nominal_bayar` di `tb_pembayaran`. Nilainya `0` berarti transaksi sudah lunas — layar
pembayaran cukup memakai field ini, tanpa memanggil endpoint pembayaran.

`pembayaran[]` berisi riwayat yang sudah tercatat: `id_pembayaran`, `tgl_bayar` (ISO-8601),
`nominal_bayar` (int rupiah), `metode` (`cash` / `qris` / `transfer`), dan `status`
(`lunas` bila sisa setelah pembayaran itu `<= 0`, selain itu `cicil`). `items[]` berisi
`id_detail`, `id_layanan`, `nama_layanan`, `berat` (float kg), `harga_satuan`, `subtotal`
(int rupiah).

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

### POST /permintaan

Contoh tanggal harus diganti dengan slot yang belum lewat; koleksi Postman menyiapkan tanggal besok WIB secara otomatis.

Mengajukan permintaan jemput. Satu pelanggan hanya boleh punya **satu** permintaan
berstatus `menunggu` atau `diproses` (belum menjadi transaksi).

Body:

```json
{
  "id_layanan": 1,
  "berat_perkiraan": 4.5,
  "alamat_jemput": "Jl. Melati No. 7, RT 2",
  "tgl_jemput": "2026-11-11",
  "slot_jemput": "siang",
  "catatan": "Cuci pisah dengan handuk"
}
```

| Field | Tipe | Wajib | Aturan di server |
|---|---|---|---|
| `id_layanan` | int | ya | JSON integer positif; layanan harus ada dan `is_aktif = 1` |
| `berat_perkiraan` | number | ya | 0,1–100 kg; disimpan dibulatkan ke 2 desimal |
| `alamat_jemput` | string | ya | 10–500 karakter setelah `trim` |
| `tgl_jemput` | string `YYYY-MM-DD` | ya | tanggal valid, hingga 30 hari ke depan; slot WIB harus belum lewat |
| `slot_jemput` | string | ya | `pagi` \| `siang` \| `sore` |
| `catatan` | string | tidak | maksimal 255 karakter; kosong disimpan sebagai `null` |

Slot menentukan jam penjemputan yang ditulis server ke `tgl_jemput`: `pagi` = 08:00,
`siang` = 12:00, `sore` = 15:00. Karena itu `tgl_jemput` pada response selalu berupa
datetime ISO-8601, bukan tanggal polos.

Response `201`:

```json
{
  "data": {
    "id_permintaan": 12,
    "status": "menunggu",
    "id_layanan": 1,
    "nama_layanan": "Cuci Kering",
    "berat_perkiraan": 4.5,
    "estimasi_harga": 31500,
    "alamat_jemput": "Jl. Melati No. 7, RT 2",
    "tgl_jemput": "2026-11-11T12:00:00+07:00",
    "slot_jemput": "siang",
    "catatan": "Cuci pisah dengan handuk",
    "estimasi_hari": 2,
    "id_transaksi": null,
    "alasan_penolakan": null,
    "created_at": "2026-10-24T10:02:00+07:00"
  }
}
```

`estimasi_harga` dihitung server: `harga_per_kg × berat_perkiraan`, dibulatkan ke integer
rupiah. `estimasi_hari` diambil dari layanan. `id_transaksi` terisi setelah kasir
mengonfirmasi dan pesanan jadi transaksi nyata; selama itu `null`.

Objek permintaan juga dipakai `GET /permintaan`, `GET /permintaan/{id}`, dan
`POST /permintaan/{id}/batal`. Status publik: `menunggu`, `diproses`, `dikonfirmasi`,
`ditolak`, `dibatalkan`. Status `diproses` ditampilkan tersendiri agar pelanggan
mengetahui penjemputan sudah ditangani kasir.
`alasan_penolakan` hanya terisi saat `ditolak`.

Error:

| HTTP | Code | Kondisi |
|---|---|---|
| 422 | `VALIDATION_ERROR` | Salah satu aturan tabel di atas gagal; `error.fields` memakai nama field yang sama |
| 422 | `VALIDATION_ERROR` | `id_layanan` tidak ada atau tidak aktif → `error.fields.id_layanan = ["Layanan tidak tersedia."]` |
| 409 | `ACTIVE_REQUEST_EXISTS` | Masih ada permintaan `menunggu`/`diproses` milik pelanggan ini |

### GET /permintaan

Query: `status=aktif|selesai|semua` (default `semua`), `page` (default 1, maksimal 1.000.000), `per_page` (default 20, maksimal 50). Filter/pagination yang tidak valid menghasilkan 422.

`aktif` = `menunggu`, `diproses`. `selesai` = `dikonfirmasi`, `ditolak`, `dibatalkan`. Setelah dikonfirmasi, kelanjutan cucian dipantau lewat `id_transaksi`.

```json
{
  "data": [
    {
      "id_permintaan": 12,
      "status": "menunggu",
      "id_layanan": 1,
      "nama_layanan": "Cuci Kering",
      "berat_perkiraan": 4.5,
      "estimasi_harga": 31500,
      "alamat_jemput": "Jl. Melati No. 7, RT 2",
      "tgl_jemput": "2026-11-11T12:00:00+07:00",
      "slot_jemput": "siang",
      "catatan": "Cuci pisah dengan handuk",
      "estimasi_hari": 2,
      "id_transaksi": null,
      "alasan_penolakan": null,
      "created_at": "2026-10-24T10:02:00+07:00"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 1, "last_page": 1 }
}
```

Diurutkan `id_permintaan` DESC (terbaru dulu). `meta` identik dengan `/transaksi`.

### GET /permintaan/{id}

`{id}` adalah `id_permintaan` numerik. Response `200` berisi satu objek permintaan seperti
di atas. Permintaan milik pelanggan lain atau ID yang tidak dikenal menghasilkan
`404 NOT_FOUND` (bukan 403), sesuai aturan kepemilikan di bagian depan dokumen.

### POST /permintaan/{id}/batal

Tanpa body. Hanya permintaan berstatus `menunggu` yang bisa dibatalkan; pembatalannya atomik dengan lock pelanggan dan permintaan. Pengiriman ulang pembatalan yang sudah berhasil mengembalikan 200 dengan status `dibatalkan`.

Response `200` berisi objek permintaan dengan `status` sudah menjadi `dibatalkan`.

| HTTP | Code | Kondisi |
|---|---|---|
| 404 | `NOT_FOUND` | Permintaan tidak ada atau bukan milik pelanggan pemilik token |
| 409 | `REQUEST_NOT_CANCELLABLE` | Status sudah diproses/dikonfirmasi/ditolak |
| 200 | - | Pengiriman ulang pembatalan yang sebelumnya berhasil |

### Pembayaran pelanggan (tahap 3)

Semua endpoint berikut memerlukan bearer token pelanggan dan kepemilikan transaksi.
Kunci merchant dan `PAYMENT_WEBHOOK_SECRET` hanya berada pada server.

| Method | Path relatif transaksi | Perilaku |
|---|---|---|
| GET | `/{id}/pembayaran` | Snapshot lokal, tanpa panggilan provider |
| POST | `/{id}/pembayaran` | Body `{"metode":"QRIS"}` atau `{"metode":"TRANSFER"}`; response 200 |
| POST | `/{id}/pembayaran/sinkronisasi` | Tanpa body; status gateway bertanda tangan diterapkan ke ledger |
| POST | `/{id}/pembayaran/batal` | Tanpa body; batal hanya setelah provider mengonfirmasi |

Response snapshot:

```json
{"data":{"status":"PENDING","enabled":true,"mode":"SIMULATION","metode":"QRIS","nominal":35000,"total_dibayar":0,"sisa":35000,"status_pembayaran":"belum","expired_at":"2026-11-10T12:15:00Z","payment_detail":{"simulation_code":"<gateway UUID>","qris_data":"<gateway UUID>","qr_image":"data:image/png;base64,..."}}}
```

| Status | Tindakan aplikasi |
|---|---|
| NONE | Pilihan metode jika `enabled`; bayar kasir jika nonaktif |
| PROCESSING | Ulang sinkronisasi menggunakan request key yang tersimpan; jangan buat invoice lain |
| PENDING | QR PNG/kode Smart Pay atau rekening dummy; sinkronisasi setiap 10 detik saat foreground |
| EXPIRED | Sinkronisasi untuk konfirmasi expiry sebelum membuat tagihan berikutnya |
| REVIEW | Tagihan legacy/tidak dikenal; hubungi kasir |
| SUCCESS | Sisa ledger 0; tampilkan lunas dan muat ulang detail/nota |

- `nominal` selalu dihitung server dari grand total dikurangi pembayaran tercatat.
  Client hanya mengirim metode, tidak dapat mengirim nominal/status pembayaran.
- Satu order hanya memiliki satu attempt aktif; metode sama mengembalikan attempt sama,
  metode lain 409. Attempt CREATING tersimpan sebelum HTTP; retry menggunakan
  `Idempotency-Key` yang sama. Timeout tidak membuktikan kegagalan remote.
- Snapshot PENDING mengekspos **QR simulasi berisi UUID**, bukan QRIS bank.
  Transfer selalu `BANK SIMULASI`, `DEMO-NOT-A-BANK-ACCOUNT`; jangan transfer uang nyata.
  Kode simulasi UUID sengaja dapat dibaca Smart Pay. Tidak ada credential di kode.
- `MOBILE_PAYMENTS_ENABLED=false` secara default. Flag mengontrol pembuatan baru;
  status, sinkronisasi, dan pembatalan existing tetap tersedia.
- Pembatalan/ganti metode tidak menghapus intent lokal saat provider timeout. Server
  hanya menutupnya setelah respons CANCELLED/EXPIRED/FAILED terverifikasi. Respons
  SUCCESS saat pembatalan justru dicatat sebagai pembayaran, bukan disamarkan batal.
- Tidak ada tombol/endpoint pelanggan yang bisa menyatakan dirinya sudah membayar.

### Verifikasi gateway dan settlement

Laundry memverifikasi raw response body Payment API dengan header
`X-Webhook-Signature`, HMAC-SHA256 `PAYMENT_WEBHOOK_SECRET` yang terpisah dari
`PAYMENT_API_KEY`. ID gateway, merchant, nota, nominal, metode dan mode harus sesuai.
Webhook memakai header `X-Signature` dengan secret server yang sama.
Webhook dan sinkronisasi menggunakan `PaymentSettlementService` yang sama dengan
lock order, intent, ledger; pengulangan tidak membuat pembayaran kedua. Pembayaran
kas kasir ditolak selama ada tagihan online aktif. Tidak ada fallback menjadi lunas
ketika provider gagal. Retry callback persisten/outbox belum tersedia; pemulihan
foreground mengandalkan sinkronisasi eksplisit.

## Kode error

| HTTP | Code | Arti |
|---|---|---|
| 401 | `AUTH_REQUIRED` | Header `Authorization` tidak ada / format salah |
| 401 | `AUTH_INVALID_TOKEN` | Token tidak dikenal, sudah dicabut, atau kedaluwarsa |
| 401 | `AUTH_INVALID_CREDENTIALS` | Nomor telepon atau PIN salah |
| 403 | `ACCOUNT_INACTIVE` | Akun dinonaktifkan kasir/admin |
| 404 | `NOT_FOUND` | Transaksi/permintaan tidak ada atau bukan milik pelanggan |
| 409 | `PHONE_TAKEN` | Nomor telepon sudah terdaftar |
| 409 | `AUTH_NOT_ACTIVATED` | Akun belum punya PIN, harus aktivasi |
| 409 | `AUTH_ALREADY_ACTIVATED` | Aktivasi ulang padahal PIN sudah ada |
| 409 | `ACTIVE_REQUEST_EXISTS` | Masih ada permintaan jemput `menunggu`/`diproses` untuk pelanggan ini |
| 409 | `CANNOT_CANCEL` | Permintaan hanya bisa dibatalkan selama belum diproses kasir |
| 409 | `ALREADY_PAID` | Tagihan transaksi sudah lunas, intent tidak dibuat |
| 409 | `CONFLICT_METHOD` | Intent `PENDING` metode lain masih berjalan; batalkan dulu |
| 409 | `PAYMENT_REVIEW_REQUIRED` | Referensi pembayaran lama perlu pemeriksaan outlet |
| 502 | `PAYMENT_CONTRACT_MISMATCH` | Respons provider tidak sesuai snapshot tagihan |
| 503 | `PAYMENTS_DISABLED` | Pembuatan pembayaran pelanggan nonaktif |
| 422 | `VALIDATION_ERROR` | Input tidak valid, lihat `error.fields` |
| 422 | `ACTIVATION_FAILED` | Kombinasi nomor telepon + nomor nota tidak cocok |
| 429 | `AUTH_BLOCKED` | Terlalu banyak percobaan login gagal |
| 500 | `INTERNAL_ERROR` | Kesalahan server |
| 502 | `PAYMENT_API_UNAVAILABLE` | Payment API mati, menolak permintaan, atau belum dikonfigurasi |

## Rate limit login

- Maksimal 5 percobaan gagal per kombinasi IP + nomor telepon.
- Setelah melewati batas, login dikunci selama 60 detik
  (`Config\AuthThrottle::$maxAttempts` dan `$lockoutSeconds`).
- Response `429` menyertakan `error.fields.retry_after` berisi sisa detik.

## Catatan implementasi

Path memakai ID numerik karena nota mengandung `/`. API membaca/memperbarui
kolom pembayaran transaksi existing, dan menyimpan snapshot/lifecycle pada
`tb_payment_intent`. Migrasi lifecycle menambah request key, unique active order,
expiry, detail dan mode. Jalankan migrasi sebelum memakai backend baru.
Permintaan jemput memakai `tb_permintaan_jemput`; reset PIN tetap melalui kasir.

Semua nilai uang berupa rupiah integer. `PAYMENT_API_KEY` dipakai untuk autentikasi
server ke gateway; HMAC menggunakan `PAYMENT_WEBHOOK_SECRET` terpisah. Keduanya tidak
masuk response Flutter, source klien, log mentah atau `--dart-define`.
