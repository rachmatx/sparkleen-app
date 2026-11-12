# Sparkleen 0.0.5 — status, layanan, dan glass

Versi `0.0.5+5`, branch `feat/glass-redesign-v0.0.2`. Perubahan hanya di Sparkleen App.

## Status dan tata letak

- Penanda status pada pesanan, pembayaran, nota, dan penjemputan memakai teks berwarna, tanpa latar atau dot. Menunggu berwarna amber, proses biru, selesai/lunas hijau, ditolak/dibatalkan merah. Tema gelap memakai warna yang lebih terang. Badge jumlah notifikasi tetap ada karena menunjukkan hitungan, bukan status pesanan.
- Delta poin dan tanggal berada di tepi kanan konten kartu, tanpa ruang chevron setelahnya. Pada teks besar, keduanya pindah ke baris bawah dengan posisi tetap rata kanan agar tidak bertabrakan dengan nomor nota.
- Glass tetap memakai opacity 75%, background solid, dan aksen biru. Blur panel 18, navigasi 24; sudut kartu 24, input 16, sheet 32. Navigasi berbentuk kapsul dengan pilihan aktif membungkus ikon sekaligus label. Animasi perpindahan menghormati pengaturan reduced motion.
- Inter lokal dan aset WebP versi 0.0.4 tetap digunakan. Tidak ada gambar atau font baru yang diunduh saat aplikasi dibuka.

## Perjalanan cucian

Timeline pelanggan diproyeksikan dari `items[].nama_layanan` pada rincian pesanan. Tidak menebak layanan berdasarkan ID dan tidak mengubah transaksi di server.

| Layanan | Tahap sebelum siap diambil |
| --- | --- |
| Cuci Reguler / Regular / Kering / Kilat / Tanpa Setrika | Diterima → Dicuci |
| Cuci + Setrika, Cuci & Setrika, Cuci dan Setrika | Diterima → Dicuci → Disetrika |
| Setrika Saja | Diterima → Disetrika |
| Pesanan campuran layanan yang dikenal | Gabungan tahap layanan yang dipilih |

Tahap siap diambil dan selesai/pengambilan dipertahankan. Bila server lama menandai Cuci Reguler sebagai `setrika`, pelanggan melihat “Diproses” pada tahap cuci sampai status berikutnya, tanpa menampilkan layanan setrika yang tidak dipesan. Timestamp asli tahap tetap dipakai; waktu baru tidak dibuat-buat. Data timeline dan status mentah tetap tersedia pada model.

Endpoint daftar di server lama belum menyertakan nama layanan. Ringkasan tersebut memakai Diterima → Proses → Siap, sehingga tidak menjanjikan tahap setrika. Jika API menyertakan `nama_layanan` atau `items`, ringkasan otomatis memakai tahap layanan yang diketahui. Status proses pada ringkasan tanpa rincian layanan juga memakai label umum “Diproses”. Tidak menambah satu request detail untuk setiap kartu daftar.

Layanan tidak dikenal atau tahap API baru tetap memakai timeline server secara konservatif. Layanan khusus perlu metadata workflow eksplisit di backend sebelum dapat disederhanakan dengan aman. Patch ini tidak mengubah workflow operasional kasir.

## Verifikasi

- 180 tes unit/widget lulus, termasuk variasi layanan, pesanan campuran, status lama yang tidak sesuai, waktu asli, status teks pada kedua tema, dan koordinat tepi kanan poin pada skala teks 1/1,8.
- Matriks layout yang sudah ada tetap meliputi lebar 320/360/390/412, skala teks 1/1,5/2, navigasi Poin → Pesanan, pembayaran, autentikasi, dan pagination.
- Dua tes capture menyelesaikan 25 skenario × 2 tema dengan font dan aset asli, termasuk dua detail dengan layanan berbeda; scroll diperiksa.
- Analyzer bersih. Lihat [hasil terang](screenshots/v0.0.5/Sparkleen-0.0.5-UI-light.webp) dan [hasil gelap](screenshots/v0.0.5/Sparkleen-0.0.5-UI-dark.webp). Data dalam capture adalah data demonstrasi.

## Build ulang di komputer sendiri

```bash
flutter pub get
flutter analyze
flutter test --dart-define=APP_PREVIEW=true
flutter build apk --release --flavor preview --dart-define=APP_PREVIEW=true --target-platform=android-arm64 --split-per-abi --split-debug-info=build/symbols/0.0.5
```

Build preview tetap menggunakan debug signing internal. Instalasi pembaruan membutuhkan sertifikat penandatangan yang sama dengan APK sebelumnya. Pengujian fingerprint, lifecycle OEM, keyboard, dan performa glass saat scroll tetap memerlukan HP fisik.


## Hasil paket Android

Build `assemblePreviewRelease` berhasil; pemeriksaan lint release juga selesai. APK ARM64 berukuran **20.531.250 byte (20,53 MB)**. Package `com.sparkleen.sparkleen_mobile.preview`, version name `0.0.5`, versionCode `2005`, minimum SDK 24, target SDK 36. Paket hanya berisi library ARM64.

Verifikasi ZIP, tanda tangan APK v2, alignment ZIP/ELF minimal 16 KB, empat bobot Inter, 12 WebP (byte sama dengan source), channel biometrik, dan plugin secure storage lulus. Simbol debug dipisahkan dari APK.

SHA-256 APK: `5ddaaaa9ec60d8cfa23deab37b38a0b4fbecb9ead64fce28490173b7b0938a4d`.

**Sertifikat preview baru:** sertifikat build ini berbeda dari APK 0.0.4 yang sebelumnya dibagikan. Android tidak menerima pembaruan di atas APK dengan penandatangan berbeda. Untuk mengganti APK lama itu, catat alamat server dan lakukan instal ulang; konfigurasi server lokal serta biometrik perlu diatur kembali. Data akun/pesanan di server tidak dihapus oleh instal ulang aplikasi. Build sendiri dengan keystore yang sama seperti build sebelumnya dapat mempertahankan kompatibilitas pembaruan.

Tes otomatis dan pemeriksaan paket tidak menggantikan pengujian fingerprint serta performa glass pada HP fisik.
