# Sparkleen Mobile Pelanggan — Flutter Fase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplikasi Android pelanggan Sparkleen Laundry: login/aktivasi PIN, beranda,
daftar & detail pesanan, timeline status, nota digital, profil. Terhubung ke API
`/api/v1` yang sudah selesai di backend.

**Architecture:** Flutter feature-first. Riverpod (`Notifier`/`AsyncNotifier`) untuk state,
go_router untuk navigasi + guard auth, dio untuk HTTP, flutter_secure_storage untuk token.
Semua data berasal dari REST API; tidak ada logika harga/poin di app.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_riverpod 3.x, go_router 18.x, dio 5.x,
flutter_secure_storage 11.x, intl, google_fonts, shimmer.

**Spesifikasi:** `docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md`
**Kontrak API:** `docs/api/sparkleen-mobile-v1.md`

**Konvensi wajib:**
- Uang = `int` rupiah. Tanggal dari API sudah ISO-8601 `+07:00`; format tampilan via `intl`.
- Token **hanya** di secure storage; tidak pernah di log/print.
- 401 dari API mana pun → hapus token + kembali ke `/login`.
- Setiap layar wajib punya state loading, empty, error — bukan hanya happy path.
- Base URL dari `--dart-define=API_BASE_URL=...` (default `http://10.0.2.2:8080` untuk
  emulator Android; device fisik pakai IP LAN, contoh `http://192.168.1.10:8080`).

**Design token (spec §8):**
| Token | Nilai |
|---|---|
| primary | `#2F2DD2` |
| background | `#FFFFFF` |
| surface | `#F8F9FC` |
| border | `#E2E8F0` |
| text | `#0D0F1A` |
| muted | `#64748B` |
| radius kartu / input / sheet | 14 / 10 / 20 |
| font | Plus Jakarta Sans (judul), Manrope (body) |

---

### Task 1: Skeleton tema, router, konfigurasi API

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/api/api_config.dart`
- Create: `lib/core/router/app_router.dart` (placeholder routes dulu)
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `AppColors`, `buildAppTheme()`, `ApiConfig.baseUrl`, `appRouter`.

- [ ] **Step 1:** Tulis `AppColors` berisi seluruh token di tabel atas.
- [ ] **Step 2:** `app_theme.dart` membuat `ThemeData` Material 3: `colorSchemeSeed`
  primary, `scaffoldBackgroundColor` putih, `CardTheme` radius 14 + border halus,
  `InputDecorationTheme` radius 10, font family Google Fonts.
- [ ] **Step 3:** `api_config.dart`:

```dart
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static const apiPrefix = '/api/v1';
  static String get apiBase => '$baseUrl$apiPrefix';
}
```

- [ ] **Step 4:** `main.dart` menjadi `ProviderScope(child: SparkleenApp())` dan
  `MaterialApp.router(routerConfig: appRouter, theme: buildAppTheme())`.
- [ ] **Step 5:** Jalankan `flutter analyze` → harus 0 error.
- [ ] **Step 6:** Commit `feat(app): skeleton tema dan konfigurasi api`.

---

### Task 2: API client, error mapping, secure storage

**Files:**
- Create: `lib/core/storage/token_storage.dart`
- Create: `lib/core/api/api_exception.dart`
- Create: `lib/core/api/api_client.dart`
- Create: `lib/core/providers.dart`
- Test: `test/core/api_exception_test.dart`

**Interfaces:**
- Produces:
  - `TokenStorage.read()/save()/clear()`
  - `ApiException(code, message, statusCode, fields)`
  - `ApiClient.get/post/patch/delete<T>` mengembalikan `Map<String, dynamic>` / `List<dynamic>` parsed
- Consumes: `ApiConfig`.

- [ ] **Step 1:** `TokenStorage` memakai `FlutterSecureStorage`, key `sparkleen_token`.
- [ ] **Step 2:** `ApiException.fromResponse(Response)` membaca
  `error.code`, `error.message`, `error.fields`; fallback `NETWORK_ERROR` untuk
  `DioExceptionType.connectionTimeout/connectionError`.
- [ ] **Step 3:** `ApiClient` membuat Dio dengan `baseUrl: ApiConfig.apiBase`,
  `connectTimeout/receiveTimeout 15s`, header `Accept: application/json`.
  Interceptor menambahkan `Authorization: Bearer <token>` bila ada. Pada status 401,
  panggil callback `onUnauthorized` (di-set dari provider auth) — jangan import auth
  secara langsung untuk menghindari siklus.
- [ ] **Step 4:** Provider: `tokenStorageProvider`, `apiClientProvider`.
- [ ] **Step 5:** Test unit `ApiException` untuk payload error valid dan payload rusak.
- [ ] **Step 6:** `flutter test test/core/api_exception_test.dart` → PASS.
- [ ] **Step 7:** Commit `feat(app): api client dan penyimpanan token`.

---

### Task 3: Model data

**Files:**
- Create: `lib/features/auth/data/pelanggan.dart`
- Create: `lib/features/home/data/layanan.dart`
- Create: `lib/features/home/data/outlet_info.dart`
- Create: `lib/features/pesanan/data/transaksi_ringkas.dart`
- Create: `lib/features/pesanan/data/transaksi_detail.dart`
- Create: `lib/features/nota/data/nota_data.dart`
- Test: `test/features/models_test.dart`

**Interfaces (field mengikuti API, uang `int`, tanggal `DateTime`):**
- `Pelanggan.fromJson` → id, kode, nama, noTelp, alamat, poin, totalTransaksi
- `Layanan.fromJson` → id, nama, hargaPerKg, estimasiHari
- `OutletInfo.fromJson` → nama, noWa, alamat, jamBuka, jamTutup
- `TransaksiRingkas.fromJson` → id, noNota, tglMasuk, tglEstimasi, totalBerat (double),
  grandTotal (int), status, statusLabel
- `TransaksiDetail` → ringkasan + tglAktual?, totalBiaya, diskon, statusPembayaran,
  metodePembayaran?, pinPengambilan, items, pembayaran, timeline
- `TimelineStep` → status, label, at?, state (`done|current|pending`)
- `NotaData` → outlet, noNota, tanggal, items, subtotal, diskon, grandTotal,
  metode?, statusPembayaran

- [ ] **Step 1:** Tulis semua model dengan `factory fromJson` dan cast defensif
  (`(json['grand_total'] as num).toInt()`).
- [ ] **Step 2:** Test parsing memakai contoh JSON dari `docs/api/sparkleen-mobile-v1.md`;
  pastikan `DateTime.parse` menghasilkan offset +07:00 dan money int.
- [ ] **Step 3:** `flutter test test/features/models_test.dart` → PASS.
- [ ] **Step 4:** Commit `feat(app): model data api`.

---

### Task 4: Auth (login, register, aktivasi) + guard router

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`
- Create: `lib/features/auth/application/auth_controller.dart`
- Create: `lib/features/auth/presentation/login_page.dart`
- Create: `lib/features/auth/presentation/register_page.dart`
- Create: `lib/features/auth/presentation/activate_page.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/auth_controller_test.dart` (fake repository)

**Interfaces:**
- `AuthRepository.login(noTelp, pin)`, `register(...)`, `activate(...)`,
  `me()`, `updateMe(...)`, `logout()` → mengembalikan hasil API, menyimpan token.
- `AuthState`: `unknown | unauthenticated | authenticated(Pelanggan)`.
- `AuthController extends AsyncNotifier<AuthState>`; method `login`, `register`,
  `activate`, `logout`, `refreshMe`, `updateProfile`.
  `build()` membaca token; bila ada → `me()`; bila 401 → unauthenticated.

- [ ] **Step 1:** Repository memanggil `ApiClient` ke `/auth/login`, `/auth/register`,
  `/auth/activate`, `/me`, `/auth/logout`; simpan `data.token` lewat `TokenStorage`.
- [ ] **Step 2:** Controller menangani `ApiException` agar pesan `fields` bisa ditampilkan
  per input (mis. `pin`, `no_telp`).
- [ ] **Step 3:** go_router `redirect`: state auth unknown → splash; unauthenticated dan
  bukan di `/login|/register|/activate` → `/login`; authenticated dan di auth route →
  `/beranda`.
- [ ] **Step 4:** UI: form dengan validasi lokal (nama 3–100, alamat ≥5, PIN 6 digit),
  tombol disabled saat submit, error banner, link antar tiga halaman auth.
- [ ] **Step 5:** Widget test minimal: PIN < 6 digit → pesan validasi, tombol tidak submit.
- [ ] **Step 6:** `flutter analyze && flutter test` → PASS.
- [ ] **Step 7:** Commit `feat(app): autentikasi pin dan guard navigasi`.

---

### Task 5: App shell + 3 tab

**Files:**
- Create: `lib/core/widgets/app_shell.dart`
- Create: `lib/features/home/presentation/home_page.dart` (placeholder)
- Create: `lib/features/pesanan/presentation/pesanan_page.dart` (placeholder)
- Create: `lib/features/profil/presentation/profil_page.dart` (placeholder)
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1:** `StatefulShellRoute.indexedStack` dengan tiga branch:
  `/beranda`, `/pesanan`, `/profil`.
- [ ] **Step 2:** `AppShell` memakai `NavigationBar` (Material 3), ikon home/receipt/person.
- [ ] **Step 3:** Placeholder tiap page hanya judul + `const SizedBox()` agar router bisa
  diverifikasi lebih dulu.
- [ ] **Step 4:** `flutter analyze` → PASS.
- [ ] **Step 5:** Commit `feat(app): shell navigasi tiga tab`.

---

### Task 6: Beranda

**Files:**
- Create: `lib/features/home/data/home_repository.dart`
- Create: `lib/features/home/application/home_providers.dart`
- Modify: `lib/features/home/presentation/home_page.dart`
- Create: `lib/core/widgets/async_value_view.dart`

**Interfaces:**
- `Future<List<Layanan>> layanan()` → GET `/layanan`
- `Future<OutletInfo> outlet()` → GET `/outlet`
- `Future<List<TransaksiRingkas>> pesananAktif()` → GET `/transaksi?status=aktif&per_page=1`

- [ ] **Step 1:** Provider `FutureProvider` untuk layanan, outlet, pesanan aktif.
- [ ] **Step 2:** UI beranda: sapaan nama pelanggan, kartu pesanan aktif (status + estimasi;
  tap → detail), tiga aksi cepat (Pesan/Lacak/WA — Pesan & Lacak arahkan ke tab Pesanan,
  WA membuka `https://wa.me/<no_wa>` lewat `url_launcher` **atau** `Clipboard` bila
  tidak ingin menambah dependency), daftar layanan + harga, kartu poin.
- [ ] **Step 3:** `AsyncValueView` menangani loading (shimmer), error (retry), empty.
- [ ] **Step 4:** Widget test: provider kosong → empty state muncul.
- [ ] **Step 5:** Commit `feat(app): beranda pesanan aktif dan katalog`.

---

### Task 7: Daftar pesanan

**Files:**
- Create: `lib/features/pesanan/data/transaksi_repository.dart`
- Create: `lib/features/pesanan/application/pesanan_controller.dart`
- Modify: `lib/features/pesanan/presentation/pesanan_page.dart`
- Create: `lib/features/pesanan/presentation/widgets/transaksi_card.dart`
- Test: `test/features/pesanan_controller_test.dart`

**Interfaces:**
- `TransaksiRepository.list({status, page, perPage})` → `(items, meta)`.
- `PesananState`: `items`, `page`, `lastPage`, `scope`, `isLoadingMore`, `error`.
- `PesananController extends AsyncNotifier<PesananState>`; `load(scope)`,
  `loadMore()`, `refresh()`.

- [ ] **Step 1:** SegmentedButton `Aktif | Selesai | Semua`; ganti scope → reset page 1.
- [ ] **Step 2:** List `TransaksiCard`: no nota, tanggal, status chip (warna per status),
  berat, grand total, chevron ke detail.
- [ ] **Step 3:** Infinite scroll: muat halaman berikutnya saat mendekati akhir;
  `RefreshIndicator` untuk pull-to-refresh.
- [ ] **Step 4:** Test controller dengan fake repository: scope berubah memanggil page 1,
  `loadMore` menambah item tanpa duplikat.
- [ ] **Step 5:** Commit `feat(app): daftar pesanan dengan filter dan pagination`.

---

### Task 8: Detail pesanan + timeline

**Files:**
- Modify: `lib/features/pesanan/data/transaksi_repository.dart` (`detail(id)`)
- Create: `lib/features/pesanan/presentation/detail_pesanan_page.dart`
- Create: `lib/features/pesanan/presentation/widgets/timeline_status.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1:** Route `/pesanan/:id` (int).
- [ ] **Step 2:** Header: no nota, status chip, estimasi selesai, tombol "Lihat Nota".
- [ ] **Step 3:** `TimelineStatus`: 5 langkah vertikal; `done` cek hijau + waktu,
  `current` titik primary + label tebal, `pending` abu; waktu null → "Menunggu".
- [ ] **Step 4:** Kartu item (nama, berat, harga/kg, subtotal) dan kartu pembayaran
  (nominal, metode, status).
- [ ] **Step 5:** Kartu PIN pengambilan hanya di detail, dengan tombol salin
  (`Clipboard.setData`) — jangan pernah muncul di daftar/nota.
- [ ] **Step 6:** Test widget: timeline `current` dan `pending` dirender dengan state benar.
- [ ] **Step 7:** Commit `feat(app): detail pesanan dan timeline status`.

---

### Task 9: Nota digital

**Files:**
- Create: `lib/features/nota/presentation/nota_page.dart`
- Modify: `lib/features/pesanan/data/transaksi_repository.dart` (`nota(id)`)
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1:** Route `/pesanan/:id/nota`, ambil GET `/transaksi/{id}/nota`.
- [ ] **Step 2:** Render struk: logo wordmark teks, info outlet, no nota, tanggal,
  daftar item, subtotal/diskon/grand total, metode + status pembayaran,
  footer "Terima kasih".
- [ ] **Step 3:** Pastikan `pin_pengambilan` tidak dirender dan tidak ada di model nota.
- [ ] **Step 4:** Widget test: teks total dan no nota tampil; PIN tidak ada.
- [ ] **Step 5:** Commit `feat(app): nota digital`.

---

### Task 10: Profil

**Files:**
- Modify: `lib/features/profil/presentation/profil_page.dart`
- Create: `lib/features/profil/presentation/edit_profil_page.dart`
- Modify: `lib/features/auth/application/auth_controller.dart`

- [ ] **Step 1:** Tampilkan nama, kode pelanggan, no telepon, poin, total transaksi.
- [ ] **Step 2:** Edit profil (nama, alamat) via PATCH `/me`; no telepon read-only dengan
  keterangan "Hubungi outlet untuk ubah nomor".
- [ ] **Step 3:** Tombol keluar dengan dialog konfirmasi → POST `/auth/logout` → hapus token
  → redirect `/login` (tetap logout lokal walau request gagal).
- [ ] **Step 4:** Test widget: logout memanggil repository dan state menjadi unauthenticated.
- [ ] **Step 5:** Commit `feat(app): profil dan edit data pelanggan`.

---

### Task 11: Polish, test menyeluruh, build APK

**Files:**
- Modify: seluruh layar untuk empty/error/loading konsisten.
- Create: `README.md` (cara run + `API_BASE_URL`).
- Create: `test/smoke_test.dart`

- [ ] **Step 1:** Audit setiap layar: minimal satu empty state dan satu error state.
- [ ] **Step 2:** `flutter analyze` → 0 issue.
- [ ] **Step 3:** `flutter test` → semua PASS.
- [ ] **Step 4:** Jalankan manual di emulator terhadap backend lokal:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
  Uji: register → logout → login → beranda → daftar → detail → nota → edit profil.
- [ ] **Step 5:** `flutter build apk --debug --dart-define=API_BASE_URL=https://<host-railway>`.
- [ ] **Step 6:** Commit `chore(app): polish state dan build apk fase 1`.

---

## Verifikasi akhir Fase 1

- [ ] `flutter analyze` bersih.
- [ ] `flutter test` hijau.
- [ ] Semua 11 endpoint API terpakai oleh app (kecuali `auth/activate` yang hanya untuk
  pelanggan lama).
- [ ] Tidak ada token/PIN tercetak di log.
- [ ] APK debug terpasang dan alur utama berjalan di device/emulator.

## Di luar cakupan (fase 2)

Permintaan jemput, halaman kasir permintaan jemput, notifikasi WhatsApp otomatis,
Play Store release, iOS build.
