# Sparkleen 0.0.6 — alamat tersimpan dan navigasi ringkas

Versi `0.0.6+6`. Sparkleen App berada di `feat/glass-redesign-v0.0.2`; backend Sparkleen Laundry berada di `feat/customer-addresses-v0.0.6`. Smart Pay dan Payment API tidak berubah.

## Alamat penjemputan

Profil → Alamat penjemputan membuka daftar alamat milik akun aktif. Pengguna dapat menambah, membaca, mengubah, menghapus, dan memilih alamat utama. Setiap alamat memiliki label, alamat lengkap, dan patokan opsional. Penghapusan membutuhkan konfirmasi. Alamat utama berikutnya dipilih otomatis jika alamat utama lama dihapus. Menghapus alamat terakhir diperbolehkan; form penjemputan kemudian meminta alamat baru.

Form penjemputan memilih alamat dari daftar tersebut, mengisi alamat utama terlebih dahulu, dan mengirim `id_alamat`. Server membaca alamat milik pelanggan; teks alamat yang dikirim klien tidak dapat menggantikan alamat tersimpan ketika ID dipakai. Alamat dan patokan disalin ke permintaan penjemputan. Perubahan atau penghapusan alamat tersimpan tidak mengubah permintaan yang sudah dibuat.

Daftar memuat paling banyak 20 alamat per halaman dengan tombol memuat halaman berikutnya; maksimal 50 alamat per akun. Respons lama tidak dapat mengembalikan data akun sebelumnya setelah sesi/server berubah. Kesalahan simpan/hapus mempertahankan formulir/data dan menampilkan pesan server.

## Tampilan

- Navigasi normal setinggi 56 dp termasuk padding panel (sebelumnya 76 dp), ikon 20 dp dan label horizontal. Skala teks besar mendapat tata letak vertikal yang lebih tinggi agar tetap terbaca. Area sentuh minimum tetap 48 dp.
- Ikon aplikasi memakai Phosphor Regular dan tiga varian Fill untuk navigasi terpilih, berlisensi MIT. Font subset lokal berukuran sekitar 17 KB, tanpa paket atau unduhan ikon saat runtime. Dialog biometrik sistem tetap mengikuti Android.
- Sumber ikon: `https://github.com/phosphor-icons/web`, commit `3d40a3eaa73b25d20d263f0e1e55c9fed3e66809`. Lisensi disertakan di `assets/icons/LICENSE-Phosphor.txt`.
- Riwayat penjemputan memakai chevron yang konsisten. Ketuk kartu untuk rincian; tautan pesanan yang sudah diterima tersedia di rincian. Pembatalan memakai ikon tempat sampah di kanan atas kartu aktif dan tetap membutuhkan konfirmasi.
- Aksi Detail pada pesanan aktif berada di kanan bawah kartu. Instruksi berulang pada penjemputan dihapus. Glass 75%, latar solid, aksen biru, Inter lokal, serta gambar WebP dipertahankan pada kedua tema.

## Layanan baru di aplikasi kasir

Tambahkan layanan aktif bernama persis **Setrika Saja**, satuan **kg**. Tentukan harga dan estimasi sesuai operasional outlet. Aplikasi pelanggan mengambil katalog dari API; tidak menyisipkan layanan atau harga palsu. Nama tersebut memilih ilustrasi setrika dan perjalanan Diterima → Disetrika → Siap Diambil → Selesai. Backend/kasir tetap menentukan status operasional.

## Urutan pembaruan

1. Perbarui Sparkleen Laundry ke branch backend di atas; cadangkan database operasional.
2. Jalankan `php spark migrate` dari direktori Sparkleen Laundry. Migration membuat `tb_alamat_pelanggan`, mengimpor alamat profil lama sekali, serta menambah snapshot patokan penjemputan. Tidak menjalankan seeder demo pada database asli.
3. Tambahkan layanan Setrika Saja di kasir.
4. Instal APK 0.0.6 dan arahkan ke server Laundry yang sudah diperbarui. Backend lama belum menyediakan endpoint alamat.

## Verifikasi

- 167 tes backend / 866 assertions lulus pada database MySQL terisolasi, termasuk isolasi pemilik, pergantian alamat utama, penghapusan terakhir, pagination, snapshot, dan rollback transaksi saat penulisan profil gagal.
- Pengujian HTTP memakai repository Dart asli → CodeIgniter → MySQL: login, CRUD alamat, sinkronisasi profil, penjemputan dengan alamat tersimpan, penghapusan, dan penolakan akses akun lain lulus.
- 188 tes unit/widget lulus; analyzer bersih. Cakupan meliputi CRUD, kegagalan hapus, simpan ganda, pergantian sesi, pagination, dan layout 320 dp dengan teks 1×/2× pada kedua tema.
- Capture UI merender 27 skenario × 2 tema dengan font dan aset aplikasi, bukan gambar rancangan. Data pada capture adalah demonstrasi.

Lihat [hasil terang](screenshots/v0.0.6/Sparkleen-0.0.6-UI-light.webp) dan [hasil gelap](screenshots/v0.0.6/Sparkleen-0.0.6-UI-dark.webp).

## Build ARM64

```bash
flutter pub get
flutter analyze
flutter test --dart-define=APP_PREVIEW=true
flutter build apk --release --flavor preview --dart-define=APP_PREVIEW=true --target-platform=android-arm64 --split-per-abi --split-debug-info=build/symbols/0.0.6
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-preview-release.apk`. Simpan simbol terpisah. Preview menggunakan signing internal; pembaruan di atas APK lama hanya diterima Android jika sertifikat sama. Fingerprint, keyboard, lifecycle OEM, dan kelancaran blur tetap perlu diuji pada HP fisik.
