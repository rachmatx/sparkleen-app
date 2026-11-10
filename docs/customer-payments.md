# Tahap 3 — pembayaran pelanggan

Implementasi lokal `feat/customer-payments`, 10 November 2026. Belum push/deploy.
Tahap 4 dilanjutkan pada `feat/notifications-loyalty`; lihat `docs/notifications-and-points.md`. Push OS belum tersedia.

## Pengalaman pelanggan

Detail pesanan → Lihat pilihan pembayaran → QR atau transfer **simulasi**.
Halaman menampilkan sisa tagihan server, label simulasi, QR PNG/kode Smart Pay,
expiry, cek status, dialog batal, dan status lunas. Desain menggunakan background
solid dan komponen glass existing dengan permukaan hampir opaque; tema terang/gelap
serta artwork existing tetap dipertahankan.

Polling 10 detik hanya saat foreground dan attempt aktif, tanpa request tumpang
tindih. Response terlambat dari akun sebelumnya tidak boleh memperbarui akun baru.
Kegagalan jaringan mempertahankan snapshot/kode dan menampilkan pesan retry.
Pembayaran sukses menginvalidasi detail, nota, daftar dan ringkasan pesanan.

## Integrasi dan batas

- Flutter hanya memakai bearer pelanggan ke Laundry; tidak menyimpan merchant key.
- Laundry menghitung sisa tagihan, membuat attempt tahan retry sebelum HTTP, lalu
  memverifikasi respons raw HMAC dari Payment API.
- Payment API memakai idempotency key per merchant dan perubahan status kondisional;
  pay/cancel bersamaan tidak dapat keduanya menang.
- Status signed dapat memulihkan callback yang hilang melalui settlement atomik sama.
- Cancel tidak menghapus tagihan lokal sebelum provider mengonfirmasi. Kas kasir
  ditolak selama attempt online aktif; saat provider mati pelanggan menghubungi outlet.
- Provider masih simulator; QR berisi UUID, rekening dummy. Fitur ini tidak menerima
  uang nyata. Pembuatan baru default nonaktif (`MOBILE_PAYMENTS_ENABLED=false`).
- Callback retry persisten/outbox, gateway bank nyata, Android fisik dan deployment
  belum tercakup. Smart Pay tidak diubah; scanner/input kode existing menerima UUID.

## Konfigurasi pasangan server

Laundry membutuhkan migration `2026-11-10-000003_AddCustomerPaymentLifecycle`,
`PAYMENT_API_URL`, `PAYMENT_API_KEY`, secret server terpisah `PAYMENT_WEBHOOK_SECRET`.
Aktifkan `MOBILE_PAYMENTS_ENABLED=true` hanya untuk lingkungan demo/test.
Payment API memerlukan API_KEY, secret sama dengan Laundry, DB_FILE terpisah dan
CALLBACK_URL jika ingin callback. Gunakan versi kedua server dari tahap ini bersama.
Jangan menaruh key di Flutter atau parameter build. Production URL gateway wajib HTTPS.
Backup DB sebelum migrasi operasional. Migration down menolak menghapus attempt
CREATING yang belum memiliki gateway_ref; rekonsiliasi dahulu. Pembatalan tidak
memperbolehkan kasir menerima kas ketika status remote belum pasti.

## Verifikasi

| Pemeriksaan | Hasil |
|---|---|
| Laundry full suite | 143 tests, 664 assertions lulus |
| Penjagaan kasir terakhir + pembayaran | 26 tests, 165 assertions lulus pada pemeriksaan ulang |
| Flutter full suite | 107 tests lulus (13 baru) |
| Flutter analyze | No issues found |
| Payment API | 17 tests lulus (migrasi legacy dan HTTP) |
| Dart → PHP → Node/SQLite → MariaDB | Lulus; callback dimatikan sengaja, ledger tercatat sekali |
| Build web release | Berhasil, 75,8 detik; URL contoh HTTPS, bukan deployment |

 Test unit/widget tidak
menghubungi layanan operasional. Uji opt-in `tool/customer_payment_integration_test.dart`
memerlukan localhost Laundry + Payment API dan database `laundry_db_test` disposable,
CALLBACK_URL kosong untuk membuktikan pemulihan callback hilang. PAYMENT_TEST_URL dan
PAYMENT_TEST_KEY hanya fixture; kode pengujian tidak disertakan build aplikasi.

```sh
flutter analyze
flutter test
flutter test tool/customer_payment_integration_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:42527
```
