# Tahap 4 — notifikasi dan penukaran poin

Implementasi lokal pada `feat/notifications-loyalty`, 10 November 2026. Melanjutkan
pembayaran tahap 3; belum push/deploy. Firebase/FCM dan push OS saat app tertutup
**belum diimplementasikan**. Yang tersedia adalah inbox tersimpan di server.

## Cara memakai

- Beranda → ikon lonceng: pembaruan pesanan, jemput, pembayaran dan penukaran.
  Buka pesan untuk menuju pesanan/riwayat jemput. Ada unread badge, tandai semua,
  pagination, pull-to-refresh, dan error/retry yang tidak mengaku sudah dibaca.
- Profil → Tukar dan riwayat poin: saldo server dan riwayat perubahan baru.
- Detail pesanan → Gunakan poin: pilih jumlah, tinjau potongan/sisa/saldo, lalu
  konfirmasi. Hanya sebelum pembayaran pertama dan tanpa tagihan online aktif.
  Satu penukaran per pesanan; tidak dapat dibatalkan melalui aplikasi.

1 poin tetap Rp300. Karena sistem existing memberi poin ketika order dibuat,
penurunan total belanja juga dapat menurunkan earned pesanan. Preview, dialog dan
riwayat menampilkan penyesuaian itu. Contoh total Rp35.000/saldo100/earned3,
tukar20 memberi diskonRp6.000, totalRp29.000/earned2/saldo79.

Riwayat dimulai sejak migrasi ini; saldo historis tetap ada. Harga, batas, saldo,
diskon dan perhitungan final tetap milik backend. Submit ulang saat koneksi putus
memakai request ID sama. Respons terlambat akun lama diabaikan. Sukses penukaran
memuat ulang profil, detail, nota, pembayaran dan ringkasan pesanan.

## Notifikasi

Pesan dan perubahan bisnis commit atomik. Repeat status/callback/redeem tidak
menghasilkan duplikat. Tidak menyertakan PIN, nomor, alamat atau instrumen bayar.
Unread badge dicek setiap 30 detik selama foreground; berhenti saat background,
memuat ulang saat resume. Inbox bisa di-refresh manual dan dibuka setelah offline.
Tandai semua menggunakan cutoff daftar yang dilihat, sehingga pesan baru tidak
terbaca secara tidak sengaja. Navigasi memakai target bertipe order/pickup/loyalty,
bukan URL bebas dari server.

Tema memakai permukaan glass existing, background solid, aset poin existing dan
warna/kontras terang-gelap. Font besar/lebar 320 px termasuk pemeriksaan widget.

## Server dan verifikasi

Gunakan backend Laundry dari tahap ini dan migrasi
`2026-11-10-000004_AddCustomerNotificationsAndLoyalty`. Rincian kontrak dan rollback
berada pada `sparkleen-laundry/docs/loyalty/notifications-and-points.md`. Payment API
serta Smart Pay tidak perlu perubahan tahap ini. Pembayaran tahap 3 tetap simulator.

```sh
flutter analyze
flutter test
flutter test tool/engagement_integration_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:42529
```

Uji HTTP opt-in membutuhkan backend localhost, database laundry_db_test disposable,
fixture mobile_demo.php reset lalu engagement_demo.php, dan env LAUNDRY_TEST_ROOT /
TEST_PHP_BIN. Tidak menggunakan pelanggan operasional, WA atau gateway nyata.

| Pemeriksaan | Hasil |
|---|---|
| Laundry full suite | 160 tests, 786 assertions lulus; 17 test tahap 4 |
| Flutter full suite | 124 tests lulus; 17 test tahap 4 |
| Flutter analyze | No issues found |
| HTTP Dart → PHP → MariaDB | Lulus: saldo/diskon/nota, kasir, jemput, inbox, retry dan isolasi akun |
| Web release build | Berhasil, 56,0 detik; URL HTTPS contoh, bukan deployment |

Race tests memakai worker/koneksi DB terpisah untuk request identik, dua order
merebut saldo sama, dan pembayaran kasir bersamaan dengan penukaran. Rollback
ketika insert notifikasi gagal juga diuji. Status tersimpan walau WhatsApp gagal.
Android fisik dan push OS belum diuji. Tidak ada token atau key baru yang dimasukkan ke aplikasi.
