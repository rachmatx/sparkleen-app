# Hasil fondasi integrasi Sparkleen

10 November 2026 · verifikasi lokal pada branch `feat/customer-api-foundation` di kedua repo.

## Yang sudah diterapkan

Backend Laundry memperoleh 11 endpoint pelanggan `/api/v1`: daftar, aktivasi,
login, logout, profil, edit profil, layanan, outlet, daftar transaksi, detail, dan
nota. Autentikasi Bearer terpisah dari sesi kasir. PIN di-hash, DB menyimpan hash
token, token dapat dicabut/kedaluwarsa, dan login/aktivasi/registrasi dibatasi.
Normalisasi nomor mendukung pelanggan lama tanpa mengubah seluruh data lama.

Query transaksi dan nota dibatasi ke pelanggan pemilik token. Detail privat dapat
memuat PIN pengambilan; daftar dan nota tidak. Harga/poin tetap berasal dari tabel
kasir. Kontrak JSON, field integer rupiah, pagination, status, serta zona tanggal
dicocokkan dengan model Flutter. CORS memakai origin yang dikonfigurasi eksplisit.

Flutter mereset cache data pelanggan saat sesi berganti. Respons pagination lama
tidak boleh digabungkan ke sesi baru, respons 401 milik token lama tidak boleh
menghapus sesi baru, dan kegagalan 401 saat edit profil tidak boleh mengembalikan
state authenticated. Desain dan aset yang sudah terpasang dipertahankan.

Jalur kasir QRIS/transfer yang tidak dapat membuat tagihan sekarang mengembalikan
kegagalan, bukan meneruskan pencatatan pembayaran lokal. Ini perbaikan terbatas:
webhook, retry callback, otorisasi Smart Pay dan simulasi saldo masih pekerjaan
berikutnya.

## Bukti pengujian

| Pemeriksaan | Hasil |
| --- | --- |
| Baseline backend `524f554` | 86 test, 17 failure lama |
| Backend sesudah perubahan | 104 test, 17 failure; nama test yang gagal sama persis dengan baseline |
| API pelanggan baru | Seluruh 18 test lulus, tanpa error/failure baru |
| Flutter unit/widget | 84 test lulus |
| Integrasi Flutter → HTTP → CodeIgniter → MariaDB | 1 skenario penuh lulus |
| Analisis Flutter | Tanpa masalah |
| Build web release | Berhasil; memakai URL contoh saat compile, bukan deployment |
| Sintaks PHP yang diubah | Lulus `php -l` |

Runtime pengujian: PHP 8.4.24, MariaDB 11.8.6 dan dependency Composer yang dikunci
repo. Baseline memakai snapshot kode sebelum perubahan dengan konfigurasi test
lokal yang sama. Tidak menganggap angka historis dari rencana Oktober sebagai
hasil saat ini. Semua data berasal dari fixture lokal; tidak menghubungi backend
operasional, Payment API operasional, atau pengiriman WhatsApp.

Skenario live memakai **repository Dart dan Dio yang asli**, server HTTP
CodeIgniter, serta database lokal `laundry_db_test`. Yang diganti hanya penyimpanan
token perangkat, karena plugin secure storage native tidak dijalankan dalam test
host. Skenario tersebut:

1. Masuk sebagai pelanggan pertama dengan nomor alias `62...`.
2. Membaca profil, katalog, outlet, daftar, serta detail transaksi.
3. Mengubah profil dan membaca hasil yang tersimpan.
4. Menjalankan service kasir sebenarnya untuk memperbarui status dan mencatat
   pembayaran tunai pada order demo; tidak memanggil gateway atau WhatsApp.
5. Membaca ulang detail/nota dari Flutter dan memeriksa perubahan status/pembayaran,
   nominal yang sama, serta ketiadaan PIN pengambilan dalam payload nota.
6. Logout, lalu memastikan akses tanpa token ditolak.
7. Membuat akun kedua dan memastikan detail/nota akun pertama menghasilkan 404,
   sementara riwayat akun kedua kosong.

Test backend mencakup migrasi naik/turun tanpa mengubah baris transaksi,
validasi/normalisasi nomor, hash token/PIN, aktivasi dengan nota terakhir,
rate limit, token invalid/expired/revoked, akun nonaktif, pembatasan PATCH,
pagination, data terhapus/kosong, pembulatan rupiah, status tidak dikenal,
preflight CORS, serta gateway tidak dikonfigurasi/transport gagal.

## Failure backend yang sudah ada sebelum perubahan

Suite backend keseluruhan **belum hijau**. Perbandingan memakai nama setiap test,
bukan hanya jumlah failure. Tidak ada failure baru pada hasil akhir.

- `Tests.Feature.AuthFeatureTest.testDeactivatedAccountCannotLogin`
- `Tests.Feature.AuthFeatureTest.testEmptyCredentialsShowsError`
- `Tests.Feature.AuthFeatureTest.testFailedLoginShowsError`
- `Tests.Feature.AuthFeatureTest.testLoginWithEmailWorks`
- `Tests.Feature.AuthFeatureTest.testSuccessfulLoginRedirectsToDashboard`
- `Tests.Feature.RateLimitTest.testBlockedLoginRecordsSecurityLog`
- `Tests.Feature.RateLimitTest.testFailedLoginRecordsActivityLog`
- `Tests.Feature.RateLimitTest.testLoginThrottleBlocksAfterMaxAttempts`
- `Tests.Feature.RateLimitTest.testSuccessfulLoginClearsThrottle`
- `Tests.Feature.TransaksiFeatureTest.testAddToCartAndRemoveFromCart`
- `Tests.Feature.TransaksiFeatureTest.testPointCalculation`
- `Tests.Feature.TransaksiFeatureTest.testSimpanPembayaranCalculatesChange`
- `Tests.Feature.TransaksiFeatureTest.testSimpanPembayaranRecordsPayment`
- `Tests.Feature.TransaksiFeatureTest.testSimpanTransaksiCreatesFullTransaction`
- `Tests.Feature.TransaksiFeatureTest.testSimpanTransaksiRejectsEmptyCart`
- `Tests.Feature.TransaksiFeatureTest.testSimpanTransaksiRejectsNoCustomer`
- `Tests.Unit.Models.TransaksiModelTest.testAllowedFieldsAreCorrect`

Kegagalan lama meliputi ekspektasi field model, redirect/session autentikasi web,
rate limit web, dan feature test transaksi kasir. Perbaikannya dipisahkan dari
fondasi API agar perubahan ini dapat ditinjau dengan jelas. Lulusnya API baru
bukan klaim bahwa seluruh alur web kasir sudah lulus pengujian otomatis.

## Menjalankan ulang

Backend: ikuti `docs/api/customer-api-foundation.md` di repo Laundry. PHPUnit
memakai bootstrap yang menolak reset DB selain database test lokal yang bernama
`laundry_db_test`. Database tersebut harus benar-benar disposable.

Frontend, setelah fixture/backend lokal siap dan environment `LAUNDRY_TEST_ROOT`
serta `TEST_PHP_BIN` diisi:

```sh
CI=true flutter test
CI=true flutter analyze
CI=true flutter test tool/customer_api_integration_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:42525
flutter build web --release --dart-define=API_BASE_URL=https://your-backend.example
```

Gunakan base URL server tanpa menambahkan `/api/v1` lagi. Untuk Android emulator,
konfigurasi sesuai host emulator; perangkat fisik memerlukan host yang dapat
diakses perangkat dan konfigurasi release HTTPS.

## Batas penerapan

- Source backend yang dipakai adalah GitHub `main` pada `524f554`; branch mobile
  lama yang disebut dokumen belum ditemukan pada remote yang tersedia. Versi
  deployment sebenarnya belum dapat dipastikan dari akses repo saja.
- Migrasi hanya diterapkan ke DB lokal pengujian. Backup/restore data operasional
  dan penerapan migrasi pada salinan data operasional belum dilakukan.
- Android fisik, secure storage native, dan kondisi jaringan perangkat belum diuji.
- Jemput, layar pembayaran pelanggan, push notification, serta penukaran poin
  dari aplikasi belum ditambahkan. Request rencana dalam koleksi Postman diberi
  penanda `[PLANNED]`.
- Ekosistem pembayaran masih memiliki simulasi verifikasi/saldo serta pekerjaan
  webhook/retry/otorisasi yang belum diselesaikan. Jalur debug/seed web lama juga
  perlu ditinjau sebelum deployment publik.
- Perubahan ini disiapkan sebagai commit lokal per repo. Belum push atau deploy.
