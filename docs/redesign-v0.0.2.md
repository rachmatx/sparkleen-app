# Sparkleen 0.0.2 — glass UI refresh

Implementasi pada branch `feat/glass-redesign-v0.0.2`, berbasis `fa24dc6` (0.0.1).
Fokus perubahan hanya repositori Sparkleen App. Kontrak API dan backend pembayaran tidak diubah.

## Tampilan dan navigasi

- Latar solid terang `#EDF3FA` / gelap `#0B1220`, aksen biru. Panel kaca opacity 87%, navigasi bawah 88%; blur memakai grup backdrop agar panel tidak membuat lapisan filter terpisah tanpa perlu.
- Pilihan Terang, Gelap, dan Ikuti sistem melalui Profil → gear tanpa kotak → Pengaturan → Tampilan. Pilihan disimpan lokal dan dimuat sebelum aplikasi dibuka.
- Login dan register memakai form tanpa kartu pembungkus besar. Register tanpa tombol back dan tanpa ilustrasi pita. Gear koneksi sebelum login tersedia di build preview.
- Layar sesi memakai tombol fingerprint kecil di area bawah, fallback PIN dan akses server tetap tersedia. Ikon aplikasi bukan penanda lokasi sensor Android.
- Beranda mengelompokkan poin/notifikasi di kanan, memakai ilustrasi dan kartu jemput. Header menyesuaikan ketika ukuran teks diperbesar.
- Profil memisahkan identitas, saldo poin, informasi akun dan aktivitas. Keamanan, server, tema, informasi aplikasi dan logout tersedia di Pengaturan.
- `total_transaksi` adalah akumulasi nilai belanja pada backend, sehingga ditampilkan sebagai Total belanja dalam rupiah.
- Daftar/detail pesanan menggunakan thumbnail. Endpoint daftar tidak menyediakan nama layanan, sehingga kartu daftar memakai ilustrasi laundry umum; detail memakai nama layanan yang benar dari API.
- Batalkan permintaan jemput rata kanan. Tandai semua dibaca rata kiri pada baris Hari ini; tanggal notifikasi dikelompokkan memakai kalender WIB.
- Status pembayaran berhasil menampilkan nominal transaksi, akses nota dan kembali ke pesanan. Konfirmasi biometrik tetap hanya melindungi pembuatan tagihan; status lunas berasal dari server.

## Aset dan performa

- Aset ilustrasi runtime memakai WebP dengan alpha. Aset PNG lama sekitar 8,3 MB dikonversi menjadi sekitar 292 KB; ilustrasi splash baru sekitar 40 KB. Master ikon launcher PNG berada di `tool/branding/`, bukan bundle aset runtime.
- Pemetaan layanan mengenali Cuci + Setrika, Cuci Kilat, Cuci Reguler, serta alias terdahulu. `asset_key` eksplisit dari API tetap diutamakan.
- Splash memakai ilustrasi, animasi masuk dan satu gerakan naik-turun kecil, lalu indikator pemuatan. Tidak menahan redirect setelah autentikasi siap. Reduced motion menghilangkan gerakan.
- API riwayat pesanan, jemput, notifikasi dan poin sudah meminta `per_page=20`. Halaman Pesanan membatasi tampilan awal 20 entri, tanpa pemuatan otomatis saat scroll. Lihat semua pesanan membuka riwayat, kemudian Muat 20 berikutnya meminta halaman berikutnya. Data yang sudah dimuat dideduplikasi oleh controller.
- Notifikasi, jemput dan poin memuat halaman lanjutan hanya melalui tombol pengguna. Mereka tidak mengunduh semua riwayat saat halaman dibuka.

## Verifikasi

- Analyzer bersih.
- 153 tes Flutter lulus, termasuk matriks layar 320/360/390/412 dan skala teks 1/1,5/2 untuk kedua tema.
- Regresi Poin → Pilih pesanan diuji sebelum tab Pesanan pernah dibuka dan setelah tab sudah aktif. Kode navigasi lama menyebabkan tes ini gagal; perbaikan memakai perpindahan cabang `go`.
- Tes riwayat memastikan scroll tidak memuat halaman kedua, ukuran permintaan 20, dan halaman berikutnya hanya diminta setelah aksi pengguna.
- Tes penyimpanan tema termasuk kegagalan storage; tes keamanan/pembayaran/sesi yang sudah ada tetap dijalankan.
- Screenshot QA diambil dari widget Flutter dengan font dan gambar yang sudah dimuat, untuk beranda terang/gelap, profil dan pengaturan.
- Build APK 0.0.2 belum diverifikasi. Toolchain Android proyek membutuhkan Gradle 9.3.1 dan AGP 9.1.0 yang belum ada pada cache lingkungan; pemeriksaan unduhan mengalami timeout. Tidak menurunkan versi toolchain proyek untuk melewati kendala tersebut.

## Uji Android berikutnya

1. Ganti tema dan tutup/buka aplikasi; cek preferensi tersimpan.
2. Dari Poin pilih pesanan beberapa kali, termasuk setelah membuka detail atau mengganti tab.
3. Gunakan akun dengan >20 pesanan; cek Lihat semua dan Muat 20 berikutnya.
4. Periksa semua gambar, teks besar, keyboard, notch dan navigasi sistem Android.
5. Uji fingerprint sukses/batal, fallback PIN, lock saat background, serta ganti server.
6. Jalankan alur jemput → transaksi kasir → tukar poin → pembayaran simulasi → nota pada server pengujian.

Sensor fisik dan alur lintas aplikasi tetap membutuhkan pengujian di perangkat pemilik. Tes otomatis tidak membuktikan bebas bug pada semua perangkat.
