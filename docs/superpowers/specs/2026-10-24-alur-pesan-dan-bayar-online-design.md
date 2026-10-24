# Sparkleen Mobile Pelanggan — Fase 2/3: Alur Pesan + Bayar Online

Tanggal: 2026-10-24
Status: disetujui user 2026-10-24; Plan A (backend) sudah ditulis, Plan B (Flutter) belum
Pemilik: Rachmat
Supersedes: `2026-10-23-sparkleen-mobile-api-design.md` §3 Fase 2 & Fase 3 (permintaan jemput dan pembayaran online yang sebelumnya ditandai "tidak dikerjakan sekarang")

## 1. Intent

Dua hal yang belum diselesaikan fase 1: pelanggan tidak bisa meminta cucian dijemput, dan
tidak bisa bayar tanpa berdiri di outlet. Keduanya ditutup di sini.

Yang harus benar-benar berubah dari sisi pelanggan:

- Buka app → pilih layanan → atur jemput → kirim. Selesai, tidak perlu chat WA untuk mulai.
- Setelah kasir menimbang dan mengonfirmasi, pelanggan lihat nominal final dan bisa bayar
  QRIS/transfer dari app, lalu status pesanan dan bukti bayar muncul sendiri tanpa balik ke outlet.

## 2. Keputusan yang sudah dikunci

| # | Keputusan | Alasan |
|---|---|---|
| 1 | Order = **permintaan**, bukan transaksi. App tidak insert ke `tb_transaksi`. | Harga final baru ada setelah kasir menimbang; `tb_transaksi.id_kasir` NOT NULL + FK; struktur `tb_transaksi` tidak boleh diubah. |
| 2 | V1 hanya **jemput ke alamat**, satu layanan per request. | Drop-off sudah jalan di outlet; multi-item tidak dibutuhkan paket all-in yang ada. |
| 3 | Layar **Pesanan Masuk di web kasir termasuk scope**. | Tanpa konfirmasi kasir, request jadi dead end. |
| 4 | Bayar: **opsi A — inisiatif pelanggan**, lewat endpoint `/api/v1` baru; backend CI4 yang bicara ke Node `payment_api`. | Kasir tidak perlu ikut campur untuk membuka tagihan; kunci merchant `X-Api-Key` tetap hanya di server. |
| 5 | Status lunas **hanya** datang dari webhook HMAC. Tidak ada endpoint yang membuat app bisa menyatakan dirinya sudah bayar. | Lihat §7 — ini keputusan paling penting di dokumen ini. |

## 3. Kenapa tidak ada tombol "Saya sudah bayar" yang langsung melunasi

Ini temuan yang mengubah desain, dan harus dinyatakan eksplisit.

Di `payment_api/src/services/paymentService.js:16`, `verifyPayment()` di-set
`const isSuccess = true` (komentar aslinya: `PROTOTYPE: Simulasi selalu sukses`). Artinya
kalau kita menambah `POST /transaksi/{id}/pembayaran/verifikasi` yang memanggil endpoint
`/pay` Node, maka pelanggan cukup menekan satu tombol untuk membuat pesanannya berstatus
LUNAS tanpa membayar apa pun. Bukan celah keamanan jaringan — celah logika: pihak yang
berhak menyatakan uang masuk jadi pihak yang membayar.

Aturan yang dipakai: **penerima pembayaran tidak pernah dipercaya menyatakan pembayaran
masuk.** Yang menyatakan adalah sisi pembayar (wallet/SmartPay) atau sisi bank, lewat
callback ter-signing. Karena itu alurnya:

```
app      : inisiasi intent  →  tampilkan QR/rekening  →  polling
pembayar : SmartPay menyatakan uang masuk → Node → webhook HMAC → CI4 mencatat LUNAS
```

Di gateway sungguhan (Midtrans/Xendit) persis begini juga bentuknya: app inisiasi, status
berubah saat webhook dari gateway datang. Bedanya, di prototype ini webhook-nya dipicu
tombol di sisi kasir/SmartPay, bukan oleh bank. Konsekuensi demo (§11) diterima sadar-sadar.

## 4. Scope

### 4.1 Backend CodeIgniter 4

- Migrasi `tb_permintaan_pesanan` (additive, tidak menyentuh tabel yang ada).
- CRUD API v1 untuk permintaan: buat, daftar milik sendiri, detail, batalkan.
- Endpoint pembayaran intent: create, read, cancel.
- `PaymentApiService` — satu implementasi panggilan ke Node, dipakai jalur kasir dan jalur app.
- Layar web kasir "Pesanan Masuk": daftar, konfirmasi (buat transaksi), tolak.

### 4.2 App Flutter

- Tab Pesan: form permintaan jemput + daftar permintaan milik sendiri.
- Detail pesanan: CTA "Bayar" saat ada sisa tagihan.
- Layar pembayaran: metode, QR/nomor rekening, countdown kedaluwarsa, polling status.

### 4.3 Non-goals

- Drop-off dari app, multi-layanan dalam satu request, reschedule jadwal jemput.
- Push notification (tetap pull-to-refresh + polling).
- Saldo/top-up e-wallet di app pelanggan.
- Rekonsiliasi otomatis uang nyata; tidak ada settlement sungguhan.
- Kurir: penjadwalan rute penjemputan, bukti jemput foto.
- Refund parsial / pembatalan pembayaran yang sudah lunas.

## 5. Model data

### 5.1 Tabel baru `tb_permintaan_pesanan`

```
id_permintaan        INT AUTO_INCREMENT PK
id_pelanggan         INT NOT NULL  FK → tb_pelanggan
id_layanan           INT NOT NULL  FK → tb_layanan
berat_perkiraan      DECIMAL(6,2) NOT NULL          -- estimasi pelanggan, bukan angka final
catatan             VARCHAR(255) NULL
alamat_jemput       VARCHAR(255) NOT NULL
tgl_jemput          DATETIME NOT NULL
slot_jemput         VARCHAR(20) NOT NULL            -- pagi | siang | sore
status              VARCHAR(20) NOT NULL            -- menunggu | dikonfirmasi | ditolak | dibatalkan
                                                     -- (+ diproses: internal kasir, tidak pernah keluar ke app)
id_transaksi        INT NULL FK → tb_transaksi      -- diisi atomik saat kasir konfirmasi
alasan_penolakan    VARCHAR(255) NULL
dikonfirmasi_oleh   INT NULL FK → tb_karyawan       -- kasir yang memproses
created_at / updated_at  DATETIME
```

Tidak ada `id_outlet`: outlet tunggal dan hanya ada sebagai `Config\Outlet`, bukan tabel DB.

Batasan: maksimal satu baris `status = menunggu` per `id_pelanggan` (dijaga di lapisan
service dengan klaim atomik, bukan constraint DB, karena MySQL tidak punya partial unique index).

### 5.2 `tb_transaksi` — nol perubahan struktur

Kolom yang dibutuhkan sudah ada sejak migrasi `2026-06-20-091304_AddPaymentApiColumnsToTransaksi`:
`payment_ref VARCHAR(100) NULL`, `payment_detail TEXT NULL`. `id_status_pembayaran` dan
`id_metode_pembayaran` juga sudah ada.

Satu-satunya hal baru di tabel ini adalah **isi** `payment_detail`: JSON respons Node yang
kita perluasi dengan satu field `expired_at` (dipakai untuk menghitung kedaluwarsa intent —
lihat §6.2). Ini perubahan bentuk JSON di kolom yang sudah ada, bukan perubahan kolom.

## 6. Kontrak API v1

Semua di bawah `api/v1`, namespace `App\Controllers\Api\V1`, filter `['cors','apiauth']`,
envelope sama seperti endpoint yang sudah ada (`{data}` / `{error:{code,message,fields}}`).

### 6.1 Permintaan jemput

```
POST   /api/v1/permintaan
       {id_layanan, berat_perkiraan, alamat_jemput, tgl_jemput, slot_jemput, catatan?}
       → 201 {id_permintaan, status, estimasi_harga, ...}
       → 409 ACTIVE_REQUEST_EXISTS   (sudah ada permintaan `menunggu`)
       → 422 validasi

GET    /api/v1/permintaan?status=aktif|selesai|semua&page=1
       → 200 [ ... ] + meta pagination

GET    /api/v1/permintaan/{id}
       → 200 satu permintaan + id_transaksi bila sudah dikonfirmasi

POST   /api/v1/permintaan/{id}/batal
       → 200 hanya bila status masih `menunggu`; selain itu 409
```

`estimasi_harga` = `harga_satuan layanan × berat_perkiraan`. Diberi label estimasi di semua
UI dan tidak pernah ditulis ke `tb_transaksi`.

### 6.2 Pembayaran

```
POST   /api/v1/transaksi/{id}/pembayaran
       {metode: "QRIS" | "TRANSFER"}
       → 201 {status:"PENDING", metode, nominal, payment_detail, expired_at}
       → 200 idempoten: kalau sudah ada intent aktif metode sama, balikin intent itu
       → 409 ALREADY_PAID            (sisa <= 0)
       → 409 CONFLICT_METHOD          (intent aktif metode lain — batalin dulu)
       → 404 bukan transaksi milik pelanggan ini

GET    /api/v1/transaksi/{id}/pembayaran
       → 200 {status: NONE|PENDING|EXPIRED, nominal, metode, payment_detail,
              expired_at, total_dibayar, sisa, status_pembayaran}
       Dibaca dari DB lokal saja: payment_ref non-null → PENDING; null → lihat status pembayaran.
       Tidak ada panggilan keluar ke Node, jadi app tidak bisa lihat data yang belum
       dinyatakan oleh webhook.

POST   /api/v1/transaksi/{id}/pembayaran/batal
       → 200 payment_ref & payment_detail dinolkan; memanggil Node /:id/cancel best-effort
```

Perubahan kecil pada endpoint yang sudah ada: `GET /api/v1/transaksi/{id}` menambah satu field
`sisa_tagihan` (int, rupiah). Tanpa itu app harus menjumlahkan `pembayaran[]` sendiri untuk
memutuskan menampilkan CTA Bayar — logika uang di klien, persis yang dilarang §7.

Aturan wajib:

- **Konstanta metode punya nama berbeda di tiap lapis.** Klien/app mengirim `QRIS` atau
  `TRANSFER`; Node `payment_api` hanya menerima `QRIS` atau `BANK_TRANSFER`
  (`transactions.js:16`). `PaymentApiService` satu-satunya tempat penerjemahan, dan
  `GET /pembayaran` membalas dengan nama sisi klien supaya app tidak perlu tahu ada dua kamus.
- **Nominal intent = sisa tagihan** (`hitungSisaTagihan()`), bukan `grand_total`. Dengan begitu
  pembayaran cicil tetap bisa ditutup dari app.
- **Klaim atomik.** Sebelum memanggil Node, transaksi harus `payment_ref IS NULL`; sesudah
  dapat `transaction_id`, update dengan `WHERE payment_ref IS NULL`. Kalau `affectedRows = 0`,
  batalkan intent yatim di Node dan balikin intent yang menang. Ini meniru pola yang sudah
  dipakai `Webhook::payment()` untuk menolak callback ganda.
- `expired_at` dari respons Node disimpan di dalam `payment_detail`; `GET` memakai nilai itu
  untuk membalas `EXPIRED`. Tanpa itu intent kedaluwarsa tampak abadi.
- `id_metode_pembayaran` ikut di-set saat intent dibuat (2 = QRIS, 3 = Transfer), sama seperti
  yang dilakukan jalur kasir hari ini.

## 7. Keamanan

- App **tidak pernah** memegang `PAYMENT_API_KEY`. Semua panggilan Node keluar dari CI4.
- Setiap endpoint memfilter `id_pelanggan` milik token; transaksi/permintaan milik orang lain
  dibalas 404, bukan 403, supaya tidak membocorkan keberadaan data.
- `Webhook::payment()` tetap satu-satunya penulis `tb_pembayaran` dari jalur online, dan
  verifikasinya HMAC-SHA256 atas raw body dengan `hash_equals()`. Tidak ada jalur baru.
- Tidak ada nominal yang diterima dari klien. Amount selalu dihitung ulang dari DB.
- Rate limit: **tidak ada limiter baru.** `AuthThrottle` hari ini khusus jalur login, dan kedua
  endpoint ini sudah punya rem alami — permintaan dibatasi "maksimal satu `menunggu` per
  pelanggan", intent dibatasi klaim atomik `payment_ref IS NULL`. Menambah limiter kedua adalah
  biaya tanpa manfaat untuk 30–80 kg/hari.
- Yang ditulis ke log: `id_transaksi`, `payment_ref`, status. Yang tidak pernah: token, PIN,
  isi `payment_detail` penuh.

## 8. `PaymentApiService`

Fungsi yang hari ini hidup di dalam `TransaksiService::prosesPembayaran()` (baris 237) —
build request, header `X-Api-Key`, cek `success`, simpan `payment_ref`/`payment_detail`,
tangani gagal — dipindah ke `App\Services\PaymentApiService` dengan interface kecil:

```php
buatIntent(int $idTransaksi, string $noNota, float $nominal, string $metode): array
batalkanIntent(string $transactionId): void
```

`prosesPembayaran()` dipanggil ulang untuk memakai service ini; **perilaku kasir tidak boleh
berubah** — itu dipakai tiap hari dan tidak ada test yang menjaganya saat ini, jadi perubahan
di sini harus disertai test yang mereproduksi respons sukses/gagal yang sekarang diharapkan.

Testability: service menerima Guzzle/CI4 `CURLRequest` lewat konstruktor dan didaftarkan di
`Config/Services.php` (`service('paymentApi')`). Test feature mengikat stub yang mengembalikan
array tiruan, sehingga suite tidak butuh Node API hidup — dan juga tidak pernah menembak
produksi dari dalam test.

## 9. UI

### 9.1 App Flutter

Shell tiga tab (beranda · pesanan · profil) **tidak berubah**. `AppShell` dan smoke test lama
aman; "Pesan" di beranda tetap quick action, hanya sekarang benar-benar membuka halaman.

```
/pesan                PesanPage — dua tab internal, bukan dua rute
   ├─ Form    : layanan · berat perkiraan · alamat · tanggal · slot · catatan · estimasi harga
   └─ Riwayat : kartu permintaan `menunggu` (CTA batal) + permintaan selesai/ditolak
/pesan/{id}           DetailPermintaanPage — status + link ke /pesanan/{id} bila sudah dikonfirmasi
/pesanan/{id}/bayar   BayarPage
   ├─ pilih metode QRIS | Transfer
   ├─ nominal sisa + countdown kedaluwarsa
   ├─ QRIS     → QR dari payment_detail.qris_data (qr_flutter)
   ├─ TRANSFER → bank, nomor rekening, atas nama (tap untuk salin)
   └─ "Menunggu pembayaran" → polling GET /pembayaran tiap 5 dtk → "Pembayaran diterima"
```

CTA **Bayar Rp X** di `DetailPesananPage` tampil hanya bila `sisa_tagihan > 0` — bukan
`status_pembayaran != lunas`, karena status itu bisa `belum` padahal intent sedang berjalan.

State wajib di setiap layar: loading, empty, error, dan kedaluwarsa (intent habis waktu →
minta buka ulang). 401 dari polling → berhenti polling, hapus token, ke `/login` (aturan lama).
`qr_flutter` jadi satu-satunya dependency baru di app.

### 9.2 Kasir web

Satu halaman baru: **Pesanan Masuk** (`Permintaan` controller, filter `role:admin,kasir`)
dengan dua aksi.

- **Konfirmasi** → form kecil (berat actual + catatan) → transaksi dibuat lewat
  `TransaksiService::prosesTransaksiBaru()` yang sudah dipakai form transaksi hari ini.
  `id_transaksi` ditulis balik ke permintaan secara atomik; tidak ada INSERT manual ke
  `tb_transaksi` di tempat baru.
- **Tolak** → alasan wajib, status `ditolak`, pelanggan melihat alasannya di app.

Halaman `Transaksi::pembayaran` yang sekarang **tidak diubah** perilakunya. Jalur kasir
membuat intent dan jalur app membuat intent memakai service yang sama, jadi tidak ada dua
definisi "tagihan online".

### 9.3 Yang sengaja tidak dibuat: tombol "sudah dibayar" di kasir

Godanya adalah menambah tombol di halaman pembayaran yang memanggil Node `/pay` supaya demo
bisa ditutup dari satu layar. Itu melanggar aturan §7: penerima pembayaran jadi pihak yang
menyatakan uang masuk, dan karena `verifyPayment()` selalu mengembalikan sukses, tombol itu
efektifnya "lubangi pesanan mana pun". Yang benar: sisi pembayar yang menyatakan (SmartPay),
persis seperti yang sudah jalan hari ini.

## 10. Urutan kerja

Backend dan app tidak bisa digabung satu plan: dua repo, dua harness test, dan backend wajib
punya kontrak yang bisa ditembak sebelum ada UI. Maka:

1. **Plan A — Backend** (`docs/superpowers/plans/`): migrasi → `PaymentApiService` + test →
   endpoint permintaan → endpoint pembayaran → layar kasir → docs API + Postman.
2. **Plan B — Flutter**: model+repo permintaan → form & daftar → layar bayar + polling →
   integrasi CTA di detail → smoke test → screenshot Chrome.

Flutter tidak menunggu backend selesai total; tiap endpoint begitu selesai langsung bisa
dikonsumsi, tapi urutan plan tetap backend dulu supaya kontrak tidak berubah dua kali.

## 11. Verifikasi & konsekuensi demo

Hard rule sebelum menyentuh apa pun yang hidup:

- `payment_api/src/db/index.js:28` memakai default
  `CALLBACK_URL = https://sparkleen.rachmatx.me/webhook/payment` — itu **produksi**. Untuk uji
  lokal wajib di-override ke `http://127.0.0.1:8082/webhook/payment` lewat env, dan gw tidak
  akan menjalankan satu pun alur bayar sebelum itu terbukti berubah.
- Suite PHPUnit jalan di `laundry_db_test` saja; tidak ada test yang memanggil Node asli.
- Verifikasi UI di Chrome (`flutter run -d web-server`, `--dart-define=API_BASE_URL=http://127.0.0.1:8082`)
  sesuai preferensi, bukan emulator.

Cara loop ditutup saat demo, karena app sengaja tidak bisa melunasi dirinya sendiri:

1. Pelanggan (app) inisiasi intent → QR/rekening muncul di `BayarPage`.
2. Sisi pembayar yang menyatakan lunas: **SmartPay** (`/pelanggan-bayar`) — scan nota QR atau
   masuk rekening transfer → PIN → `prosesBayar()` → Node `/confirm`.
3. Node → webhook HMAC → `Webhook::payment()` mencatat `tb_pembayaran` → app berubah sendiri
   dalam ≤5 detik dari polling.

Koreksi dari asumsi awal gw: `Transaksi::ajaxCekPembayaran()` **tidak** memanggil Node. Ia
hanya membaca sisa dari DB lokal dan dipoll halaman kasir untuk melihat hasil webhook. Jadi
satu-satunya penutup loop yang ada hari ini ya SmartPay itu, dan desain ini tidak menambah
yang kedua (lihat §9.3). Untuk demo, presenter berpindah tab browser — bukan menekan tombol.

QRIS di app: `qris_data` yang di-seed adalah payload EMVCo merchant QR **statis tanpa nominal**,
sehingga hasil scan tidak membawa jumlah yang harus dibayar. App menampilkan nominal terpisah.
Jangan klaim QR-nya "langsung bayar pas scan".

Framing jujur untuk laporan: ini **alur bayar online lengkap dengan settlement disimulasikan**.
Yang nyata: inisiasi dari app, klaim atomik, kedaluwarsa, webhook HMAC ter-signing, idempotensi,
nominal dihitung di server. Yang disimulasikan: uang berpindah. Jangan ditulis sebagai
"integrasi payment gateway produksi".

## 12. Risiko

| Risiko | Mitigasi |
|---|---|
| Pelanggan tekan bayar, tidak pernah bayar, status menggantung 15 menit | `expired_at` disimpan; `GET` membalas `EXPIRED`; intent bisa dibatalkan dari app. |
| Dua intent aktif untuk satu transaksi (app + kasir barengan) | Klaim atomik `WHERE payment_ref IS NULL`; yang kalah membatalkan intent yatim di Node. |
| Webhook produksi tertembak saat dev | Override `CALLBACK_URL` + daftar periksa sebelum eksekusi (§11). |
| Regresi jalur bayar kasir yang dipakai tiap hari | Refactor ke `PaymentApiService` dengan test yang mereproduksi perilaku lama sebelum mengubahnya. |
| Repo backend kotor, perubahan kecampur pekerjaan orang lain | Commit per task, hanya file yang gw sentuh; tidak pernah `git add -A`. |
| `tb_transaksi.id_kasir` membuat request tanpa kasir tidak bisa jadi transaksi | Konfirmasi selalu dilakukan kasir login; `dibuat_oleh` menyimpan siapa yang memproses. |

## 13. Definition of done

- Migrasi additive, jalan di `laundry_db_test`, tidak mengubah satu kolom pun di `tb_transaksi`.
- `flutter analyze` bersih, `flutter test` hijau, suite backend hijau, tanpa test yang menyentuh Node/produksi.
- Permintaan: buat → tampil di kasir → konfirmasi → transaksi terbentuk → muncul di app dengan `id_transaksi`.
- Bayar: intent dibuat dari app → QR/VA tampil → webhook masuk → app jadi lunas tanpa interaksi tambahan.
- Ganda: callback kedua untuk satu `payment_ref` tidak menghasilkan dua baris `tb_pembayaran`.
- Batas: request ganda ditolak, transaksi orang lain 404, intent metode lain menuntut pembatalan.
- Dokumen API + Postman collection ter-update untuk semua endpoint baru.
