# Sparkleen Mobile API v1

> Status implementasi 9 November 2026: fondasi 11 endpoint akun/profil/katalog/outlet/transaksi/nota diterapkan pada branch backend `feat/customer-api-foundation` dari `524f554`. Bagian `/permintaan` dan `/transaksi/{id}/pembayaran` di dokumen ini adalah rencana berikutnya, **belum tersedia** pada implementasi fondasi tersebut. Contoh dan catatan fase pembayaran di bawah tidak boleh dianggap sebagai hasil uji backend yang sedang berjalan. Lihat `docs/integration-foundation-results.md` untuk bukti dan batas verifikasi.

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
| POST | `/transaksi/{id}/pembayaran/batal` | Bearer | Batalkan intent pembayaran online |

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

Mengajukan permintaan jemput. Satu pelanggan hanya boleh punya **satu** permintaan
berstatus `menunggu`.

Body:

```json
{
  "id_layanan": 1,
  "berat_perkiraan": 4.5,
  "alamat_jemput": "Jl. Melati No. 7, RT 2",
  "tgl_jemput": "2026-10-25",
  "slot_jemput": "siang",
  "catatan": "Cuci pisah dengan handuk"
}
```

| Field | Tipe | Wajib | Aturan di server |
|---|---|---|---|
| `id_layanan` | int | ya | numerik; layanan harus ada dan `is_aktif = 1` |
| `berat_perkiraan` | number | ya | > 0 dan ≤ 100; disimpan dibulatkan ke 2 desimal (pesan error menyebut "0.1 dan 100 kg") |
| `alamat_jemput` | string | ya | minimal 10 karakter setelah `trim` |
| `tgl_jemput` | string `YYYY-MM-DD` | ya | tanggal valid, tidak boleh di masa lalu |
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
    "tgl_jemput": "2026-10-25T12:00:00+07:00",
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
`POST /permintaan/{id}/batal`. `status` yang mungkin dilihat klien: `menunggu`,
`dikonfirmasi`, `ditolak`, `dibatalkan`. State internal kasir `diproses` sengaja
dinormalkan menjadi `menunggu` — bagi pelanggan belum ada yang berubah.
`alasan_penolakan` hanya terisi saat `ditolak`.

Error:

| HTTP | Code | Kondisi |
|---|---|---|
| 422 | `VALIDATION_ERROR` | Salah satu aturan tabel di atas gagal; `error.fields` memakai nama field yang sama |
| 422 | `VALIDATION_ERROR` | `id_layanan` tidak ada atau tidak aktif → `error.fields.id_layanan = ["Layanan tidak tersedia."]` |
| 409 | `ACTIVE_REQUEST_EXISTS` | Masih ada permintaan `menunggu` milik pelanggan ini |

### GET /permintaan

Query: `status=aktif|selesai|semua` (default `semua`; nilai lain diperlakukan sebagai
`semua`), `page` (default 1), `per_page` (default 20, maksimal 50).

`aktif` = `menunggu`, `diproses`, `dikonfirmasi`. `selesai` = `ditolak`, `dibatalkan`.

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
      "tgl_jemput": "2026-10-25T12:00:00+07:00",
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

Tanpa body. Hanya permintaan berstatus `menunggu` yang bisa dibatalkan; pembatalannya
atomik (satu `UPDATE` dengan predikat status), jadi dua tap cepat tetap menghasilkan
satu pembatalan dan permintaan tidak pernah singgah di status `diproses`.

Response `200` berisi objek permintaan dengan `status` sudah menjadi `dibatalkan`.

| HTTP | Code | Kondisi |
|---|---|---|
| 404 | `NOT_FOUND` | Permintaan tidak ada atau bukan milik pelanggan pemilik token |
| 409 | `CANNOT_CANCEL` | Status sudah bukan `menunggu` (sudah diproses/dikonfirmasi/ditolak/dibatalkan) |
| 409 | `CANNOT_CANCEL` | Kasir mengambil permintaan di antara baca dan update ("Permintaan sudah sedang diproses.") — permintaan tetap utuh |

### POST /transaksi/{id}/pembayaran

Membuka tagihan online untuk sisa tagihan transaksi. `{id}` = `id_transaksi` numerik.

Body:

```json
{ "metode": "QRIS" }
```

Hanya `metode` yang dibaca. Nilainya `QRIS` atau `TRANSFER` (server meng-`trim` lalu
`strtoupper`, jadi `qris`/`transfer` juga diterima). **Nominal tidak dikirim klien** —
server menghitung sendiri `sisa_tagihan` dan memakai angka itu sebagai nominal intent.

Response `201` berisi objek intent berstatus `PENDING` (bentuk lengkapnya di
`GET /transaksi/{id}/pembayaran`):

```json
{
  "data": {
    "status": "PENDING",
    "metode": "QRIS",
    "nominal": 21000,
    "total_dibayar": 0,
    "sisa": 21000,
    "status_pembayaran": "belum",
    "expired_at": "2026-10-24T12:15:00+07:00",
    "payment_detail": {
      "qris_data": "<string payload QRIS dari Payment API>",
      "merchant_name": "Sparkleen",
      "expired_at": "2026-10-24T12:15:00+07:00",
      "metode": "QRIS"
    }
  }
}
```

`payment_detail` adalah objek mentah dari Payment API (untuk QRIS berisi payload QRIS,
untuk TRANSFER rekening tujuan) plus `expired_at` dan `metode` yang ditempel server.
`transaction_id` dari provider **tidak** dikembalikan ke klien.

Perilaku:

- Transaksi fresh (`NONE`) → intent baru, `201`.
- Sudah ada intent `PENDING` dengan metode yang sama → intent yang ada dikirim ulang
  apa adanya, `200`, tanpa memanggil Payment API (idempoten).
- Sudah ada intent `PENDING` metode lain → `409 CONFLICT_METHOD`; batalkan dulu.
- Intent `EXPIRED` **tidak** otomatis berganti jadi intent baru. `payment_ref` intent
  yang kedaluwarsa masih terisi (tidak ada yang membersihkannya otomatis), sedangkan
  klaim atomik saat menyimpan intent baru mensyaratkan `payment_ref` kosong. Hasilnya:
  `200` berisi intent lama yang tetap `EXPIRED`, bukan `201`. Untuk membuka ulang:
  panggil `POST /transaksi/{id}/pembayaran/batal` lebih dulu, lalu `POST` yang sama untuk
  mendapatkan intent baru (`201`).
- Kasir membuka intent bersamaan sehingga klaim atomik kalah → `200` berisi intent yang
  sedang aktif, bukan error.

| HTTP | Code | Kondisi |
|---|---|---|
| 404 | `NOT_FOUND` | Transaksi tidak ada atau bukan milik pelanggan |
| 422 | `VALIDATION_ERROR` | `metode` kosong / bukan `QRIS` atau `TRANSFER` (`error.fields.metode`) |
| 409 | `ALREADY_PAID` | `sisa_tagihan` sudah `0` |
| 409 | `CONFLICT_METHOD` | Ada intent `PENDING` metode berbeda |
| 502 | `PAYMENT_API_UNAVAILABLE` | Payment API mati / menolak / belum dikonfigurasi (`PAYMENT_API_URL` atau `PAYMENT_API_KEY` kosong) |

### GET /transaksi/{id}/pembayaran

Endpoint polling status tagihan online. Isinya **murni dibaca dari DB lokal** — tidak ada
pemanggilan ke Payment API sama sekali, sehingga latency dan matinya provider tidak
membuat layar status error. `status` hanya berganti karena dua hal: app sendiri membuat
atau membatalkan intent, atau webhook `POST /webhook/payment` mencatat pembayaran.
Lunasnya hanya lewat webhook — lihat "Cara intent menjadi lunas".

`status` selalu salah satu dari `NONE`, `PENDING`, `EXPIRED`, `SUCCESS`, dan **kedelapan
key selalu ada** pada setiap status (perbedaannya hanya nilainya).

`NONE` — belum pernah ada intent, atau intent dibatalkan (contoh ini transaksi yang belum
pernah dibuka intent, sehingga `metode` masih `null`):

```json
{
  "data": {
    "status": "NONE",
    "metode": null,
    "nominal": 21000,
    "total_dibayar": 0,
    "sisa": 21000,
    "status_pembayaran": "belum",
    "expired_at": null,
    "payment_detail": {}
  }
}
```

`PENDING` — intent aktif, bayar sekarang:

```json
{
  "data": {
    "status": "PENDING",
    "metode": "QRIS",
    "nominal": 21000,
    "total_dibayar": 0,
    "sisa": 21000,
    "status_pembayaran": "belum",
    "expired_at": "2026-10-24T12:15:00+07:00",
    "payment_detail": { "qris_data": "<payload QRIS>", "expired_at": "...", "metode": "QRIS" }
  }
}
```

`EXPIRED` — bentuknya sama persis dengan `PENDING`, hanya `status` yang berganti, yaitu
ketika `expired_at` sudah lewat sedangkan intent-nya belum dibatalkan:

```json
{
  "data": {
    "status": "EXPIRED",
    "metode": "TRANSFER",
    "nominal": 15000,
    "total_dibayar": 6000,
    "sisa": 15000,
    "status_pembayaran": "belum",
    "expired_at": "2026-10-24T11:00:00+07:00",
    "payment_detail": { "bank_name": "Bank BCA", "account_number": "1234567890", "metode": "TRANSFER" }
  }
}
```

`SUCCESS` — sisa tagihan sudah `0`:

```json
{
  "data": {
    "status": "SUCCESS",
    "metode": "qris",
    "nominal": 21000,
    "total_dibayar": 21000,
    "sisa": 0,
    "status_pembayaran": "lunas",
    "expired_at": null,
    "payment_detail": {}
  }
}
```

Arti tiap key:

| Key | Tipe | Keterangan |
|---|---|---|
| `status` | string | `NONE` \| `PENDING` \| `EXPIRED` \| `SUCCESS` |
| `metode` | string\|null | `QRIS`/`TRANSFER` selama intent masih ada (diambil dari `payment_detail`); kalau `payment_detail` sudah dikosongkan — oleh webhook maupun oleh pembatalan — jatuh ke metode transaksi sehingga bernilai `cash`/`qris`/`transfer` huruf kecil, atau `null` |
| `nominal` | int | rupiah yang masih harus dibayar sekarang (= `sisa`) |
| `total_dibayar` | int | rupiah yang sudah tercatat di `tb_pembayaran` |
| `sisa` | int | `grand_total - total_dibayar`, nilai negatif dipotong ke `0` |
| `status_pembayaran` | string | `belum` \| `cicil` \| `lunas` dari master status |
| `expired_at` | string\|null | ISO-8601 batas waktu intent; `null` pada `NONE` dan setelah webhook |
| `payment_detail` | object | mentah dari Payment API; `{}` kalau tidak ada intent |

Cara baca di app: `SUCCESS` → bayar selesai; `PENDING` → tampilkan `payment_detail` +
`expired_at` dan jalankan polling; `EXPIRED` → tawarkan "coba lagi", yang harus memanggil
`POST /transaksi/{id}/pembayaran/batal` lalu `POST /transaksi/{id}/pembayaran` (POST ulang
tanpa pembatalan hanya mengembalikan `EXPIRED`, lihat di atas); `NONE` → tampilkan pilihan
metode. Status `SUCCESS` diperiksa lebih dulu daripada `payment_ref`, karena webhook
mengosongkan `payment_ref` tepat setelah mencatat pembayaran — tanpa urutan itu,
pembayaran yang barusan sukses akan kelihatan sebagai `NONE`.

Satu-satunya error endpoint ini adalah `404 NOT_FOUND` (transaksi tidak ada / bukan
milik pelanggan).

### POST /transaksi/{id}/pembayaran/batal

Tanpa body. Mengosongkan `payment_ref` dan `payment_detail` transaksi, lalu mencoba
membatalkan intent di Payment API. Pembatalan ke provider bersifat best-effort: kalau
provider mati, tagihan lokal tetap batal dan response tetap `200`.

Response `200` berisi objek intent yang sudah kembali ke `NONE` (`sisa` tetap sebesar
tagihan yang belum dibayar):

```json
{
  "data": {
    "status": "NONE",
    "metode": "qris",
    "nominal": 21000,
    "total_dibayar": 0,
    "sisa": 21000,
    "status_pembayaran": "belum",
    "expired_at": null,
    "payment_detail": {}
  }
}
```

`metode` di sini bukan `null`: pembatalan hanya mengosongkan `payment_ref` dan
`payment_detail`, sedangkan `id_metode_pembayaran` yang ditulis saat intent dibuat tetap
tinggal (untuk intent QRIS nilainya `qris` — huruf kecil, dari master metode). `null` hanya
muncul kalau transaksi belum pernah punya metode.

| HTTP | Code | Kondisi |
|---|---|---|
| 404 | `NOT_FOUND` | Transaksi tidak ada atau bukan milik pelanggan |
| 409 | `NO_ACTIVE_PAYMENT` | Tidak ada tagihan online yang berjalan (`payment_ref` kosong) |
| 409 | `NO_ACTIVE_PAYMENT` | `payment_ref` sudah diganti/dikosongkan pihak lain sejak dibaca ("Tagihan sudah diproses.") — pembatalan ditolak supaya tidak menghapus intent orang lain |

## Cara intent menjadi lunas

Untuk pembayaran online, satu-satunya penulis `tb_pembayaran` (dan status `lunas`/`cicil`
pada transaksi) adalah **webhook ber-HMAC** `POST /webhook/payment` (`Webhook::payment()`)
— dipanggil Payment API, bukan aplikasi. Tidak ada satu pun route mobile API yang
menyisipkan pembayaran atau menandai lunas; pembayaran tunai tetap tercatat dari web kasir,
di luar API ini. Verifikasinya: header `X-Signature` dibandingkan dengan
`hash_hmac('sha256', raw body, PAYMENT_API_KEY)` lewat `hash_equals`, dan callback ganda
ditolak lewat klaim atomik (`payment_ref` dikosongkan lebih dulu dalam transaksi yang
sama; kalau tidak ada baris yang terkena, callback dianggap sudah diproses).

Konsekuensinya bagi app:

- **Tidak ada endpoint "sudah bayar"** dan tidak boleh ada tombolnya di UI. Klien tidak
  pernah bisa menyatakan dirinya lunas.
- App cukup **polling `GET /transaksi/{id}/pembayaran`** dan menganggap pembayaran sukses
  saat `status == "SUCCESS"`, yang berarti `sisa <= 0`. `GET /transaksi/{id}` dengan
  `sisa_tagihan == 0` adalah sumber kebenaran yang sama.
- Sebelum webhook sempat masuk, status masih `PENDING` walaupun uang sudah dibayar.
  Tampilkan "menunggu konfirmasi pembayaran", jangan langsung menandai lunas.
- Webhook juga mengosongkan `payment_ref`, jadi setelah lunas intent tidak bisa dibatalkan
  lagi dan `payment_detail` ikut kosong.

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
| 409 | `ACTIVE_REQUEST_EXISTS` | Masih ada permintaan jemput `menunggu` untuk pelanggan ini |
| 409 | `CANNOT_CANCEL` | Permintaan hanya bisa dibatalkan selama belum diproses kasir |
| 409 | `ALREADY_PAID` | Tagihan transaksi sudah lunas, intent tidak dibuat |
| 409 | `CONFLICT_METHOD` | Intent `PENDING` metode lain masih berjalan; batalkan dulu |
| 409 | `NO_ACTIVE_PAYMENT` | Tidak ada tagihan online yang berjalan / sudah diproses pihak lain |
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

- Path memakai ID numerik karena `no_nota` mengandung `/` yang ditolak Apache. Berlaku juga
  untuk `/permintaan/{id}`, `/permintaan/{id}/batal`, dan seluruh route pembayaran.
- `tb_transaksi` tidak diubah strukturnya; API hanya membaca. Pembayaran online memakai
  kolom yang sudah ada (`payment_ref`, `payment_detail`, `id_metode_pembayaran`), dan
  `expired_at` dititipkan di dalam JSON `payment_detail` — bukan kolom baru.
- Migrasi yang ditambahkan: kolom PIN/login pada `tb_pelanggan`, tabel `tb_api_token`, dan
  tabel `tb_permintaan_pesanan` (FK ke pelanggan, layanan, transaksi, serta kasir yang
  mengonfirmasi).
- Reset PIN dilakukan kasir dari web (`POST /pelanggan/reset-pin/{id}`), lalu pelanggan
  aktivasi ulang memakai nomor nota terakhir.

### Nilai uang dan rahasia pembayaran

- **Tidak ada satu pun endpoint yang menerima nominal dari klien.** `POST /permintaan`
  hanya menerima `berat_perkiraan` dan harga dihitung server dari `harga_per_kg` layanan
  (`estimasi_harga`). `POST /transaksi/{id}/pembayaran` hanya membaca `metode`; nominal
  intent diambil dari `sisa_tagihan = grand_total - SUM(tb_pembayaran.nominal_bayar)`
  hasil hitung server. Field lain di body diabaikan, sehingga app tidak bisa
  memengaruhi — apalagi menentukan — angka yang harus dibayar.
- **`PAYMENT_API_KEY` tidak pernah meninggalkan server.** `PaymentApiService` membacanya
  dari `.env` untuk header ke Payment API, dan `Webhook::payment()` memakainya sebagai
  secret HMAC. Key tidak pernah masuk response, tidak pernah ditulis ke `payment_detail`,
  dan tidak pernah muncul di log. Message `PaymentApiException` (termasuk isi mentah dari
  hulu) hanya masuk `log_message('error', ...)`, sementara klien selalu menerima pesan
  generik `"Payment API tidak dapat dihubungi. Coba lagi sebentar."` dengan code
  `PAYMENT_API_UNAVAILABLE` — termasuk ketika provider menolak permintaan atau ketika
  `PAYMENT_API_URL`/`PAYMENT_API_KEY` belum diset.
- `transaction_id` / `payment_ref` provider tidak diekspos ke klien; app hanya melihat
  bentuk intent yang sudah dinormalalkan (`status`, `nominal`, `sisa`, `expired_at`,
  `payment_detail`).
- Klien tidak punya jalur untuk menulis `tb_pembayaran`: pembayarannya dicatat webhook,
  dan kasir bisa mencatat pembayaran manual dari web.
