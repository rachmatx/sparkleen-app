# Rencana peningkatan UI/UX Sparkleen

Tanggal: 9 November 2026  
Baseline: `140786c` pada branch lokal `feat/sparkleen-visual-assets`  
Status: rencana dan konsep interaksi; implementasi redesign belum dimulai.

## 1. Tujuan produk

Sparkleen membantu pelanggan menjawab empat pertanyaan: cucian sedang berada di tahap apa, kapan diperkirakan selesai, berapa biayanya, dan bagaimana menghubungi outlet. Prioritas visual mengikuti urutan tersebut.

Permintaan “100 kali lebih bagus” diterjemahkan menjadi perubahan yang dapat diperiksa: informasi utama ditemukan lebih cepat, tindakan tidak berulang, tampilan kaca memiliki kedalaman, formulir mudah dipakai, serta seluruh layar konsisten. Tidak ada klaim peningkatan numerik sebelum pengujian pengguna.

## 2. Temuan audit

| Temuan | Bukti baseline | Implikasi desain |
| --- | --- | --- |
| Kartu berukuran besar dan memiliki bobot visual yang hampir sama. | Beranda: sapaan, pesanan aktif, tombol penuh, katalog; kartu lain pada detail/profil. | Bedakan elemen utama, sekunder, dan baris informasi. Kurangi wadah yang tidak perlu. |
| Efek kaca kurang terbaca. | `AppCard` memakai blur 14 dan fill 0,72; beberapa area memakai bidang opaque. Background dominan tekstur tenun berulang. | Bentuk lapisan kaca di atas bidang warna yang memiliki kedalaman; atur tint, tepi, dan blur per tingkat. |
| Tipografi terlalu sering memakai bobot 700–800. | `app_theme.dart`: hampir seluruh judul dan label berinteraksi. | Gunakan 400/500 untuk isi, 600 untuk judul bagian, 700 untuk informasi utama. Batasi judul besar. |
| Aksi ke daftar/detail pesanan berulang. | Kartu aktif, “Lihat perjalanan cucian”, “Lihat semua pesanan”, dan tab Pesanan. | Kartu aktif menuju detail; tautan bagian “Semua” menuju daftar. Hindari tombol penuh yang mengulang tujuan yang sama. |
| Data outlet belum dimanfaatkan. | Model memuat nama, alamat, nomor WA, jam buka/tutup; beranda hanya menyalin nomor WA. | Tampilkan identitas outlet, alamat, jam operasional yang tersedia, dan aksi kontak yang jelas. |
| Ilustrasi menjadi panel tersendiri yang menambah tinggi halaman. | Hero dan login pada commit aset awal. | Gunakan ilustrasi sebagai aksen pada header atau kondisi kosong; sisakan ruang untuk tugas utama. |
| PIN selalu tertutup tanpa kontrol visibilitas. | Login, daftar, aktivasi. | Tambahkan tampilkan/sembunyikan PIN dengan label aksesibel dan area sentuh yang cukup. |
| Hierarki antarlayar belum menyatu. | Header “Ruang pribadimu.”, “LAUNDRY KAMU”, bentuk kartu serupa pada hampir semua data. | Gunakan judul yang langsung: Beranda, Pesanan, Detail pesanan, Nota digital, Profil. |

Temuan berasal dari kode dan screenshot demo yang sudah dirender. Belum ada wawancara pengguna, rekaman sesi, atau pengukuran keberhasilan tugas pada pengguna nyata.

## 3. Arah visual: glassmorphism yang tenang

### Material dan warna

- Pertahankan royal blue Sparkleen `#0D63D8` sebagai warna tindakan dan identitas.
- Dasar terang: putih kebiruan; dasar gelap: navy. Teks utama tetap memiliki kontras yang jelas.
- Bentuk latar berupa bidang biru luas dengan perubahan cahaya halus. Kurangi tekstur berulang yang mengganggu isi.
- Gunakan tepi kaca tipis, sorotan bagian atas, tint yang lembut, dan bayangan pendek. Hindari glow neon dan dekorasi warna yang tidak berkaitan dengan merek.
- Kaca memiliki tiga tingkat: permukaan isi, kartu informasi utama, dan dock navigasi. Besar blur dan opacity bukan satu nilai untuk semua komponen.
- Blur diklip sesuai batas elemen. Kartu di dalam kartu tidak otomatis mendapatkan blur lagi. Dock yang bertumpuk di atas isi tidak berbagi kelompok blur dengan isi yang tertutup.
- Rentang eksplorasi awal blur 16–24 untuk permukaan utama. Nilai akhir ditentukan melalui render dan pengukuran di perangkat, bukan dianggap sudah optimal.

### Tipografi dan geometri

- Pertahankan Plus Jakarta Sans untuk judul dan Manrope untuk isi.
- Skala awal: judul halaman 26–28, judul bagian 17–18, isi 14–15, keterangan 12–13 logical pixel. Ukuran mengikuti pembesaran teks sistem.
- Bobot 700 hanya untuk titik fokus seperti estimasi, nama, atau total. Label kecil tidak semuanya menjadi uppercase dengan jarak huruf lebar.
- Grid jarak 4/8; margin layar sekitar 20; radius utama 24–28, elemen kecil 12–16.
- Nominal dan tanggal memakai perataan yang konsisten; angka uang dapat menggunakan tabular figures.
- Target sentuh minimal 48 × 48 logical pixel. Jangan mengecilkan area interaksi agar tampak minimalis.

### Pemakaian aset

- Sembilan aset yang sudah dibuat tetap menjadi sumber visual; tidak menambah stok gambar acak.
- Logo digunakan konsisten. Gambar layanan menjadi pembeda layanan; ilustrasi beranda/login menjadi aksen dengan ukuran terbatas.
- Bidang pale blue tetap dapat digunakan sebagai alas gambar untuk mengatasi tepi putih master, tetapi tidak harus menjadi kartu besar tersendiri.
- Ikon navigasi/kontrol memakai satu keluarga Material Icons pada aplikasi Flutter.
- Tidak menambahkan banner promo, status keanggotaan, testimoni, statistik, atau hadiah yang belum tersedia.

## 4. Susunan tiap layar

| Layar | Urutan dan hierarki baru | Interaksi yang ditingkatkan |
| --- | --- | --- |
| Beranda | Header merek/poin ringkas → sapaan singkat → pesanan aktif dengan status dan estimasi → layanan/harga → outlet. | Kartu aktif membuka detail. “Semua” membuka daftar. Poin menuju profil. Layanan dapat membuka ringkasan informasi. |
| Masuk | Header merek → intro ringkas dengan aksen ilustrasi → satu panel formulir → daftar/aktivasi. | Nomor telepon dan PIN mudah dijangkau; visibilitas PIN, autofill yang sesuai, keyboard next/done, submit saat loading dicegah. |
| Daftar/aktivasi | Header kembali dan judul langsung → penjelasan singkat → formulir berkelompok. | Visibilitas PIN, validasi dekat field, fokus ke field bermasalah, posisi scroll aman ketika keyboard terbuka. |
| Pesanan | Judul dan deskripsi ringkas → filter Aktif/Selesai/Semua → daftar transaksi. | Filter mempertahankan konteks dan state yang jelas, kartu seluruhnya dapat ditekan, pagination dan retry dipertahankan. |
| Detail pesanan | Status/estimasi sebagai fokus → timeline → rincian layanan → pembayaran → PIN pengambilan jika ada. | Nota digital mudah ditemukan. Status tidak hanya dibedakan oleh warna. Nomor nota dan rincian tetap tersedia tanpa mendominasi. |
| Nota digital | Identitas outlet → nomor/tanggal → rincian → total paling menonjol → status pembayaran. | Teks terbaca dan nominal konsisten; PIN pengambilan tetap tidak masuk nota. |
| Profil/edit | Identitas pengguna → poin/transaksi yang memang tersedia → data kontak/alamat → edit → logout. | Label langsung, penyuntingan memberi umpan balik, konfirmasi logout dipertahankan. |

### Beranda: keputusan penting

1. Status dan estimasi menjadi fokus kartu aktif; nomor nota menjadi informasi sekunder.
2. Penanda tahap menunjukkan tahap proses aktual dari API. Jangan menampilkan persentase pengerjaan yang tidak disediakan backend.
3. Hapus duplikasi tombol besar ke daftar pesanan. Tab Pesanan tetap tersedia.
4. Untuk katalog kecil, uji dua kartu layanan berdampingan. Pada layar sempit atau ukuran teks besar, ubah menjadi satu kolom.
5. Ringkasan layanan hanya menampilkan nama, harga, satuan, dan estimasi dari API. Tidak menyiratkan proses checkout yang belum tersedia.
6. Tampilkan alamat dan jam buka jika tersedia. Jangan menyatakan outlet “sedang buka” tanpa aturan zona waktu dan penanganan jam lintas tengah malam.
7. Kontak WhatsApp dapat ditingkatkan melalui launcher URL yang tervalidasi. Jika aplikasi tujuan tidak tersedia, berikan fallback penyalinan nomor yang eksplisit. Membuka aplikasi kontak tidak mengirim pesan otomatis.

## 5. Komponen yang dibangun ulang

| Komponen | Tanggung jawab |
| --- | --- |
| Token tema | Warna, opacity, border, bayangan, radius, jarak, dan tipografi terang/gelap. |
| `AppCard` / material kaca | Kaca yang konsisten dengan tingkat penekanan berbeda dan blur yang dibatasi. |
| `AppBackdrop` | Dasar opaque dan bidang cahaya biru statis di belakang kaca. |
| Header halaman | Judul, penjelasan singkat, dan aksi yang benar-benar tersedia. |
| Kartu pesanan | Versi utama pada beranda dan versi ringkas pada daftar, berbagi bahasa visual. |
| Penanda tahap | Label proses aktual dan keadaan selesai/aktif/menunggu. |
| Field PIN | Visibilitas, pembatasan enam angka, fokus, dan label aksesibel. |
| Kondisi loading/error/kosong | Ukuran ilustrasi, teks, dan tindakan yang sesuai konteks. |
| Dock navigasi | Tiga tab yang sama; kaca lebih jelas, label terbaca, target sentuh memadai. |

Tetap gunakan widget native Flutter untuk interaksi dasar, semantik, fokus, dan keyboard. Hindari komponen visual buatan yang kehilangan perilaku aksesibilitas.

## 6. State dan perilaku

- Loading mempertahankan bentuk konten yang akan muncul. Animasi tenang; hormati pengaturan pengurangan animasi.
- Error jaringan menampilkan ilustrasi koneksi; error server/validasi mempertahankan konteks dan pesan aslinya.
- Pesanan aktif kosong dan riwayat kosong memiliki pesan yang berbeda, dengan tindakan yang memang tersedia.
- Semua tombol aktif mempunyai hasil yang nyata. Tidak ada ikon notifikasi, pencarian, atau reward dengan callback kosong.
- Gerak singkat 160–220 ms untuk perubahan state lokal. Tidak ada animasi dekoratif yang terus berulang.
- Pertahankan refresh, pagination, session handling, copy PIN, validasi, dan isolasi data pelanggan.

## 7. Urutan eksekusi dan titik evaluasi

| Tahap | Keluaran konkret | Syarat lanjut |
| --- | --- | --- |
| A. Perencanaan | Dokumen ini dan konsep interaksi untuk memeriksa hierarki/arah kaca. | Informasi utama jelas, cakupan sesuai fitur aktual. |
| B. Sistem visual | Token dan komponen kaca pada Flutter. | Kontras, clipping blur, dan tema gelap terverifikasi. |
| C. Layar utama | Beranda dan masuk, dirender dari widget Flutter dengan data demo. | Status/estimasi serta formulir terlihat pada viewport sasaran; gambar tidak mendominasi. |
| D. Konsistensi alur | Pesanan, detail, nota, profil, edit, daftar, aktivasi, empty/error/loading. | Setiap aksi dan state bekerja; data dan route tetap benar. |
| E. Verifikasi | Analisis statis, test, build web, screenshot, pemeriksaan sentuh dan keyboard. | Tidak ada regresi, overflow, atau kontrol palsu. |
| F. Penyerahan | Commit lokal terpisah dari commit aset awal, ringkasan perubahan, dan bukti render. | Working tree bersih; push tetap menunggu instruksi pengguna. |

Perencanaan memakai audit source dan konsep interaksi. Eksekusi memakai implementasi dan render Flutter aktual; gambar generatif hanya diperlukan bila ada kebutuhan aset raster baru yang jelas. Konsep interaksi bukan bukti bahwa UI Flutter sudah diimplementasikan.

## 8. Kriteria penerimaan

### Visual dan kegunaan

- Pada viewport 390 × 844 dengan ukuran teks normal, kartu aktif memperlihatkan status dan estimasi pada tampilan awal; pengguna tidak perlu melewati ilustrasi besar.
- Pada layar masuk dengan viewport yang sama dan keyboard tertutup, kedua field dan tombol masuk dapat ditemukan tanpa gulir panjang.
- Layout diperiksa pada lebar 320, 360, 390, dan 412 logical pixel serta layar lebih lebar yang dibatasi aplikasi.
- Pembesaran teks 1,0 / 1,5 / 2,0 tidak menyebabkan overflow; konten dapat mengalir dan digulir.
- Kontras teks utama/pendukung ditargetkan sekurang-kurangnya 4,5:1 terhadap latar efektif, termasuk pada area kaca yang bertumpuk.
- Tindakan penting dapat digunakan dengan pembaca layar dan memiliki nama yang jelas. Status memakai label, bukan warna saja.
- Target sentuh minimal 48 × 48; tombol aktif tidak mempunyai callback kosong.
- Tidak ada ilustrasi, label, nomor nota, harga, atau indikator yang terpotong dock navigasi.

### Teknis

- `flutter analyze` tanpa masalah.
- Seluruh 50 test baseline tetap lulus; test yang bertambah memeriksa perilaku baru, bukan hanya struktur widget.
- Test tambahan mencakup visibilitas PIN, loading/submit, pemilihan layanan, navigasi, error/fallback kontak, dan layout jika fitur terkait diimplementasikan.
- Build web release berhasil; screenshot terang/gelap menggunakan data demo dan font asli.
- Ukur performa blur/scroll pada perangkat Android nyata dalam profile mode. Target kelancaran adalah tujuan verifikasi, bukan hasil benchmark yang sudah diperoleh.
- Jangan menyatakan perangkat Android sudah lulus sebelum pemeriksaan perangkat benar-benar dilakukan.

### Evaluasi pengguna sesudah implementasi

Uji singkat tugas menemukan estimasi, membuka nota, menghubungi outlet, serta mengubah alamat. Catat penyelesaian tugas, salah tekan, dan kebingungan; bandingkan dengan baseline. Jumlah peserta dan hasil belum tersedia.

## 9. Batas cakupan

- Backend/API, metode autentikasi telepon + PIN, harga, status, dan perhitungan pembayaran tetap mengikuti kontrak yang ada.
- Tidak menambahkan jemput, bayar online, reset PIN, notifikasi, checkout, hadiah, atau foto outlet fiktif sebagai fitur yang seolah sudah berjalan.
- Kontak/link baru memerlukan penanganan platform dan fallback yang diuji.
- Sembilan aset dan commit awal tetap dapat ditelusuri. Perencanaan ini tidak mengganti atau menghapusnya.
- Tidak melakukan push, deploy, atau publikasi desain tanpa instruksi lanjutan.

## Referensi teknis

- Flutter BackdropFilter: https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Baseline tema: `lib/core/theme/app_theme.dart`, `app_colors.dart`.
- Baseline material: `lib/core/widgets/app_card.dart`, `app_shell.dart`.
- Baseline interaksi: `lib/features/auth/presentation/`, `lib/features/home/presentation/home_page.dart`, `lib/features/pesanan/presentation/`.
