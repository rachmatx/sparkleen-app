# Sparkleen Mobile Pelanggan

Aplikasi Android pelanggan Sparkleen Laundry. Dibangun dengan Flutter dan terhubung ke
REST API `/api/v1` yang berjalan di backend CodeIgniter 4 (`sparkleen-laundry`).

## Fitur

- Masuk dengan nomor telepon + PIN, daftar akun baru, aktivasi pelanggan lama dengan nomor nota.
- Beranda: sapaan, pesanan aktif, katalog layanan + harga, dan poin pelanggan.
- Riwayat pesanan dengan filter Aktif / Selesai / Semua dan pagination.
- Detail pesanan: timeline status, rincian layanan, pembayaran, dan PIN pengambilan.
- Nota digital (tanpa PIN pengambilan).
- Profil, ubah nama/alamat, dan keluar akun.

## Kebutuhan

- Flutter 3.47+ (Dart 3.13+).
- Android SDK untuk build APK.
- Backend Sparkleen `/api/v1` berjalan.

## Menjalankan

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Pilihan `API_BASE_URL`:

| Target | Nilai |
|---|---|
| Emulator Android + backend lokal | `http://10.0.2.2:8080` (default) |
| Device fisik + backend LAN | `http://<IP-LAN-komputer>:8080` |
| Backend Railway | `https://<nama-service>.up.railway.app` |

Tanpa `--dart-define`, aplikasi memakai `http://10.0.2.2:8080`. Untuk device fisik,
pastikan ponsel dan komputer berada di jaringan yang sama. Koneksi HTTP polos ke IP
lokal diizinkan lewat `android/app/src/debug/AndroidManifest.xml`; build release
sebaiknya memakai HTTPS.

### Variasi shell

CMD (Command Prompt):

```bat
set "API_URL=https://<nama-service>.up.railway.app"
flutter run --dart-define=API_BASE_URL=%API_URL%
```

PowerShell:

```powershell
$env:API_URL = "https://<nama-service>.up.railway.app"
flutter run --dart-define=API_BASE_URL=$env:API_URL
```

Git Bash:

```bash
export API_URL="https://<nama-service>.up.railway.app"
flutter run --dart-define=API_BASE_URL="$API_URL"
```

Linux / macOS:

```bash
export API_URL="https://<nama-service>.up.railway.app"
flutter run --dart-define=API_BASE_URL="$API_URL"
```

## Build APK

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Hasil build: `build/app/outputs/flutter-apk/app-debug.apk`.

## Analisis dan test

```bash
flutter analyze
flutter test
```

## Struktur

```
lib/
  core/       tema, api client, storage token, router, widget bersama, formatter
  features/
    auth/     login, register, aktivasi, state auth
    home/     beranda, layanan, outlet
    pesanan/  riwayat, detail, timeline
    nota/     nota digital
    profil/   profil dan edit data
    splash/   layar awal
```

## Keamanan

- Token hanya disimpan di secure storage dan tidak pernah ditulis ke log.
- PIN pengambilan hanya tampil di detail pesanan; payload nota tidak memuat PIN.
- Respons `401` menghapus token dan mengembalikan pengguna ke halaman masuk.

## Dokumen

- Spesifikasi: [`docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md`](docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md)
- Plan Flutter fase 1: [`docs/superpowers/plans/2026-10-24-sparkleen-mobile-flutter-phase1.md`](docs/superpowers/plans/2026-10-24-sparkleen-mobile-flutter-phase1.md)
- Plan backend fase 1: [`docs/superpowers/plans/2026-10-23-sparkleen-mobile-api-backend.md`](docs/superpowers/plans/2026-10-23-sparkleen-mobile-api-backend.md)
- Kontrak API: [`docs/api/sparkleen-mobile-v1.md`](docs/api/sparkleen-mobile-v1.md)
- Postman: [`docs/api/sparkleen-mobile-v1.postman_collection.json`](docs/api/sparkleen-mobile-v1.postman_collection.json)

## Status

Fase 1 selesai: seluruh layar utama terhubung ke API, `flutter analyze` bersih, dan
`flutter test` hijau. Uji manual di emulator/device mengikuti langkah di atas.
