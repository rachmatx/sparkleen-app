# Rencana peningkatan UI/UX Sparkleen

Tanggal: 9 November 2026  
Baseline: `140786c` pada branch lokal `feat/sparkleen-visual-assets`  
Status: rencana dan konsep interaksi direvisi sesuai arahan pengguna; implementasi redesign belum dimulai.

Arahan visual terbaru: background solid, tanpa gradasi, material kaca lebih padat, dan detail lebih rapi/modern. Arahan ini menggantikan eksplorasi latar bercahaya pada konsep pertama.

## 1. Tujuan produk

Sparkleen membantu pelanggan menjawab empat pertanyaan: cucian sedang berada di tahap apa, kapan diperkirakan selesai, berapa biayanya, dan bagaimana menghubungi outlet. Prioritas visual mengikuti urutan tersebut.

Permintaan “100 kali lebih bagus” diterjemahkan menjadi perubahan yang dapat diperiksa: informasi utama ditemukan lebih cepat, tindakan tidak berulang, tampilan kaca memiliki kedalaman, formulir mudah dipakai, serta seluruh layar konsisten. Tidak ada klaim peningkatan numerik sebelum pengujian pengguna.

## 2. Temuan audit

| Temuan | Bukti baseline | Implikasi desain |
| --- | --- | --- |
| Kartu berukuran besar dan memiliki bobot visual yang hampir sama. | Beranda: sapaan, pesanan aktif, tombol penuh, katalog; kartu lain pada detail/profil. | Bedakan elemen utama, sekunder, dan baris informasi. Kurangi wadah yang tidak perlu. |
| Material kartu perlu diperhalus. | `AppCard` memakai blur 14 dan fill 0,72; beberapa area memakai bidang opaque. Background dominan tekstur tenun berulang. | Gunakan background solid dan permukaan kaca yang lebih padat, dengan tint, tepi, dan bayangan halus. |
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
- Background terang berupa satu warna solid `#EFF3F8`; background gelap satu warna solid `#101C2C`. Tidak ada bidang cahaya, tekstur, atau bentuk dekoratif pada latar.
- Tidak menggunakan linear/radial/conic gradient pada background, kartu, border, maupun tombol UI.
- Material kaca tampil lebih padat: opacity awal 95% pada kartu terang dan 96% pada kartu gelap; dock 98%. Transparansi hanya menjadi aksen sangat halus.
- Kedalaman berasal dari border tipis, garis highlight solid, tint, dan bayangan pendek. Tidak menggunakan sorotan yang dibentuk melalui gradasi.
- Kaca memiliki tiga tingkat penekanan: permukaan isi, kartu informasi utama, dan dock navigasi. Bedakan terutama melalui padding, border, dan bayangan; jaga seluruhnya tetap padat dan terbaca.
- Blur diklip sesuai batas elemen. Kartu di dalam kartu tidak otomatis mendapatkan blur lagi. Dock yang bertumpuk di atas isi tidak berbagi kelompok blur dengan isi yang tertutup.
- Rentang eksplorasi awal blur 8–12; efek tidak perlu dibuat kuat pada latar solid. Nilai akhir ditentukan melalui render dan pengukuran di perangkat, bukan dianggap sudah optimal.

### Tipografi dan geometri

- Pertahankan Plus Jakarta Sans untuk judul dan Manrope untuk isi.
- Skala awal: judul halaman 26–28, judul bagian 17–18, isi 14–15, keterangan 12–13 logical pixel. Ukuran mengikuti pembesaran teks sistem.
- Bobot 700 hanya untuk titik fokus seperti estimasi, nama, atau total. Label kecil tidak semuanya menjadi uppercase dengan jarak huruf lebar.
- Grid jarak 4/8; margin layar sekitar 20; radius kartu utama 22–24, kartu layanan 18, elemen kecil 12–16. Gunakan radius secara konsisten agar tampilan lebih terstruktur.
- Nominal dan tanggal memakai perataan yang konsisten; angka uang dapat menggunakan tabular figures.
- Target sentuh minimal 48 × 48 logical pixel. Jangan mengecilkan area interaksi agar tampak minimalis.

### Revisi keterbacaan mode terang

- Warna isi utama `#102A43`, isi pendukung `#40536A`, dan tautan/ikon aktif `#0B56C2`. Tombol utama tetap royal blue Sparkleen dengan teks putih.
- Tetapkan warna foreground secara eksplisit pada judul, label field, nominal, nama layanan, dan identitas. Pada konsep web, isolasi pewarisan warna dari tema host agar judul/label tidak berubah putih ketika permukaan aplikasi sedang terang.
- Keterangan bermakna minimal 12; label navigasi dan tindakan 13; nama layanan 14. Placeholder memakai opacity penuh. Pembesaran teks tidak boleh memotong informasi; baris boleh mengalir.
- Batas input memakai `#74869C` terhadap bidang `#F5F7FB`; garis tahap menunggu `#8193A8`, tahap selesai `#537FB9` dengan opacity penuh. Label tahap tetap ditampilkan.
- Ikon kontrol memakai ketebalan yang konsisten, sekitar 2 pada konsep. Status tidak dibedakan hanya melalui ikon/warna.
- Pasangan token dihitung memakai luminans relatif: teks utama pada putih 14,64:1; teks pendukung pada putih 7,88:1 dan pada canvas 7,08:1; biru pada tint `#E4EDFA` 5,69:1; batas input terhadap bidang 3,48:1. Angka ini pemeriksaan pasangan warna, belum audit piksel hasil render ataupun bukti seluruh UI memenuhi WCAG.
- Konsep revisi dibuka pada mode terang agar masalah yang sedang ditinjau langsung terlihat; tombol tema tetap tersedia. Ketentuan ini tidak mengubah preferensi tema pengguna pada aplikasi Flutter.

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
| `AppBackdrop` | Satu warna solid per tema, tanpa gradasi, tekstur, atau bidang cahaya. |
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
| B. Sistem visual | Token, background solid, dan komponen kaca padat pada Flutter. | Tanpa gradasi; kontras, clipping blur ringan, dan tema gelap terverifikasi. |
| C. Layar utama | Beranda dan masuk, dirender dari widget Flutter dengan data demo. | Status/estimasi serta formulir terlihat pada viewport sasaran; gambar tidak mendominasi. |
| D. Konsistensi alur | Pesanan, detail, nota, profil, edit, daftar, aktivasi, empty/error/loading. | Setiap aksi dan state bekerja; data dan route tetap benar. |
| E. Verifikasi | Analisis statis, test, build web, screenshot, pemeriksaan sentuh dan keyboard. | Tidak ada regresi, overflow, atau kontrol palsu. |
| F. Penyerahan | Commit lokal terpisah dari commit aset awal, ringkasan perubahan, dan bukti render. | Working tree bersih; push tetap menunggu instruksi pengguna. |

Perencanaan memakai audit source dan konsep interaksi. Eksekusi memakai implementasi dan render Flutter aktual; gambar generatif hanya diperlukan bila ada kebutuhan aset raster baru yang jelas. Konsep interaksi bukan bukti bahwa UI Flutter sudah diimplementasikan.

## 8. Kriteria penerimaan

### Visual dan kegunaan

- Background memakai satu warna solid per tema; tidak ada gradient pada dekorasi UI.
- Kartu dan dock terasa padat: isi di belakang tidak terlihat jelas melalui kaca. Acuan awal opacity 95–98%, dengan pengecekan visual sebelum nilai ditetapkan.
- Pada viewport 390 × 844 dengan ukuran teks normal, kartu aktif memperlihatkan status dan estimasi pada tampilan awal; pengguna tidak perlu melewati ilustrasi besar.
- Pada layar masuk dengan viewport yang sama dan keyboard tertutup, kedua field dan tombol masuk dapat ditemukan tanpa gulir panjang.
- Layout diperiksa pada lebar 320, 360, 390, dan 412 logical pixel serta layar lebih lebar yang dibatasi aplikasi.
- Pembesaran teks 1,0 / 1,5 / 2,0 tidak menyebabkan overflow; konten dapat mengalir dan digulir.
- Kontras teks utama/pendukung ditargetkan sekurang-kurangnya 4,5:1 terhadap latar efektif, termasuk pada area kaca yang bertumpuk.
- Batas kontrol dan indikator proses yang dibutuhkan untuk memahami state ditargetkan minimal 3:1 terhadap permukaan sekitar. Periksa juga halaman profil, masuk, filter pesanan, dan sheet detail/edit pada mode terang.
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
