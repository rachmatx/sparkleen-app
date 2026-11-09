# Implementasi UI/UX Sparkleen

9 November 2026 · branch `feat/sparkleen-visual-assets`

Desain yang disetujui sudah diterapkan pada widget Flutter. Background memakai warna solid; material kaca lebih padat, dan keterbacaan mode terang ditingkatkan. Kontrak API dan metode autentikasi tetap mengikuti aplikasi yang ada.

## Perubahan

- Tema terang/gelap: foreground eksplisit, teks pendukung lebih gelap, batas input lebih jelas, bobot huruf lebih tenang, label navigasi 13, dan permukaan kaca 95% / 96% dengan dock 98%. Latar bertekstur dihapus; tidak ada gradient pada UI.
- Beranda: merek dan poin ringkas, sapaan dengan ilustrasi kecil, status/estimasi di awal kartu pesanan, tahapan proses berlabel, dua kolom layanan yang beralih menjadi satu kolom pada ruang sempit/teks besar, serta informasi outlet dari API. Tombol penuh yang mengulang daftar pesanan dihapus.
- Interaksi: poin membuka profil; kartu pesanan membuka detail; layanan membuka sheet informasi; kontak outlet menyalin nomor WhatsApp dengan umpan balik. Tombol menyebutkan tindakan menyalin secara eksplisit.
- Masuk/daftar/aktivasi: field PIN bersama dengan tampil/sembunyikan, pembatasan enam angka, label aksesibel, dan pencegahan submit berulang termasuk melalui keyboard. Ilustrasi login berada di samping intro, disembunyikan ketika keyboard muncul atau teks diperbesar.
- Pesanan/detail/nota/profil/edit: tema dan material konsisten; daftar pesanan menonjolkan status serta estimasi; filter tetap memanggil controller dan mempertahankan pagination/retry. Timeline detail mengikuti data API. PIN pengambilan tetap tidak masuk nota digital.

## Penempatan gambar

Sembilan aset raster yang sudah diintegrasikan tetap digunakan. Master tidak diubah pada redesign ini.

| Aset | Penempatan |
| --- | --- |
| `sparkleen_mark.png` | Header masuk/beranda, splash, nota; ikon platform dari integrasi sebelumnya tetap tersedia |
| `badge_points.png` | Tombol poin beranda dan statistik profil |
| `home_laundry.png` | Aksen sapaan beranda |
| `auth_laundry.png` | Aksen intro masuk |
| `service_cuci_kering.png` | Kartu dan sheet layanan Cuci Kering |
| `service_cuci_setrika.png` | Kartu dan sheet layanan Cuci & Setrika |
| `empty_active_order.png` | Beranda/pesanan aktif kosong |
| `empty_order_history.png` | Riwayat pesanan kosong |
| `error_connection.png` | Error jaringan, terpisah dari error server/validasi |

Pemetaan layanan memakai `asset_key` atau alias nama yang dikenal; layanan lain memakai ikon generik. Alas gambar pale blue mempertahankan tepi master yang rapi pada kedua tema, dan gambar dekoratif dikecualikan dari pembaca layar.

## Verifikasi

- `flutter analyze`: tanpa masalah.
- `flutter test`: 78 test lulus, termasuk 50 baseline yang dipertahankan dengan penyesuaian pencarian label status yang sekarang juga muncul di indikator tahapan.
- Matrix layout: 9 layar × 4 lebar (320, 360, 390, 412) × 3 skala teks (1,0 / 1,5 / 2,0) × 2 tema. Setiap halaman digulir untuk memeriksa konten di bawah tampilan awal. Tidak ada exception/overflow pada pengujian ini.
- Interaksi baru: buka/tutup sheet layanan, salin nomor outlet, poin ke profil, filter pesanan, detail ke nota, tampil/sembunyikan PIN, pembatasan digit, dan penolakan submit berulang saat loading.
- Pemeriksaan kontras memakai token tema dan komposit permukaan: teks utama, pendukung, serta tautan minimal 4,5:1; batas input minimal 3:1 pada pasangan yang diuji. Ini bukan audit aksesibilitas menyeluruh berbasis piksel.
- `flutter test tool/capture_assets_test.dart --dart-define=VISUAL_OUTPUT=build/redesign-review`: 12 capture lulus, memakai widget Flutter, repository demo, aset lokal, dan Google Fonts sebenarnya.
- `flutter build web --release`: berhasil.

Screenshot hasil render tersedia di [screenshots/redesign](screenshots/redesign/). Contoh: [beranda terang](screenshots/redesign/beranda-aset.png), [beranda gelap](screenshots/redesign/beranda-aset-gelap.png), [masuk](screenshots/redesign/login-aset.png), [profil](screenshots/redesign/profil-terang.png), [detail](screenshots/redesign/detail-terang.png), dan [nota](screenshots/redesign/nota-terang.png).

Jalankan ulang capture dengan perintah di atas. Screenshot memakai data fiktif dari fake repository; tidak menghubungi API produksi. Build web bukan bukti pengujian browser interaktif atau perangkat Android. Performa blur/scroll, keyboard native, dan pembaca layar Android masih memerlukan pemeriksaan pada perangkat sebelum rilis.

Seluruh perubahan disiapkan untuk commit lokal. Push dan deploy menunggu instruksi pengguna.
