# Sparkleen 0.0.4 — penyelarasan UI dengan preview

12 November 2026 (WIB). Versi `0.0.4+4`, tetap pada branch `feat/glass-redesign-v0.0.2`. Perubahan hanya Sparkleen App. Catatan ini menggantikan klaim kesesuaian visual pada versi sebelumnya: tes fungsi dan tidak adanya overflow belum cukup membuktikan kesesuaian dengan preview.

## Dasar desain

- Preview gambar AI yang disetujui dipakai untuk struktur, urutan, proporsi, hierarki dan jenis ilustrasi. Preview tersebut tidak menyertakan metadata font; Inter dipilih sebagai padanan visual. Font tidak diklaim sebagai nama font yang pasti dipakai oleh generator gambar.
- Inter 400/500/600/700 dibundel lokal bersama lisensinya. Semua judul, isi, label, tombol dan kontrol memakai keluarga yang sama. Judul/section dibuat lebih tegas; isi memakai bobot normal. Aplikasi tidak mengunduh font saat dibuka.
- Seluruh panel `AppCard`, panel biru, input dan navigasi memakai opacity **75%**. Teks tetap opak agar terbaca. Border highlight, blur dan shadow dipertahankan; background solid dan aksen biru tidak menggunakan gradasi.
- Screenshot di folder versi ini adalah render widget dari kode Flutter dengan font dan image provider yang benar-benar dimuat. Bukan hasil imagegen. Data demonstrasi berbeda dari akun/nota produksi dan dari data fiktif pada preview awal.

## Perbandingan dan perbaikan

| Halaman | Perbedaan pada build sebelumnya | Implementasi 0.0.4 |
| --- | --- | --- |
| Beranda | Poin berupa teks; hero mesin cuci; jarak dan kartu terlalu besar | Header poin dalam chip glass, keranjang/tas sesuai referensi, hero dan kartu aktif lebih padat, ilustrasi layanan lebih jelas |
| Profil | Avatar bulat, jarak besar dan statistik tidak seimbang | Avatar persegi membulat, identitas ringkas, statistik dua kolom dengan pemisah, daftar menu padat dan gear tanpa kotak |
| Pesanan | Header brand hilang; kartu berbeda susunannya | Header brand/poin/notifikasi, jumlah pesanan terbaru, status/nota di atas, thumbnail dan estimasi di tengah, aksi detail di kanan |
| Detail | Timeline/rincian dibungkus kartu besar bertumpuk | Timeline terbuka, header dan ringkasan tagihan ringkas, rincian layanan dalam kartu, aksi poin/nota dan pembayaran diurutkan seperti referensi |
| Nota | Logo besar di tengah dan blok struk generik | Header brand horizontal, bentuk tiket dengan takikan, status lunas dekat nomor nota, rincian/total/metode dan konfirmasi pembayaran |
| Penjemputan | Aktif/riwayat tercampur dan kartu riwayat besar | Hero keranjang/tas, info jumlah aktif, bagian aktif terpisah, kalender/alamat/berat berikon, pembatalan kanan, riwayat ringkas dengan rincian yang dapat dibuka |
| Formulir jemput | Form panjang dengan kontrol tidak seragam | Layanan/berat dan ilustrasi satu kartu; lokasi/jadwal terpisah; tanggal dan slot sejajar saat ruang cukup; catatan dan estimasi ringkas |
| Pembayaran | Petunjuk panjang, QR dan aksi bercampur | Nominal/status ringkas, kartu QR terpusat, tombol status dan batal di luar kartu, pengaturan biometrik di bawah |
| Poin | Kartu riwayat besar dengan penjelasan dominan | Hero saldo/coin/pemisah, baris ledger padat dengan ikon, pagination manual dan catatan di bawah |
| Tukar poin | Dua kartu generik besar | Ringkasan saldo/tagihan dua baris, input poin terpisah, rincian potongan/sisa/saldo, penyesuaian poin dan konfirmasi tetap terlihat |
| Koneksi gagal | Mesin cuci kecil dan konten di tengah dengan ruang kosong | Ilustrasi router, judul/keterangan rata kiri, kartu server lokal/online, retry/server/fallback PIN berurutan |
| Notifikasi | Kontrol belum benar-benar berada di tepi kanan | Hari ini di kiri dan baca semua di tepi kanan; teks besar memakai susunan adaptif dengan aksi tetap rata kanan |

Nama layanan pada endpoint daftar pesanan belum tersedia. Kartu daftar memakai label umum “Pesanan laundry” dan ilustrasi laundry; tidak menebak layanan dari ID. Detail dan nota menggunakan nama layanan asli API. Nomor nota, nominal, status, QR dan data pengguna tetap berasal dari server; data contoh dalam gambar preview tidak ditanam sebagai data aplikasi.

PIN pengambilan berada dalam panel yang dapat dibuka di detail, dengan fungsi salin tetap tersedia. Status akhir pengambilan ditambahkan ke timeline ketika tahap tersebut mulai/selesai, sehingga tahapan yang masih jauh tidak memenuhi layar awal. Rincian riwayat penjemputan (alamat/catatan/alasan ditolak) dapat dibuka dari kartu; akses pesanan akhirnya tetap tersedia langsung.

## Splash dan performa

Splash tampil minimal **2 detik sekali saat cold start**. Pengecekan sesi berjalan bersamaan; navigasi normal dan kembali dari background tidak menambah delay splash baru. Animasi selesai dalam 1,8 detik. Preferensi reduced motion tetap dihormati. Timer dibatalkan ketika scope aplikasi dibuang.

Daftar pesanan, penjemputan, notifikasi dan poin meminta maksimal 20 entri per halaman, dengan aksi Lihat semua/Muat 20 berikutnya. Riwayat memakai pemuatan manual; poin, notifikasi dan penjemputan dirender bertahap. Formulir pendek sengaja mempertahankan seluruh field agar validator tetap aktif setelah scroll ke tombol kirim.

## Verifikasi

- Analyzer bersih.
- Tes unit/widget mencakup autentikasi/sesi/biometrik, navigasi Poin → Pesanan, pembayaran dan pagination yang sudah ada.
- Regresi tambahan: splash masih terlihat pada 1.999 ms meski inisialisasi login sudah selesai, lalu berpindah sesudah dua detik; panel biasa dan berwarna sama-sama 75%; tombol baca semua berada pada tepi kanan; field jemput wajib tetap divalidasi saat tombol kirim berada jauh di bawah.
- Matriks layout 320/360/390/412 dengan skala teks 1/1,5/2 dan kedua tema. Halaman penjemputan/notifikasi juga diuji pada lebar 320 dan skala 1,8.
- 24 skenario halaman × 2 tema dirender dengan font dan gambar; scroll diperiksa. Contoh 390 × 868 menyertakan inset atas/bawah. Pembayaran memakai QR QA yang tidak dapat digunakan bertransaksi.

**Hasil akhir:** 161 tes unit/widget lulus dan dua tes capture menyelesaikan 48 skenario. Build preview ARM64 berhasil. APK 20,531,250 byte (sekitar 20.53 MB), package `com.sparkleen.sparkleen_mobile.preview`, version name `0.0.4`, versionCode `2004`, minimum SDK 24 dan target SDK 36. Signature v2, ZIP, alignment APK/ELF 16 KB, keempat bobot Inter (byte sama dengan source), seluruh WebP serta channel keamanan/native storage terverifikasi.

Sertifikat APK sama dengan versi 0.0.3 yang dibagikan sebelumnya, sehingga dapat memperbarui APK tersebut tanpa menghapus data lokal. Ini tetap APK preview internal dengan debug signing; bukan build Play Store.

SHA-256 APK: `056db38e2f172843aac5ecac402eaa924ba3549c131463d88d81c18f7ca8c0f4`.

## Menjalankan kembali

```bash
flutter pub get
flutter analyze
flutter test --dart-define=APP_PREVIEW=true
flutter test tool/capture_redesign_audit_test.dart --dart-define=APP_PREVIEW=true
flutter build apk --release --flavor preview --dart-define=APP_PREVIEW=true --target-platform=android-arm64 --split-per-abi --split-debug-info=build/symbols/0.0.4
```

Lihat [screenshot terang/gelap](screenshots/v0.0.4/) untuk hasil kode. Capture memakai data demo, bukan akses produksi. APK preview mendukung konfigurasi server lokal dan internet yang sama dengan versi sebelumnya. Sensor fingerprint, lifecycle OEM, keyboard dan performa native tetap perlu pengujian di HP fisik; hasil tes otomatis tidak membuktikan semua perangkat bebas bug.
