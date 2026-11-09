# Rencana tahap pertama: fondasi integrasi Sparkleen

Tanggal: 9 November 2026

Status: fondasi API dan integrasi lokal diterapkan; hasil verifikasi di `docs/integration-foundation-results.md`. Versi deployment operasional dan pengujian perangkat fisik masih belum diverifikasi.

## Hasil yang dituju

Sparkleen App dapat memakai backend Laundry melalui API pelanggan yang benar: pelanggan masuk, melihat cucian miliknya, membuka detail dan nota, serta memperbarui profil. Ketika kasir mengubah status, perubahan terlihat di app setelah refresh. Data pelanggan lain tetap terlindungi.

Keberhasilan tahap ini dinilai melalui integrasi dengan backend dan database pengujian, bukan hanya widget dengan fake repository. Desain solid/glass padat dan sembilan aset yang sudah terpasang dipertahankan.

## Dasar rencana dan batas kepastian

| Repo | Snapshot yang diperiksa | Temuan yang memengaruhi urutan kerja |
| --- | --- | --- |
| `sparkleen-app` | `feat/sparkleen-visual-assets`, `dfbc043` | Flutter sudah memanggil `/api/v1`; 78 test sebelumnya memakai pengujian lokal/demo, bukan bukti integrasi ke backend berjalan. |
| `sparkleen-laundry` | `main`, `524f554`; juga `feature/smartpay-integration`, `946dd1e` | Route/controller API pelanggan belum ditemukan pada kedua branch yang diperiksa. Jalur web kasir dan webhook sudah ada. |
| `payment-api` | `main`, `40cf883` | Verifikasi bayar masih simulasi; kegagalan callback dicatat ke log tanpa mekanisme kirim ulang pada fungsi yang diperiksa. |
| `smart-pay` | `main`, `5d4ee1f` | Klien pembayaran simulasi memakai akses merchant; identitas dan saldo per pengguna belum menjadi fondasi yang dapat dianggap siap untuk uang nyata. |

Dokumen Oktober di repo App menyebut branch lokal `feature/mobile-api` dan pekerjaan API yang pernah dilakukan. Itu petunjuk untuk mencari implementasi lama, bukan bukti bahwa API tersebut sudah berada di backend GitHub/deployment saat ini. Angka kegagalan test, kondisi working tree, path Windows, dan klaim implementasi dalam rencana lama tidak dipakai sebagai baseline baru.

## Batas tahap pertama

Dikerjakan: penetapan versi backend, kontrak 11 endpoint yang sudah digunakan app, autentikasi pelanggan, isolasi data, integrasi Flutter, pengujian alur kasir–app, serta panduan menjalankan lingkungan pengujian.

Belum dikerjakan: permintaan jemput, antrean jemput kasir, layar pembayaran pelanggan, deep link Smart Pay, notifikasi push, penukaran poin dari app, dan ledger dompet. App menampilkan poin serta pembayaran yang sudah dicatat backend; tidak menulis nominal/status lunas.

API pelanggan berada di backend Laundry. Payment API tetap menangani tagihan pembayaran; Smart Pay tetap berperan sebagai klien pembayaran simulasi pada tahap ini. Tidak ada kunci merchant/payment yang dimasukkan ke Flutter Sparkleen App.

## Urutan pelaksanaan

### 1. Pastikan sumber backend dan siapkan baseline

- [ ] Identifikasi branch/commit backend yang benar-benar digunakan oleh lingkungan pengujian/deployment, berikut versi migrasinya. Gunakan konfigurasi yang tersedia tanpa menyalin nilai rahasia ke dokumen/log.
- [x] Cari implementasi `feature/mobile-api` yang disebut dokumen lama sebelum menulis ulang. Jika ditemukan, audit dan bawa perubahan relevan secara terpisah; jangan menimpa pekerjaan lokal atau mengganti backend berdasarkan asumsi.
- [x] Jika implementasi lama tidak tersedia, catat gap terhadap kontrak Flutter dan bangun bagian yang hilang pada branch integrasi terpisah dari `main`.
- [x] Jalankan baseline backend dan Flutter, simpan daftar failure aktual serta penyebabnya. Angka historis dalam dokumen lama tidak dianggap hasil terkini.
- [x] Siapkan database pengujian terisolasi dengan pelanggan A/B, kasir, layanan, dan transaksi fiktif. Pastikan test tidak memakai database operasional.

**Catatan pelaksanaan:** implementasi memakai snapshot GitHub yang tersedia, bukan deployment yang belum diketahui. **Syarat selesai:** sumber backend dan daftar gap dapat ditelusuri; koneksi test terverifikasi aman; baseline tercatat. Ketidakjelasan sumber tidak boleh ditutup dengan klaim integrasi sudah bekerja.

### 2. Kunci kontrak yang sudah dibutuhkan Flutter

Base path: `/api/v1`.

| Kelompok | Endpoint | Perilaku yang wajib cocok |
| --- | --- | --- |
| Akun baru/lama | `POST /auth/register`, `/auth/activate`, `/auth/login` | Payload yang dipakai app diterima; respons autentikasi berisi token dan pelanggan. Aktivasi memverifikasi kecocokan nota dengan pemilik nomor. |
| Sesi | `POST /auth/logout` | Mencabut token yang dipakai; app tetap dapat mengakhiri sesi lokal jika jaringan terputus. |
| Profil | `GET /me`, `PATCH /me` | Nama, nomor, alamat, poin, total transaksi cocok dengan model Flutter. PATCH hanya menerima perubahan profil yang diizinkan. |
| Katalog/outlet | `GET /layanan`, `GET /outlet` | Data dari backend; key gambar opsional tetap kompatibel dengan fallback nama/ikon. |
| Pesanan | `GET /transaksi`, `GET /transaksi/{id}` | Filter, pagination, status, tanggal, detail layanan, pembayaran, dan kepemilikan cocok. |
| Nota | `GET /transaksi/{id}/nota` | Nominal dan rincian sesuai transaksi; PIN pengambilan tidak masuk response nota. |

- [x] Cocokkan kontrak dengan `AuthRepository`, `HomeRepository`, `TransaksiRepository`, dan model Flutter, bukan hanya contoh respons di README.
- [x] Tetapkan response sukses `{data, meta?}` dan error `{error: {code, message, fields?}}`. API tidak membalas halaman login HTML atau redirect sesi web.
- [x] Tetapkan uang sebagai integer rupiah; tanggal ISO-8601 dengan zona; ID transaksi numerik pada path. Format nomor nota yang mengandung `/` tetap menjadi field data.
- [x] Kunci arti filter `aktif/selesai/semua` dan pemetaan status master agar hasil web dan app konsisten, termasuk transaksi lama.
- [x] Tandai endpoint jemput/pembayaran dalam dokumentasi sebagai cakupan berikutnya sampai implementasinya terbukti tersedia. Perbarui koleksi pengujian agar rute rencana tidak disalahartikan sebagai rute aktif.

**Syarat selesai:** matriks request/response dan status implementasi untuk seluruh 11 endpoint tersedia, dengan contoh sukses, kosong, validasi gagal, dan akses ditolak.

### 3. Implementasikan autentikasi dan isolasi data

- [x] Pisahkan autentikasi API Bearer dari sesi web kasir. Pengecualian filter web/CSRF hanya untuk rute API yang memerlukannya; setiap rute API privat tetap dilindungi filter token. Perlindungan form web tidak dilonggarkan.
- [x] Tambahkan skema autentikasi secara additive bila belum ada: hash PIN pelanggan serta tabel token. Tidak mengubah struktur `tb_transaksi` atau menghapus data pelanggan lama.
- [x] PIN disimpan melalui hashing password; token acak hanya dikirim saat diterbitkan, sedangkan DB menyimpan hash token. Rahasia tidak ditulis ke log.
- [x] Terapkan normalisasi `08…` dan `62…` dengan pemeriksaan duplikat nomor lama sebelum perubahan data. Tidak melakukan backfill massal otomatis.
- [x] Terapkan validasi, pembatasan percobaan login/aktivasi, masa berlaku token sesuai kontrak yang disepakati, revocation saat logout, serta penolakan akun nonaktif.
- [x] Setiap query transaksi/detail/nota dibatasi oleh pelanggan dari token. ID milik pelanggan lain menghasilkan 404 tanpa membocorkan detail.
- [x] PATCH profil memakai allowlist nama/alamat; pelanggan tidak dapat mengubah poin, total transaksi, atau status pembayaran melalui body tambahan.
- [ ] Migrasi diuji naik/turun pada DB test beserta skenario pelanggan lama; langkah backup dan pemulihan disiapkan sebelum penerapan ke lingkungan operasional.

**Syarat selesai:** A tidak dapat membaca/mengubah data B; token invalid/kedaluwarsa/dicabut menghasilkan 401 JSON; registrasi/aktivasi tidak membuat pelanggan lama menjadi duplikat.

### 4. Sambungkan data aktual ke UI yang sudah ada

- [x] Implementasikan query/proyeksi profil, layanan, outlet, daftar transaksi, detail, dan nota dari tabel existing. Hindari menyalin ulang perhitungan harga/poin ke Flutter.
- [x] Hubungkan Flutter ke backend pengujian melalui `API_BASE_URL`, tanpa hardcode alamat produksi atau kredensial.
- [x] Perbaiki ketidakcocokan parsing, field null, pagination, atau error hanya jika terbukti dari pengujian kontrak. Status yang tidak dikenal tidak boleh ditampilkan sebagai tahap yang sudah selesai.
- [x] Pastikan logout/401, retry, pull-to-refresh, dan edit profil bekerja terhadap API. Ganti akun tidak boleh menyisakan tampilan data akun sebelumnya.
- [x] Buktikan semua aset tetap tampil sesuai data nyata: layanan dikenal, layanan tanpa gambar, pesanan kosong, serta error jaringan. Tidak membutuhkan gambar baru.
- [x] CORS dibatasi ke origin pengujian/web yang diperlukan bila target web digunakan; respons API dan preflight diuji. Konfigurasi release memakai HTTPS.

**Syarat selesai:** alur inti berjalan memakai backend + DB test; widget demo bukan satu-satunya bukti.

### 5. Uji alur penuh, dokumentasikan, lalu siapkan commit

| Skenario | Hasil yang diharapkan |
| --- | --- |
| Pelanggan baru daftar lalu login | Satu akun tercipta; profil benar; token bekerja. |
| Pelanggan lama aktivasi | Nota harus milik nomor tersebut; riwayat lama tetap terhubung. |
| Pelanggan A meminta detail/nota B | 404; tidak ada kebocoran data ataupun PIN. |
| Kasir membuat/mengubah status transaksi A | Refresh app A menampilkan data yang sama dengan web; B tidak ikut melihatnya. |
| Kasir mencatat pembayaran tunai pada transaksi demo | Ringkasan pembayaran dan nota app mengikuti backend, tanpa app mengirim nominal pelunasan. |
| Edit profil lalu buka ulang app | Perubahan tersimpan; poin dan nomor tidak berubah melalui field yang tidak diizinkan. |
| Token kedaluwarsa/logout/ganti akun | Akses token lama ditolak; sesi dan data tampilan sesuai akun aktif. |
| API mati, respons invalid, pagination, atau data kosong | Ada pesan/retry yang sesuai; tidak menampilkan keberhasilan palsu atau data akun sebelumnya. |

- [x] Test backend memeriksa kontrak, pembatasan akses, validasi, dan regresi kasir. Failure lama dibandingkan satu per satu; tidak cukup hanya membandingkan jumlah failure.
- [x] `flutter analyze`, suite Flutter yang ada, dan build web release lulus. Tambahkan test integrasi/kontrak yang menguji server pengujian, bukan menggandakan test struktur widget.
- [ ] Uji pada target Android yang tersedia: login, secure storage, jaringan, kembali dari background, dan logout. Jika perangkat tidak tersedia, catat sebagai pemeriksaan yang belum dilakukan; jangan mengklaim lulus.
- [x] Simpan hasil pemeriksaan request/response dalam test, snapshot dasar kedua repo, daftar keterbatasan, serta instruksi menjalankan ulang.
- [ ] Simpan screenshot alur data demo pada perangkat target saat pengujian Android dilakukan.
- [x] Siapkan commit terpisah untuk backend dan penyesuaian app agar rollback dapat ditelusuri. Jangan push/deploy otomatis dari rencana ini.

**Syarat selesai:** demo kasir–API–app dapat diulang dengan pelanggan A/B, perlindungan akses lulus, regresi kasir tidak bertambah, dan batas pengujian jelas.

## Penghalang sebelum pembayaran pelanggan ditambahkan

Temuan pembayaran tidak dianggap selesai oleh pekerjaan API pelanggan di atas.

1. Backend Laundry tidak boleh otomatis mencatat pembayaran online melalui jalur lokal ketika Payment API gagal. Pertahankan status belum terkonfirmasi dan berikan pesan kegagalan; pembayaran tunai tetap tindakan kasir yang eksplisit.
2. Webhook perlu memvalidasi pembayaran terhadap intent dan nominal yang benar, memproses pembaruan secara atomik, serta mencegah pencatatan ganda.
3. Payment API perlu rekaman pengiriman callback dan retry yang bisa ditelusuri, serta sinkronisasi ketika provider sudah SUCCESS tetapi Laundry belum menerima konfirmasi.
4. Pemisahan akses merchant/pengguna dan penanda simulasi Smart Pay harus diputuskan sebelum membuka pembayaran pelanggan. Keberhasilan simulator tidak membuktikan perpindahan uang nyata.

Jika alur pembayaran existing sedang dipakai untuk transaksi operasional, poin 1 menjadi pekerjaan paling awal sebelum uji pembayaran lain. Untuk pengujian fondasi API, gunakan data demo dan pembayaran tunai eksplisit; jangan menghubungi provider operasional. Fitur bayar di app tidak dibuka sampai penghalang ini ditangani dan diuji.

## Keluaran tahap pertama

- Matriks kontrak dan status 11 endpoint.
- Implementasi atau pemulihan API pelanggan pada backend yang sumbernya sudah jelas.
- Migrasi additive dan langkah pemulihan yang diuji.
- App yang terhubung ke backend test dengan desain/aset tetap konsisten.
- Bukti test kontrak, isolasi A/B, dan alur kasir–app.
- Dokumentasi konfigurasi tanpa rahasia, versi yang kompatibel, serta commit per repo.

Tahap implementasi lokal sudah dikerjakan. Penerapan operasional menunggu verifikasi versi deployment, backup, dan perangkat. Catatan estimasi awal: besarnya pekerjaan bergantung pada ditemukan atau tidaknya implementasi backend mobile yang disebut dokumen lama. Setelah langkah 1 selesai, estimasi dibuat dari gap aktual.

## Setelah tahap pertama lulus

Urutan berikutnya: konsistensi/otorisasi pembayaran → permintaan jemput beserta antrean kasir → pembayaran pelanggan → notifikasi dan loyalitas. Masing-masing direncanakan terpisah setelah fondasi terverifikasi.

## Sumber yang dipakai

- Flutter: `lib/core/api/`, `lib/features/auth/data/`, `lib/features/home/data/`, `lib/features/pesanan/data/`, `lib/features/nota/data/`.
- Kontrak existing: `docs/api/sparkleen-mobile-v1.md` dan koleksi Postman; endpoint rencana perlu diberi status implementasi.
- Backend Laundry: `app/Config/Routes.php`, `Filters.php`, `Database.php`, `app/Models/MPelanggan.php`, `app/Services/TransaksiService.php`, `app/Controllers/Webhook.php`.
- Payment API: `src/routes/transactions.js`, `src/services/paymentService.js`, `src/middleware/auth.js`.
- Smart Pay: `lib/services/payment_service.dart`, `lib/screens/home_screen.dart`, `lib/screens/pin_screen.dart`.
- Rencana Oktober digunakan untuk menelusuri keputusan lama, dengan verifikasi ulang terhadap snapshot repo yang dicantumkan di atas.

## Pembaruan 10 November: tahap 6–8

Suite backend penuh: 106 test, 404 assertions lulus sesudah perbaikan kesiapan rilis.
Rehearsal backup/restore lokal dan 3 skenario startup lulus. Tahap Android fisik,
signing rilis, koneksi GitHub dan identitas/akses hosting masih diperlukan; tidak
ada push atau deployment operasional. Lihat `docs/release/android-verification.md`
dan laporan kesiapan rilis pada repo Laundry.
