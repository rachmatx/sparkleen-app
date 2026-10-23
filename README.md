# Sparkleen Mobile Pelanggan

Aplikasi Android pelanggan Sparkleen Laundry. Dibangun dengan Flutter dan terhubung ke
REST API `/api/v1` yang berjalan di backend CodeIgniter 4 (`sparkleen-laundry`).

## Dokumen

- Spesifikasi: [`docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md`](docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md)
- Plan Flutter fase 1: [`docs/superpowers/plans/2026-10-24-sparkleen-mobile-flutter-phase1.md`](docs/superpowers/plans/2026-10-24-sparkleen-mobile-flutter-phase1.md)
- Plan backend fase 1: [`docs/superpowers/plans/2026-10-23-sparkleen-mobile-api-backend.md`](docs/superpowers/plans/2026-10-23-sparkleen-mobile-api-backend.md)
- Kontrak API: [`docs/api/sparkleen-mobile-v1.md`](docs/api/sparkleen-mobile-v1.md)
- Postman: [`docs/api/sparkleen-mobile-v1.postman_collection.json`](docs/api/sparkleen-mobile-v1.postman_collection.json)

## Menjalankan

Base URL API diberikan lewat `--dart-define`:

```bash
# Emulator Android, backend lokal (XAMPP)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Device fisik, backend di LAN
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080

# Backend Railway
flutter run --dart-define=API_BASE_URL=https://<nama-service>.up.railway.app
```

Tanpa `--dart-define`, aplikasi memakai `http://10.0.2.2:8080`.

Backend lokal harus melayani `/api/v1` dan database sudah dimigrasi. Untuk Android 9+,
koneksi HTTP polos ke IP lokal diizinkan lewat konfigurasi network security (belum diubah
di scaffold; aktifkan saat uji device fisik bila perlu).

## Perintah

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=https://<host>
```

## Status

- Backend API fase 1: selesai (branch `feature/mobile-api` di repo `sparkleen-laundry`).
- App Flutter: scaffold + plan fase 1; implementasi mengikuti plan.
