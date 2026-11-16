# Jemput laundry: pengajuan, riwayat dan antrean kasir

10 November 2026. Branch App dan Laundry: `feat/pickup-requests`.

## Yang sudah diterapkan

Dari kartu **Jemput laundry** di beranda, pelanggan membuka riwayat lalu memilih
**Ajukan penjemputan**. Form berisi layanan, perkiraan berat, alamat dari profil,
tanggal, slot WIB dan catatan. Alamat dapat disesuaikan untuk permintaan ini tanpa
mengganti alamat profil. Tidak memerlukan gambar baru; gaya solid, AppCard glass
padat dan paket artwork existing dipertahankan, termasuk ilustrasi kosong laundry.

Slot yang ditawarkan mulai pukul 08.00, 12.00 atau 15.00 WIB. Tanggal hingga 30 hari
ke depan; server menolak slot yang sudah lewat. Ketersediaan dipastikan outlet.
Perkiraan bukan tagihan: berat aktual serta harga layanan saat diterima di outlet
menjadi sumber biaya transaksi. Harga, poin atau ID pelanggan tidak dikirim dari form.

| Status | Tampilan/tindakan pelanggan |
| --- | --- |
| menunggu | Menunggu konfirmasi; bisa membatalkan lewat dialog |
| diproses | Penjemputan diproses; perubahan jadwal melalui outlet |
| dikonfirmasi | Cucian diterima; tombol membuka pesanan dan biaya akhir |
| ditolak | Alasan dari kasir terlihat; bisa mengajukan kembali |
| dibatalkan | Riwayat tetap ada; bisa mengajukan kembali |

Hanya satu permintaan menunggu/diproses per akun. Tombol pengajuan baru dinonaktifkan
saat riwayat memuat permintaan aktif, dan server tetap menegakkan batas itu saat
request bersamaan. Submit tidak dapat diulang selama proses; konflik server tampil
sebagai error yang dapat dibaca, bukan keberhasilan palsu.

Riwayat memiliki pull-to-refresh, retry error dan pagination. Data direset saat
sesi berubah; completion pagination dari akun lama tidak digabung ke akun berikutnya.
`id_transaksi` baru tersedia setelah kasir memproses dan menerima berat aktual.

## Backend pasangan

Empat endpoint `/api/v1/permintaan` sudah aktif pada branch pasangan. Endpoint
pelanggan tetap memerlukan Bearer dan membatasi data ke pemilik token. Antrean kasir
ada di `/penjemputan`, memakai sesi/role/CSRF web. Kasir/admin memproses, menolak dengan
alasan, atau menerima cucian dengan berat aktual. Pemilik hanya membaca antrean.

Penerimaan memakai service transaksi POS existing. Status request dan transaksi/nota,
poin serta audit tindakan disimpan secara atomik. Konfirmasi ulang memakai transaksi
yang sama. Poin tidak ditebus otomatis, dan penjemputan tidak mengonsumsi inventaris.
Detail backend/migrasi ada pada `docs/pickup/implementation.md` di repo Laundry.

Migrasi baru: `2026-11-10-000002_CreatePickupRequests`. Verifikasi backup dan terapkan
pada salinan DB sebelum rollout. Memerlukan InnoDB serta CHECK yang didukung MySQL
8.0.16+ atau MariaDB. Deploy backend yang cocok sebelum app. Dokumen/Postman kini
menandai endpoint jemput tersedia; endpoint pembayaran pelanggan tetap rencana.

## Bukti verifikasi lokal

| Pemeriksaan | Hasil |
| --- | --- |
| Seluruh suite Laundry | 130 test, 592 assertions lulus |
| Test backend jemput | 11 test, 96 assertions lulus |
| Seluruh suite Flutter | 94 test lulus |
| Test Flutter jemput baru | 10 test lulus |
| Flutter analyze | Tanpa masalah |
| Integrasi Dart → HTTP PHP → MariaDB | Lulus |
| Build web release | Berhasil, 59,4 detik; URL compile contoh HTTPS, bukan deployment |

Test baru meliputi form dengan berat koma, alamat profil, satu submit, konflik
server, dialog pembatalan, alasan penolakan/status diproses, completion akun lama,
dan layout lebar 320 px pada tema terang/gelap dengan text scale 1,0 dan 1,8.
Pengujian redesign existing juga tetap berjalan pada berbagai lebar/text scale.

Uji HTTP memakai repository Dart/Dio sebenarnya serta server CodeIgniter dan
MariaDB lokal. Pengganti hanya penyimpanan token perangkat. Alur: login → buat
permintaan → pengajuan ganda ditolak → service kasir proses/terima dengan berat
aktual → detail/nota sesuai → permintaan berikutnya dibatalkan → akun B tidak bisa
melihat/membatalkan permintaan A. Tidak ada panggilan WhatsApp/payment operasional.

Jalankan ulang setelah fixture dan server lokal siap:

```sh
flutter analyze
flutter test
flutter test tool/pickup_integration_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:42525
```

Set `LAUNDRY_TEST_ROOT` dan `TEST_PHP_BIN`; helper hanya menerima database disposable
lokal `laundry_db_test`. Jangan arahkan tool ke database/URL operasional. Test biasa
tidak menghubungi backend hidup. Untuk build gunakan URL HTTPS backend yang telah
memuat API dan migrasi, tanpa menambahkan `/api/v1` pada `API_BASE_URL`.

## Batas tahap ini

Belum push/deploy, belum migrasi DB operasional atau uji Android fisik/secure storage
native. Tidak ada notifikasi otomatis, tracking kurir, perhitungan area/ongkos jemput,
atau layar pembayaran pelanggan baru. Outlet mengatur pemenuhan jemput melalui antrean.
