# Sparkleen 0.0.3 — penyempurnaan UI dan APK ARM64

12 November 2026 (WIB). Branch tetap `feat/glass-redesign-v0.0.2` agar semua perubahan redesign dapat diperiksa dalam satu branch. Versi aplikasi `0.0.3+3`. Perubahan kode hanya pada Sparkleen App; backend Laundry dan Payment API dipakai sebagai server uji lokal, tanpa perubahan kode produksi.

## Perubahan

- Notifikasi: **Hari ini di kiri**, **Tandai semua dibaca di kanan**, sesuai revisi terakhir. Judul diperpendek; titik dan semantik menandai pesan belum dibaca, tanpa label berulang pada tiap kartu. Hari ini/sebelumnya mengikuti WIB. Jumlah badge, baca satu pesan, batas ID baca semua, refresh dan pagination tetap memakai controller yang sama.
- Daftar notifikasi dan penjemputan memakai sliver sehingga kartu dibangun saat mendekati viewport. Permintaan awal tetap 20 entri; halaman lanjutan dimuat hanya setelah tombol pengguna. Aksi pembatalan penjemputan tetap di kanan.
- Form login, daftar, aktivasi, profil, penjemputan, konfigurasi server dan penukaran poin memakai label tetap di atas input. Fokus input dapat ditutup dengan tap di luar. PIN tetap enam digit, tersembunyi secara default, dan dapat diperlihatkan secara eksplisit.
- Layar sesi menambahkan ringkasan akun tersimpan tanpa membuka identitas akun sebelum unlock. Tombol fingerprint tetap berukuran normal di bagian bawah. Sensor dan dialog biometrik ditangani sistem Android.
- Halaman keamanan memisahkan buka sesi dan konfirmasi pembuatan tagihan. Konfigurasi server merangkum alamat aktif dan konsekuensi perpindahan server. Pengaturan menampilkan versi aplikasi yang sama dengan pubspec.
- Navigasi edit profil memakai GoRouter, sehingga tetap mengikuti pengalihan sesi yang sama dengan halaman privat lainnya.
- Detail pesanan memakai header ringkas dan akses nota sesudah ringkasan pembayaran. Pembayaran berhasil memakai `total_dibayar`, sehingga pembayaran kasir tanpa tagihan online aktif tidak ditampilkan sebagai Rp0. Status lunas tetap berasal dari backend.
- Tanggal penjemputan dan kalender mengikuti hari WIB, termasuk ketika zona waktu perangkat berbeda. Kontrol Material seperti kalender memakai bahasa Indonesia.
- Latar solid, biru, panel glass 87%, navigasi 88%, serta seluruh gambar WebP dari redesign sebelumnya dipertahankan. Gambar layanan dipetakan berdasarkan alias nama maupun asset key; thumbnail tersedia pada pesanan/detail, nota memakai identitas brand.
- Batas memori Gradle menjadi 3 GB dengan dua worker. Versi Flutter, AGP 9.1.0, Kotlin 2.4.0 dan Gradle 9.3.1 dipertahankan.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Flutter analyzer | Bersih |
| Tes unit/widget | 157 lulus |
| Uji lanjutan setelah penyempurnaan sesi/form | 64 lulus |
| Screenshot aktual Flutter | 24 skenario × 2 tema; gambar dan font dimuat sebelum capture; scroll setiap halaman diperiksa |
| Ukuran layar/teks | 320/360/390/412, skala 1/1,5/2, terang dan gelap |
| APK preview ARM64 release | Build berhasil; 20.492.405 byte (20,49 MB), versi 0.0.3, versionCode 2003 |
| Isi dan integritas APK | Signature v2, ZIP valid, seluruh 10 WebP + 8 font, library ARM64, channel biometrik dan secure storage terkonfirmasi |
| Alignment APK/ELF | ZIP dan ketiga library native lolos pemeriksaan 16 KB |
| HTTP Dart → Laundry → Payment API | Lulus: buat, lanjutkan, batal, pembayaran dan pemulihan callback hilang, isolasi akun |
| HTTP poin/notifikasi → kasir | Lulus: penukaran, nota, pembayaran, baca semua dengan cutoff ID dan isolasi akun |
| HTTP penjemputan → kasir → pesanan | Lulus: permintaan jemput terhubung ke pesanan, termasuk isolasi akun |

Regresi tambahan menguji pembayaran kasir dengan `nominal=0` tetapi `total_dibayar=38500`, posisi tombol notifikasi, daftar notifikasi panjang yang tidak membangun seluruh kartu sekaligus, dan kalender WIB di batas hari/tahun. Tes Poin → Pilih pesanan tetap dijalankan sebelum tab Pesanan pernah dibuka.

Perintah pemeriksaan screenshot:

```bash
flutter test tool/capture_redesign_audit_test.dart --dart-define=APP_PREVIEW=true
```

Contoh hasil capture (bukan mockup): [beranda terang](screenshots/v0.0.3/home-light.webp), [beranda gelap](screenshots/v0.0.3/home-dark.webp), [notifikasi terang](screenshots/v0.0.3/notifications-light.webp), dan [notifikasi gelap](screenshots/v0.0.3/notifications-dark.webp).

Capture memakai data fiktif dan tidak terhubung ke server produksi. Hasil ditulis di `../.tooling/ui-qa-v003/` dari root repo. QR pada capture adalah kode QA yang tidak dapat digunakan untuk pembayaran.

## Build untuk pengujian Android

```bash
flutter pub get
flutter build apk --release --flavor preview --dart-define=APP_PREVIEW=true --target-platform=android-arm64 --split-per-abi --split-debug-info=build/symbols/0.0.3
```

APK berada di `build/app/outputs/flutter-apk/app-arm64-v8a-preview-release.apk`. Arsitektur ARM64 sesuai Xiaomi 14T. Ganti server melalui gear sebelum login atau Profil → Pengaturan → Konfigurasi server. Gunakan HTTP hanya untuk IP privat server lokal; gunakan HTTPS untuk server internet.

SHA-256 APK: `5f51b167742657114a4c5d5c2a1e81b063af340d5222acfd85bccfc2265843e9`.

APK preview memakai identitas `com.sparkleen.sparkleen_mobile.preview` dan debug signing untuk pengujian internal. Build produksi memerlukan keystore milik pemilik dan tetap ditolak oleh guard build sampai signing produksi dikonfigurasi.

APK build laptop biasanya memakai debug keystore laptop sendiri. Jika Android menolak pembaruan karena signature berbeda, hapus hanya aplikasi **Sparkleen Preview** lama lalu instal APK ini. Ini menghapus sesi/pengaturan lokal dan mengharuskan login serta pengaturan server ulang; data pesanan pada backend tetap ada.

## Batas verifikasi

Tidak ada perangkat Android fisik terhubung. Keberhasilan build, pemeriksaan isi paket, tes widget dan HTTP tidak membuktikan sensor fingerprint, keyboard OEM, instalasi/update, performa blur, atau lifecycle pada semua HP. Uji manual tetap diperlukan: login → jemput → kasir → tukar poin → bayar simulasi → nota, tema persisten, unlock batal/sukses, fallback PIN, background, dan pergantian server.
