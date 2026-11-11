# Sparkleen Android preview 0.0.1

Branch: `feat/app-stability-biometrics-v0.0.1`. Perubahan tahap ini hanya pada repository `sparkleen-app`.

## Perubahan

- Startup dengan token tersimpan membedakan sesi habis (401) dari jaringan/backend yang sementara tidak tersedia. Kegagalan sementara menawarkan retry tanpa menghapus sesi.
- Refresh profil/poin, pesanan, permintaan jemput, dan notifikasi dipusatkan; permintaan bersamaan digabung. Refresh mempertahankan profil dan filter pesanan. Hasil dari akun/server lama tidak boleh menimpa sesi baru.
- Android menggunakan `BiometricPrompt` dengan `BIOMETRIC_STRONG` melalui method channel. Login pertama tetap memakai PIN akun. Akses biometrik hanya membuka sesi tersimpan yang kemudian diverifikasi backend.
- Preferensi biometrik terikat pada token sesi dan disimpan dengan Flutter Secure Storage. Logout dan pergantian server menghapus preferensi. Data sidik jari tidak dibaca/disimpan oleh aplikasi.
- Saat aplikasi berada di latar belakang, tampilan akun biometrik ditutup. Setelah satu menit di background, pengguna harus membuka sesi kembali. Pembatalan/interupsi prompt tidak membuat tagihan.
- Konfirmasi biometrik pembayaran bersifat opsional dan lokal sebelum pembuatan tagihan; status pembayaran tetap milik backend. Integrasi uang nyata belum diaktifkan.
- Flavor `preview` menyediakan pengaturan alamat backend laptop, suffix package `.preview`, serta HTTP LAN. Flavor `production` menolak cleartext; build produksi diblokir sampai signing pemilik tersedia.
- Font UI dibundel beserta lisensinya agar tidak bergantung pada unduhan saat runtime. Gaya background solid dan kartu hampir opak dipertahankan.

## Validasi

- `flutter analyze`: tidak ada temuan.
- `flutter test --dart-define=APP_PREVIEW=true`: **149 tes lulus**.
- Integrasi HTTP Dart → PHP → MariaDB: **1 skenario lulus**, meliputi penukaran poin, pembayaran kasir, inbox, dan isolasi akun. Fixture memakai database pengujian terpisah.
- Cakupan baru: pemulihan sesi offline/5xx, 401, logout dan pergantian akun saat request/prompt masih berjalan, biometrik batal, pencegahan invoice setelah sesi berganti, validasi server LAN, penguncian setelah background, refresh gabungan, serta layout lebar 320 px dengan skala teks 1,8 pada tema terang/gelap.
- Enam screenshot halaman keamanan, pemulihan sesi, dan server tersedia di `docs/screenshots/v0.0.1/`; native biometrik dimock dalam pengambilan screenshot.
- Native Android compilation dan publikasi APK dijalankan oleh `.github/workflows/android-preview.yml`. Keberhasilan tes Dart tidak menyatakan build Android berhasil; periksa hasil workflow dan release sebelum memasang.

## Batas pengujian

Belum ada perangkat Android fisik yang terhubung dalam lingkungan pengembangan. Sensor fingerprint, prompt sistem, secure storage native, instalasi APK, koneksi Wi-Fi laptop, dan lifecycle OEM wajib diuji manual. Versi ini adalah prerelease internal dengan debug signing, bukan distribusi Play Store. Panduan pengguna dan checklist ada di `v0.0.1.md`.
