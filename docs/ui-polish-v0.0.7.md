# Sparkleen 0.0.7 — penyempurnaan visual

Perubahan hanya pada Sparkleen App, branch `feat/glass-redesign-v0.0.2`. Backend Laundry, Smart Pay, dan Payment API tidak berubah dari rilis 0.0.6. Fitur alamat tetap membutuhkan backend alamat 0.0.6 yang sudah menjalankan migration.

## Yang dipoles

- Panel glass tetap opacity 75%, latar solid, dan aksen biru. Tepi panel lebih tipis, bayangan lebih lembut, serta sudut input menjadi 18 dp. Separator lebih ringan tanpa menurunkan kontras teks utama.
- Semua peran teks menggunakan Inter lokal. Bobot teks isi ditentukan eksplisit agar tidak mewarisi bobot dari elemen induk. Line-height teks kecil diperbaiki untuk nomor, alamat, dan keterangan.
- Beranda memiliki jarak header yang lebih jelas, hero jemput dengan judul serta ilustrasi responsif, chip poin kapsul tanpa bayangan berlebih, dan area sentuh chip/CTA setidaknya 48 dp. Status dan nomor nota memakai sisi berlawanan; Detail tetap di kanan bawah. Harga layanan diberi bobot lebih kuat, ilustrasi layanan sedikit dipadatkan.
- Profil menampilkan kode pelanggan tanpa kalimat berulang. Tautan Ubah profil memiliki area sentuh 48 dp. Footer merek yang berulang dihapus. Baris pengaturan/profil memiliki tinggi minimum 56 dp dan ikon 22 dp, sambil tetap berkembang pada teks besar.
- Aksi Detail pada kartu daftar pesanan disamakan dengan beranda: teks ringkas dan chevron. Status tetap teks polos berwarna sesuai keadaan.
- Form alamat menampilkan contoh label, alamat, dan patokan; penghitung karakter yang selalu tampil dihapus. Batas panjang, validasi, dan pesan kesalahan tetap berjalan.

## Koreksi placeholder

`AppTextFormField` sebelumnya mengubah label internal menjadi string kosong. Flutter tetap menganggapnya label inline, sehingga placeholder tidak terlihat sebelum input difokuskan. Komponen kini meniadakan label internal sambil mempertahankan label tetap di atas input, semantik, prefix/suffix, helper, counter, serta dekorasi error. Contoh nomor telepon dan PIN langsung terbaca sejak halaman dibuka.

## Verifikasi visual dan layout

Capture merender 27 halaman × 2 tema dengan font dan aset aplikasi. Binding capture kini memakai blur bayangan produksi; binding tes standar menonaktifkan blur dan membuat bayangan terlihat seperti lapisan kartu keras. Gambar hasil kode disimpan sebagai WebP, bukan mockup generatif.

189 tes unit/widget lulus, termasuk konfigurasi `APP_PREVIEW=true` yang dipakai APK. Analyzer bersih. Matriks layout memakai Inter asli pada lebar 320/360/390/412 dp dan skala teks 1/1,5/2, termasuk scroll konten panjang. Regresi placeholder memeriksa visibilitas sebelum fokus, label/adornment, pengetikan, dan validasi error. Pengujian CRUD, sesi, pembayaran, serta navigasi yang sudah ada tetap dijalankan. Capture memakai flag preview yang sama; nilai akun pada capture adalah data demonstrasi.

Lihat [tema terang](screenshots/v0.0.7/Sparkleen-0.0.7-UI-light.webp) dan [tema gelap](screenshots/v0.0.7/Sparkleen-0.0.7-UI-dark.webp).

## Build

```bash
flutter pub get
flutter analyze
flutter test --dart-define=APP_PREVIEW=true
flutter build apk --release --flavor preview --dart-define=APP_PREVIEW=true --target-platform=android-arm64 --split-per-abi --split-debug-info=build/symbols/0.0.7
```

Preview ARM64, versi `0.0.7+7`. Keberhasilan tes otomatis dan capture tidak menggantikan pengujian fingerprint, keyboard, serta performa blur pada Android fisik.

Build release dan lint Android lulus. APK berukuran **20.600.049 byte (20,6 MB)**, versionCode `2007`, minimum SDK 24, target SDK 36. Pemeriksaan ZIP, signature v2, alignment ZIP/ELF 16 KB, font Inter/Phosphor lokal, 12 WebP, channel biometrik, dan secure storage lulus. AOT dibuat setelah perubahan UI final dan berbeda dari AOT 0.0.6.

SHA-256 APK: `bc5ccfee60fd13f1d644cc0758694f1722a3bcda192cf2455d6191b9e0847661`.

Sertifikat SHA-256 `4a716d04db8ec185a24f364bf2c41d82baa3de3bb0b9e85f787e79c6e73578ef`, sama dengan APK 0.0.6 yang dibagikan. APK ini dapat diperbarui di atas APK 0.0.6 tersebut tanpa uninstall; APK hasil build sendiri atau versi lebih lama dapat memakai sertifikat berbeda.
