# Verifikasi Android dan rilis Sparkleen App

10 November 2026. Kandidat: branch `feat/customer-api-foundation`, fondasi app
`c56b6b7`. Test Dart/HTTP sebelumnya memakai penyimpanan token pengganti, sehingga
belum membuktikan plugin secure storage pada Android.

## Hasil pemeriksaan lingkungan saat ini

Java 21 tersedia, tetapi Android SDK, `adb`, emulator dan akses perangkat fisik
belum tersedia. Tidak ada APK Android baru, hasil uji secure storage native, atau
hasil uji background/jaringan yang dapat dinyatakan lulus dari lingkungan ini.
Pemeriksaan perangkat melalui Flutter juga belum menghasilkan inventaris yang
berhasil, sehingga ketiadaan perangkat tidak dianggap hasil test aplikasi.

## Menyiapkan perangkat di Windows

1. Siapkan Android SDK melalui Android Studio, aktifkan USB debugging, hubungkan
   perangkat, lalu terima otorisasi USB pada perangkat.
2. Di repo, jalankan:

   ```powershell
   flutter doctor -v
   flutter devices
   flutter pub get
   flutter run --debug -d DEVICE_ID --dart-define=API_BASE_URL=https://BACKEND_HTTPS
   ```

   Ganti `DEVICE_ID` dan `BACKEND_HTTPS` dengan target nyata. Base URL tidak
   menyertakan `/api/v1`. Untuk emulator Android yang mengakses backend lokal di
   Windows, gunakan `http://10.0.2.2:8080` pada build debug. Untuk HP fisik, gunakan
   alamat host yang dapat dijangkau HP; `10.0.2.2` adalah alias emulator.
3. Backend harus memuat migrasi dan endpoint pelanggan. Pakai akun/data pengujian;
   jangan menambahkan token merchant/GitHub ke aplikasi.

## Daftar uji perangkat yang belum dijalankan

| Uji | Bukti yang harus dicatat | Status |
| --- | --- | --- |
| Login akun A | Profil dan order sesuai akun | Belum diuji |
| Tutup paksa dan buka kembali | Token native tersimpan; sesi kembali sesuai akun | Belum diuji |
| Background lalu kembali | UI dan sesi tetap konsisten | Belum diuji |
| Logout lalu buka kembali | Tetap di layar masuk; token lama ditolak backend | Belum diuji |
| Ganti akun A → B | Order/detail/nota A tidak tersisa | Belum diuji |
| Token dicabut pada server | Request privat berikutnya mengakhiri sesi | Belum diuji |
| Matikan/nyalakan jaringan | Pesan error/retry jelas; data pulih setelah refresh | Belum diuji |
| Kasir memperbarui status | Refresh HP menampilkan perubahan yang sama | Belum diuji |
| Tema terang/gelap | Teks, layanan, detail, nota dan aset terbaca | Belum diuji |
| Keyboard dan ukuran teks besar | Form/tombol tetap dapat dipakai tanpa overflow | Belum diuji |

Catat model perangkat, Android, commit kedua repo, base URL staging dan screenshot
hasil tanpa PIN/token. Jangan memberi tanda lulus sebelum uji perangkat dilakukan.

## Penghalang APK produksi

`android/app/build.gradle.kts` masih mengarahkan release ke signing config debug.
Keystore rilis pemilik belum tersedia dan tidak dibuat otomatis pada sesi ini.
Sebelum distribusi, konfigurasi signing rilis dengan keystore pemilik dan simpan
`android/key.properties`/keystore secara privat; keduanya sudah diabaikan Git.

Setelah signing dan seluruh uji di atas lulus:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://BACKEND_HTTPS
```

APK internal dapat dibuat dengan `flutter build apk --release` setelah konfigurasi
signing yang sama siap. Verifikasi application ID dan versionCode terhadap aplikasi
terpasang/Play Console sebelum mengunggah. Jangan menimpa identitas aplikasi atau
membuat signing key pengganti untuk aplikasi yang sudah pernah dirilis.

Backend dan database operasional belum teridentifikasi dari repo saja. Push dan
rilis perlu koneksi GitHub serta target hosting yang tepat. Tahap Android belum
selesai; dokumen ini menyediakan langkah dan bukti yang masih diperlukan.
