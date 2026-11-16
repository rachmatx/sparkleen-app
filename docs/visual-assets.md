# Integrasi aset visual Sparkleen

Paket pertama berisi sembilan PNG master dengan gaya biru/putih dan objek laundry yang konsisten.

| Aset | Pemakaian |
| --- | --- |
| `assets/brand/sparkleen_mark.webp` | Header, auth, splash, nota; sumber ikon Android/web |
| `assets/brand/badge_points.webp` | Poin pada beranda dan profil |
| `assets/illustrations/home_laundry.webp` | Kartu sapaan beranda |
| `assets/illustrations/auth_laundry.webp` | Login pada viewport tinggi ketika keyboard tertutup |
| `assets/illustrations/empty_active_order.webp` | Pesanan aktif kosong |
| `assets/illustrations/empty_order_history.webp` | Riwayat/daftar pesanan kosong |
| `assets/illustrations/error_connection.webp` | Error dengan kode `NETWORK_ERROR` |
| `assets/services/service_cuci_kering.webp` | Layanan Cuci Kering |
| `assets/services/service_cuci_setrika.webp` | Layanan Cuci & Setrika |

## Perilaku komponen

- `BrandMark` memakai satu sumber logo di seluruh halaman.
- `AppArtwork` membatasi ukuran decode berdasarkan ukuran tampilan dan DPR, mempertahankan rasio gambar, mengecualikan dekorasi dari pembaca layar, dan menampilkan ikon cadangan jika gambar gagal dimuat.
- `IllustrationPanel` memakai permukaan pale blue yang sama di kedua tema. Master raster masih memiliki sedikit tepi putih; panel ini memberi kontras yang konsisten tanpa memodifikasi gambar sumber.
- Hero beranda digabung dengan sapaan agar kartu pesanan tetap dekat bagian atas. Saat ukuran teks besar, susunannya berubah menjadi kolom.
- Ilustrasi login menjadi aksen 76 × 84 di samping intro; disembunyikan ketika keyboard terbuka atau teks diperbesar melewati ambang layout. Form daftar dan aktivasi memakai logo yang sama tanpa menambah hero. Ilustrasi beranda menjadi aksen ringkas, bukan kartu hero tersendiri.
- Ilustrasi koneksi hanya muncul pada error jaringan. Error validasi/server tetap menampilkan pesan aslinya dan ikon error.
- Ikon navigasi dan kontrol tetap menggunakan Material Icons.

## Katalog layanan

Model `Layanan` mendukung field opsional `asset_key`, tanpa mewajibkan perubahan backend:

| `asset_key` | Gambar |
| --- | --- |
| `cuci_kering` | Cuci Kering |
| `cuci_setrika` | Cuci & Setrika |

Untuk respons lama tanpa `asset_key`, pemetaan hanya menerima nama yang dikenal: `Cuci Kering`, `Cuci & Setrika`, `Cuci dan Setrika`, dan `Cuci Setrika` (huruf besar/kecil dan spasi dinormalisasi). Tidak ada asumsi mengenai ID layanan produksi. Nama atau key yang tidak dikenal mendapatkan ikon generik; pencarian substring tidak digunakan agar layanan baru tidak mendapat gambar yang keliru.

## Ikon platform

Konfigurasi `flutter_launcher_icons.yaml` membangun ulang ikon launcher Android, adaptive icon, ikon PWA, dan favicon dari logo master. Jalankan setelah mengganti logo:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Splash native Android menggunakan latar royal blue dan logo launcher. Android 12+ menggunakan atribut splash platform; layar Flutter melanjutkan identitas yang sama. Folder iOS tidak tersedia pada proyek ini sehingga tidak dibuatkan konfigurasi iOS.

## Pemeriksaan

```bash
flutter analyze
flutter test
flutter build web --release
```

Uji tambahan meliputi bundel sembilan gambar, fallback file hilang, lebar ilustrasi yang mengikuti parent, pemilihan gambar error jaringan, dan pemetaan layanan dengan key/nama yang tidak dikenal. Verifikasi perangkat Android tetap diperlukan sebelum rilis APK ke pengguna.

Untuk mengambil screenshot dengan repository demo dan font sebenarnya:

```bash
flutter test tool/capture_assets_test.dart
```

Hasil berada di `build/visual-review/`. Tool ini secara eksplisit memuat Google Fonts publik dan mock direktori cache font; suite `flutter test` biasa tetap menggunakan isolasi HTTP bawaan. Tidak ada data pelanggan produksi yang dimuat. Tambahkan `--dart-define=VISUAL_OUTPUT=docs/screenshots` jika ingin memperbarui screenshot dokumentasi.

Integrasi ini tidak menambahkan fitur jemput, checkout, penukaran poin, promosi, atau pemrosesan gambar baru.
