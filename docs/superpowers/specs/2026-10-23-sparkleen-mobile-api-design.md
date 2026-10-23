# Sparkleen Mobile Pelanggan — Desain Backend + App

Tanggal: 2026-10-23
Status: draft, menunggu persetujuan
Pemilik: Rachmat

## 1. Intent

Aplikasi pelanggan Sparkleen Laundry untuk **satu outlet UMKM** (1–3 orang, 30–80 kg/hari,
pelanggan langganan radius 1–2 km). Bukan multi-cabang, bukan marketplace.

Yang diselesaikan: pelanggan berhenti nanya "cucian saya sudah selesai belum?" lewat WA,
dan nota tidak lagi hilang. Pesanan tetap dibuat kasir seperti sekarang.

## 2. Kenapa companion, bukan order engine

- Harga final ditentukan setelah barang ditimbang kasir. App tidak boleh mengunci harga.
- Jemput-antar di UMKM dinegosiasikan lewat WA, bukan slot waktu yang dijanjikan app.
- Install app adalah friksi besar; fitur yang dipakai tiap hari harus yang nol tambahan
  kerja operasional: lacak status, nota digital, poin.
- Alur order penuh akan memaksa `tb_transaksi.id_kasir` (NOT NULL + FK) diubah dan kasir
  harus menangani antrean baru. Itu risiko ke sistem yang sudah jalan, tanpa manfaat nyata
  untuk satu outlet.

## 3. Scope

### Fase 1 — read-only companion (backend + app inti)
Auth pelanggan, daftar layanan + harga, daftar & detail transaksi milik sendiri,
timeline status, nota digital, poin, profil.

### Fase 2 — permintaan jemput
Pelanggan mengirim permintaan jemput (alamat, tanggal, slot pagi/siang/sore, estimasi kg,
catatan). Kasir mengonfirmasi/menolak di halaman web baru. Bukan order: harga dan berat
tetap ditentukan saat barang diterima.

### Fase 3 — opsional, tidak dikerjakan sekarang
Pembayaran online memakai Payment API Node.js yang sudah ada, push notification (FCM).

**Urutan eksekusi:** fase 1 diselesaikan end-to-end dulu (backend → app → uji di device).
Fase 2 dibuat sebagai plan terpisah setelah fase 1 jalan, supaya migrasi dan UI kasir tidak
tercampur dengan pekerjaan inti.

## 4. Non-goals

- Multi-outlet / multi-cabang.
- Kurir realtime tracking, chat in-app, rating.
- Saldo / topup e-wallet. Tidak ada orang menaruh uang di aplikasi laundry.
- Pelanggan menentukan harga final atau membuat transaksi langsung ke `tb_transaksi`.
- Push notification di fase 1–2 (notifikasi status via WA dan pull-to-refresh).

## 5. Anti-goals

- Merusak atau mengubah alur kasir yang sudah dipakai.
- Mengubah struktur `tb_transaksi`.
- Menyimpan PIN plaintext atau token plaintext di DB.
- Endpoint publik tanpa rate limit.

## 6. Pendekatan yang dipilih

**A. REST API di dalam app CodeIgniter 4 yang sudah ada** (dipilih).
Branch `feature/mobile-api`, route `/api/v1`, controller baru di `app/Controllers/Api/V1/`,
auth token sendiri, model & koneksi DB dipakai ulang. Frontend Flutter repo terpisah.
Alasan: satu sumber data, nol duplikasi logika harga/poin/nota, satu deployment.

Ditolak: B (backend Express/Laravel terpisah — logika bisnis dobel, dua deployment),
C (Supabase/Postgres — dua sumber kebenaran karena kasir tetap di MySQL).

## 7. Backend

### 7.1 Lokasi & struktur

Repo: `C:\Users\R\Documents\@Tugas kampus semester 4\Pemrograman Web\Sparkleen Laundry\sparkleen-laundry`
Branch: `feature/mobile-api`

```
app/Controllers/Api/V1/{Auth,Layanan,Transaksi,Profil,PermintaanJemput}Controller.php
app/Filters/ApiAuthFilter.php
app/Libraries/ApiResponse.php
app/Models/MApiToken.php
app/Models/MPermintaanJemput.php
app/Database/Migrations/*_AddPinToPelanggan.php
app/Database/Migrations/*_CreateApiTokenTable.php
app/Database/Migrations/*_CreatePermintaanJemputTable.php
tests/Api/*.php
docs/api/sparkleen-mobile-v1.md
```

Route group `api/v1` didaftarkan eksplisit; filter `auth`/`role` milik web **tidak** dipakai.

### 7.2 Auth

- Login: `no_telp` + PIN 6 digit. PIN di-hash `password_hash(PASSWORD_DEFAULT)`.
- Token: opaque, 64 hex char, dikirim `Authorization: Bearer <token>`.
  DB menyimpan `sha256(token)`; token asli tidak pernah disimpan.
- Masa berlaku 30 hari, sliding (diperpanjang saat dipakai). Logout = revoke.
- Pelanggan lama buatan kasir (`pin_hash` NULL) melakukan **aktivasi**:
  `no_telp` + `no_nota` terakhir + PIN baru. `no_nota` harus milik nomor itu.
  Alasan: pelanggan lama tidak perlu daftar ulang, dan `no_nota` sudah mereka pegang.
- Rate limit login/aktivasi: 5 percobaan / 15 menit per (no_telp + IP) → 429 + `retry_after`.
- Registrasi baru: nama, no_telp, alamat, PIN. `kode_pelanggan` dari `MPelanggan::generateKode()`,
  `is_aktif = 1`. Nomor sudah terdaftar → 409 `PHONE_TAKEN`.
- Validasi no_telp mengikuti aturan existing: diawali `08` atau `62`.

**Normalisasi nomor.** DB menyimpan nomor apa adanya (kasir bisa mengetik `0812...` atau
`62812...`), sementara unique index bekerja pada string mentah. Semua lookup auth memakai
helper `normalizePhone()` → bentuk `62...`, lalu query mencocokkan **kedua bentuk**
(`62...` dan `08...`). Tidak ada backfill data lama. Registrasi memeriksa duplikat dengan
cara yang sama, jadi `0812...` tidak bisa mendaftar dua kali sebagai `62812...`.

**Lupa PIN.** Tanpa jalur reset, pelanggan yang lupa PIN terkunci permanen. Solusi yang
dipakai: kasir bisa **Reset PIN** dari halaman data pelanggan (role `admin,kasir`), yang
menghapus `pin_hash` dan mencatat aksi ke `tb_log_aktivitas`. Pelanggan lalu melakukan
aktivasi ulang lewat `no_nota` terakhir. Tidak ada PIN sementara lewat WA. **Disetujui pemilik.**

**PIN pengambilan.** `tb_transaksi.pin_pengambilan` (4 digit) saat ini dikirim lewat WA.
App menampilkannya di detail transaksi aktif dengan pola **tap-to-reveal**, agar bisa
menggantikan nota kertas, dan tidak pernah muncul di response list. **Disetujui pemilik.**

**Info outlet.** Nomor WA publik, alamat, dan jam operasional dibaca dari config/env baru
(`Config\Outlet`), bukan hardcode di Flutter, supaya bisa diubah tanpa rebuild app.

### 7.3 Perubahan skema

`tb_pelanggan` (hanya kolom nullable, aman untuk data existing):
```
pin_hash       VARCHAR(255) NULL
pin_set_at     DATETIME     NULL
last_login_at  DATETIME     NULL
```

`tb_api_token` (baru):
```
id_token      INT PK AI
id_pelanggan  INT NOT NULL FK -> tb_pelanggan ON DELETE CASCADE
token_hash    CHAR(64) UNIQUE
device_name   VARCHAR(100) NULL
last_used_at  DATETIME NULL
expires_at    DATETIME NOT NULL
revoked_at    DATETIME NULL
created_at    DATETIME NULL
INDEX (id_pelanggan)
```

`tb_permintaan_jemput` (baru, fase 2):
```
id              INT PK AI
no_referensi    VARCHAR(20) UNIQUE        -- JMK/YYYYMMDD/0001
id_pelanggan    INT NOT NULL FK -> tb_pelanggan
alamat          TEXT NOT NULL
catatan         TEXT NULL
tgl_diminta     DATE NOT NULL
slot            ENUM('pagi','siang','sore') NOT NULL
estimasi_berat  DECIMAL(6,2) NULL
status          ENUM('baru','dikonfirmasi','dijemput','dibatalkan','selesai') DEFAULT 'baru'
id_kasir        INT NULL FK -> tb_karyawan
alasan_batal    VARCHAR(255) NULL
created_at, updated_at DATETIME NULL
```

`tb_transaksi` **tidak disentuh**.

### 7.4 Endpoint fase 1

| Method | Path | Keterangan |
|---|---|---|
| POST | `/api/v1/auth/register` | nama, no_telp, alamat, pin |
| POST | `/api/v1/auth/activate` | no_telp, no_nota, pin (pelanggan lama) |
| POST | `/api/v1/auth/login` | no_telp, pin → token |
| POST | `/api/v1/auth/logout` | revoke token aktif |
| GET | `/api/v1/me` | profil + ringkasan (poin, total transaksi) |
| PATCH | `/api/v1/me` | nama, alamat |
| GET | `/api/v1/layanan` | layanan aktif: id, nama, harga_per_kg, estimasi_hari |
| GET | `/api/v1/transaksi` | `?status=aktif\|selesai&page=&per_page=20` |
| GET | `/api/v1/transaksi/{id}` | detail + item + status log + ringkasan pembayaran |
| GET | `/api/v1/transaksi/{id}/nota` | data nota terstruktur (untuk render di app) |
| GET | `/api/v1/outlet` | nama outlet, nomor WA publik, alamat, jam operasional |

**Path memakai `id_transaksi` numerik, bukan `no_nota`.** `no_nota` berformat
`LAU/YYYYMMDD/NNNN` dan mengandung `/`, yang ditolak Apache sebelum sampai ke CodeIgniter
(`%2F` → 404). `no_nota` tetap dikembalikan sebagai field dan dipakai di body request aktivasi.
Karena `tb_transaksi.no_nota` tidak punya unique index, lookup aktivasi memakai kombinasi
`no_telp` + `no_nota` dan mengambil baris terbaru.

Semua endpoint transaksi hanya mengembalikan data milik `id_pelanggan` pada token. ID milik
orang lain → 404 (bukan 403, agar tidak membocorkan keberadaan nota).

### 7.5 Endpoint fase 2

| Method | Path | Keterangan |
|---|---|---|
| POST | `/api/v1/permintaan-jemput` | alamat, tgl_diminta, slot, estimasi_berat, catatan |
| GET | `/api/v1/permintaan-jemput` | riwayat milik sendiri |
| GET | `/api/v1/permintaan-jemput/{id}` | detail + status |
| POST | `/api/v1/permintaan-jemput/{id}/batal` | hanya saat status `baru` |

Path juga memakai ID numerik (alasan sama: `no_referensi` mengandung `/`).

Web kasir: route baru `/permintaan-jemput` (filter `role:admin,kasir`) untuk daftar + aksi
`Konfirmasi` → `Dijemput` → `Selesai`, dan `Batal` dengan alasan. Notifikasi memakai
`App\Config\WhatsApp`: karena provider aktif masih `link`, halaman kasir **menampilkan tombol
"Kirim via WhatsApp"** yang membuka `wa.me`, bukan kirim otomatis. Kalau nanti provider
Fonnte/Wablas diaktifkan, tombol yang sama bisa memanggil API.

### 7.6 Kontrak response

Sukses:
```json
{ "data": { }, "meta": { } }
```
List: `meta = {page, per_page, total, last_page}`.

Error:
```json
{ "error": { "code": "AUTH_INVALID_PIN", "message": "PIN salah.", "fields": { "pin": ["..."] } } }
```

Aturan:
- Uang selalu **integer rupiah** (`42000`), bukan float/string.
- Tanggal ISO-8601 dengan offset `+07:00`.
- HTTP: 200/201/204, 401, 404, 409, 422, 429, 500.
- 401 JSON, tidak pernah redirect ke `/login` (filter terpisah).
- Jangan pernah log PIN, token, atau hash.

### 7.7 Mapping status

DB hanya punya 5 status nyata. Timeline app memakai itu, bukan 7 langkah fiktif:

| DB | Label app |
|---|---|
| `menunggu` | Diterima |
| `proses` | Dicuci |
| `setrika` | Disetrika |
| `selesai` | Siap Diambil |
| `diambil` | Selesai |

Sumber: `tb_status_log` (riwayat + waktu), fallback ke `tb_transaksi.status`.
Status permintaan jemput ditampilkan terpisah, bukan dicampur ke timeline transaksi.

### 7.8 Kode yang dipakai ulang

- `App\Services\LacakService::searchByNota / searchByPhone` untuk pengambilan data + timeline.
- `MPelanggan::generateKode()`, `MTransaksi::getTransaksiWithJoins()`.
- `dompdf` (sudah terpasang) bila nanti perlu PDF nota; fase 1 cukup JSON.
- Konfigurasi WhatsApp existing (`link|fonnte|wablas`).

### 7.9 Testing

- Feature test per endpoint di `tests/Api/`, `DatabaseTestTrait` + `FeatureTestTrait`.
- DB test terpisah: `laundry_test` (MySQL XAMPP), migrate fresh tiap run.
- Wajib ada test: login sukses/gagal, rate limit, isolasi data antar pelanggan,
  aktivasi dengan no_nota orang lain (harus gagal), validasi input, pagination.
- Tidak dijalankan terhadap DB production.

## 8. Frontend (Flutter)

Lokasi: `C:\Users\R\Documents\@Semester 5\sparkleen_mobile_pelanggan`

- Flutter stable, Riverpod, go_router, dio, flutter_secure_storage, intl, google_fonts, shimmer.
- Struktur feature-first: `lib/core/{api,theme,router,storage,widgets}`,
  `lib/features/{auth,home,layanan,pesanan,lacak,nota,profil,permintaan_jemput}`.
- Token disimpan di secure storage; 401 → logout otomatis + kembali ke login.
- Design token mengikuti `DESIGN.md`: primary `#2F2DD2`, bg `#FFFFFF`, surface `#F8F9FC`,
  border `#E2E8F0`, text `#0D0F1A`, muted `#64748B`; Plus Jakarta Sans + Manrope;
  radius kartu 14, input 10, sheet 20; shadow tipis.
- Navigasi fase 1: 3 tab — Beranda, Pesanan, Profil. Lacak & nota masuk dari kartu pesanan.
- Home menampilkan pesanan aktif, 3 aksi cepat, daftar layanan + harga, dan kartu poin.
- Tanpa order engine: CTA layanan = "Minta Dijemput" (fase 2) atau "Hubungi via WA".
- Empty/loading/error state dirancang, bukan setelahnya.

## 9. Rollout

1. Backup DB production (sudah ada `Backup` controller).
2. Migrasi hanya menambah kolom nullable + tabel baru → aman dijalankan saat app kasir hidup.
3. Deploy backend ke Railway yang sama, base URL `https://<existing-host>/api/v1`.
4. Flutter build internal (APK) dulu; belum perlu Play Store.
5. Tag `v1.0.0-mobile-api` setelah fase 1 lolos test.

## 10. Keputusan yang saya ambil (silakan dikoreksi)

1. Token opaque di DB, bukan JWT — bisa dicabut langsung, tanpa dependency baru.
2. PIN, bukan OTP WhatsApp — provider WA masih `link`, OTP butuh gateway aktif dan biaya.
3. Pelanggan lama aktivasi lewat `no_nota` terakhir, bukan daftar ulang.
4. Fase 2 pakai tabel terpisah; `tb_transaksi` utuh.
5. Timeline 5 status nyata.
6. Uang integer rupiah.
7. Tidak ada endpoint lacak publik baru; semua lewat auth.
8. Tab app fase 1: 3, bukan 4.
9. Path API memakai ID numerik, bukan `no_nota`/`no_referensi` (masalah `/` di Apache).
10. Nomor telepon dinormalisasi saat lookup, tanpa backfill data lama.
11. Notifikasi fase 2: tombol "Kirim via WhatsApp" di halaman kasir, bukan auto-send.
12. Fase 2 dikerjakan sebagai plan terpisah setelah fase 1 jalan.
13. Logo memakai wordmark teks; tidak ada ilustrasi, tidak perlu aset gambar di fase 1.

## 11. Yang diserahkan ke builder

- Penamaan file/kelas dan gaya kode mengikuti konvensi CI4 yang sudah ada.
- Bentuk query list transaksi (JOIN vs model method) — bebas selama terisolasi per pelanggan.
- Detail format `meta` pagination dan pesan error bahasa Indonesia.
- Struktur widget Flutter dan state management per fitur.
- Isi `README` API dan contoh `.env` lokal.

## 12. Risiko

- **Duplikat nomor telepon** sudah dijaga unique index; register harus menangani 409 dengan rapi.
- **`no_nota` bukan rahasia** (tercetak di nota), jadi aktivasi tetap butuh rate limit ketat.
- **DB production**: migration hanya additive; jangan pernah `migrate:refresh` di Railway.
- **Timezone**: server bisa UTC; semua response dikonversi ke `Asia/Jakarta`.
- **CI4 filter web** memakai redirect; API wajib punya filter sendiri agar tidak balas HTML.
