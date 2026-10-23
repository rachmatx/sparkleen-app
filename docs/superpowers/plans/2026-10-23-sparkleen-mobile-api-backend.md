# Sparkleen Mobile API — Backend Fase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** REST API `/api/v1` di aplikasi CodeIgniter 4 yang sudah ada, supaya app pelanggan bisa login, melihat layanan, transaksi, timeline status, nota digital, dan poin — tanpa mengubah `tb_transaksi` atau alur kasir.

**Architecture:** Satu route group baru `api/v1` dengan filter auth sendiri (Bearer token opaque, disimpan sebagai SHA-256). Controller tipis di `app/Controllers/Api/V1/`, query dan presentasi di model/library terpisah. Filter global `auth` dan `csrf` milik web dikecualikan untuk `api/*`, jadi API tidak pernah membalas redirect atau HTML.

**Tech Stack:** PHP 8.2, CodeIgniter 4.7, MySQLi, PHPUnit 10.5, dompdf (tidak dipakai fase 1).

**Spec:** `docs/superpowers/specs/2026-10-23-sparkleen-mobile-api-design.md`

## Global Constraints

- PHP 8.2, CodeIgniter 4.7, PHPUnit 10.5. **Tanpa dependency Composer baru.**
- Semua response JSON: sukses `{"data":...}`, list `{"data":[...],"meta":{page,per_page,total,last_page}}`, error `{"error":{code,message,fields}}`.
- Uang di JSON selalu integer rupiah (`(int) round((float) $value)`), tidak pernah float/string.
- Tanggal ISO-8601 `+07:00`. `Config\App::$appTimezone` sudah `Asia/Jakarta` — jangan diubah.
- Pesan `message` dan label status berbahasa Indonesia.
- Migrasi **additive only**: kolom nullable baru + tabel baru. `tb_transaksi` tidak diubah.
- Jangan pernah log PIN, token, atau hash.
- Token plaintext hanya dikirim sekali saat issue; DB menyimpan `hash('sha256', $token)`.
- Test berjalan di DB `laundry_db_test`, tidak pernah di DB production.
- Nama kelas migration = nama file tanpa prefix tanggal.
- Ikuti gaya kode yang ada: namespace `App\...`, model `M*`, pesan Indonesia.

## Review Focus

1. **Isolasi data antar pelanggan** — token pelanggan A membuka `GET /transaksi/{id}` milik B harus `404`, bukan `200`. (Task 7)
2. **Format nomor HP campur** — `0812...` dan `62812...` harus dianggap nomor yang sama saat daftar, login, dan aktivasi. (Task 4)
3. **Token kedaluwarsa / di-revoke** — harus `401` JSON `AUTH_INVALID_TOKEN`, bukan redirect HTML ke `/login`. (Task 3)
4. **Transaksi lama tanpa `id_status_transaksi`** — timeline tetap tampil dari kolom enum `status`, bukan `500`. (Task 7)
5. **Nilai desimal di DB** — `grand_total` `42500.50` harus jadi `42501`, dan `42500.00` jadi `42500`, bukan `42500.0` atau string. (Task 6)

---

### Task 1: API skeleton, test harness, filter exclusion

**Files:**
- Create: `phpunit.xml.dist`
- Create: `app/Controllers/Api/V1/BaseApiController.php`
- Create: `app/Controllers/Api/V1/PingController.php`
- Modify: `app/Config/Routes.php` (tambah group di akhir file)
- Modify: `app/Config/Filters.php` (tambah `api/v1`, `api/v1/*` ke `except` milik `auth` dan `csrf`)
- Modify: `app/Config/Cors.php` (`allowedOrigins`, `allowedHeaders`, `allowedMethods`)
- Test: `tests/Feature/Api/PingTest.php`

**Interfaces:**
- Consumes: tidak ada.
- Produces: `App\Controllers\Api\V1\BaseApiController` dengan
  `ok(mixed $data = null, array $meta = [], int $status = 200): ResponseInterface`,
  `fail(string $code, string $message, int $status, array $fields = []): ResponseInterface`,
  `noContent(): ResponseInterface`.

- [ ] **Step 1: Buat branch dan DB test**

```bash
git checkout -b feature/mobile-api
C:\xampp\mysql\bin\mysql -u root -e "CREATE DATABASE IF NOT EXISTS laundry_db_test CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
```

- [ ] **Step 2: Tulis `phpunit.xml.dist`**

Isi: `bootstrap="tests/phpunit_bootstrap.php"`, `cacheDirectory=".phpunit.cache"`, `<env name="CI_ENVIRONMENT" value="testing"/>`, `<server name="app.baseURL" value="http://localhost:8080/"/>`, dan tiga testsuite: `Unit` → `tests/unit`, `Feature` → `tests/Feature`, `Database` → `tests/database`. Jangan pakai `failOnWarning`/`failOnRisky` agar suite lama tidak pecah.

- [ ] **Step 3: Tulis test yang gagal**

```php
// tests/Feature/Api/PingTest.php
namespace Tests\Feature\Api;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\FeatureTestTrait;

final class PingTest extends CIUnitTestCase
{
    use FeatureTestTrait;

    public function testPingReturnsJsonWithoutLogin(): void
    {
        $result = $this->call('get', 'api/v1/ping');

        $result->assertStatus(200);
        $this->assertSame('ok', $result->getJSON()->data->status);
        $this->assertStringNotContainsString('<html', strtolower($result->getBody()));
    }
}
```

- [ ] **Step 4: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PingTest`
Expected: FAIL — route `api/v1/ping` tidak ada / ter-redirect ke login.

- [ ] **Step 5: Implementasi**

`BaseApiController` extends `App\Controllers\BaseController`, helper di atas memakai `$this->response->setStatusCode($status)->setJSON([...])`.
`PingController::index()` mengembalikan `$this->ok(['status' => 'ok'])`.
Di `Routes.php`:

```php
$routes->group('api/v1', ['namespace' => 'App\Controllers\Api\V1'], static function ($routes) {
    $routes->get('ping', 'PingController::index');
});
```

Di `Filters.php`, `$globals['before']['auth']['except'][] = 'api/v1'; ...[] = 'api/v1/*';` dan hal yang sama untuk `csrf`.
Di `Cors.php`: `allowedOrigins = ['*']`, `allowedHeaders = ['Authorization','Content-Type','Accept']`, `allowedMethods = ['GET','POST','PATCH','OPTIONS']`.

- [ ] **Step 6: Jalankan, pastikan lulus + suite lama tetap hijau**

Run: `php vendor/bin/phpunit --filter PingTest`
Expected: PASS
Run: `php vendor/bin/phpunit --testsuite Feature`
Expected: PASS (semua test lama tetap lulus)

- [ ] **Step 7: Commit**

```bash
git add phpunit.xml.dist app/Controllers/Api app/Config/Routes.php app/Config/Filters.php app/Config/Cors.php tests/Feature/Api/PingTest.php
git commit -m "feat(api): tambah skeleton /api/v1 dan harness test"
```

---

### Task 2: Migrasi auth mobile + model token

**Files:**
- Create: `app/Database/Migrations/2026-10-23-000001_AddMobileAuthToPelanggan.php`
- Create: `app/Database/Migrations/2026-10-23-000002_CreateApiTokenTable.php`
- Create: `app/Models/MApiToken.php`
- Create: `tests/_support/Api/ApiTestTrait.php`
- Test: `tests/database/ApiTokenModelTest.php`

**Interfaces:**
- Consumes: `tb_pelanggan` existing.
- Produces:
  - `MApiToken::issue(int $idPelanggan, ?string $deviceName = null): array` → `['token' => string, 'expires_at' => string]`
  - `MApiToken::findValid(string $plainToken): ?array` → baris token + `id_pelanggan`, atau `null`
  - `MApiToken::extend(int $idToken): void` (perpanjang 30 hari, set `last_used_at`)
  - `MApiToken::revoke(string $plainToken): void`
  - `MApiToken::revokeAllFor(int $idPelanggan): void`
  - `Tests\Support\Api\ApiTestTrait::createPelanggan(array $override = []): array`
  - `Tests\Support\Api\ApiTestTrait::createTokenFor(array $pelanggan, ?string $expiresAt = null): array` → `['token' => string, 'id_token' => int]`
  - `createPelanggan()` membuat `no_telp` unik otomatis bila tidak di-override (counter statis `6281200000001`, `...002`, dst), `pin_hash = password_hash('123456', PASSWORD_DEFAULT)`, `is_aktif = 1`.

- [ ] **Step 1: Tulis test yang gagal**

```php
// tests/database/ApiTokenModelTest.php
namespace Tests\Database;

use App\Models\MApiToken;
use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;

final class ApiTokenModelTest extends CIUnitTestCase
{
    use DatabaseTestTrait;

    protected $migrate = true;
    protected $DBGroup = 'tests';

    public function testPinColumnsExist(): void
    {
        $db = db_connect('tests');
        $this->assertTrue($db->fieldExists('pin_hash', 'tb_pelanggan'));
        $this->assertTrue($db->fieldExists('pin_set_at', 'tb_pelanggan'));
        $this->assertTrue($db->fieldExists('last_login_at', 'tb_pelanggan'));
    }

    public function testIssueStoresHashNotPlaintext(): void
    {
        $id = db_connect('tests')->table('tb_pelanggan')->insert([
            'kode_pelanggan' => 'PLG9001', 'nama_pelanggan' => 'Uji',
            'no_telp' => '6281200000001', 'alamat' => 'Jl. Uji', 'is_aktif' => 1,
        ], true);

        $issued = (new MApiToken())->issue((int) $id, 'android');
        $row = db_connect('tests')->table('tb_api_token')->where('id_pelanggan', $id)->get()->getRowArray();

        $this->assertSame(64, strlen($row['token_hash']));
        $this->assertNotSame($issued['token'], $row['token_hash']);
        $this->assertSame(hash('sha256', $issued['token']), $row['token_hash']);
        $this->assertNotNull((new MApiToken())->findValid($issued['token']));
    }

    public function testExpiredAndRevokedTokenNotFound(): void
    {
        $model = new MApiToken();
        $issued = $model->issue(9001);
        $model->revoke($issued['token']);
        $this->assertNull($model->findValid($issued['token']));
    }
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter ApiTokenModelTest`
Expected: FAIL — tabel/kolom belum ada.

- [ ] **Step 3: Implementasi migrasi**

`AddMobileAuthToPelanggan`: `addColumn('tb_pelanggan', ...)` untuk `pin_hash VARCHAR(255) NULL`, `pin_set_at DATETIME NULL`, `last_login_at DATETIME NULL`. `down()` drop ketiganya.
`CreateApiTokenTable`: field persis seperti spec §7.3, plus `INDEX (id_pelanggan)`, `UNIQUE (token_hash)`, FK `id_pelanggan` → `tb_pelanggan` `ON DELETE CASCADE`.

- [ ] **Step 4: Implementasi `MApiToken`**

Token: `bin2hex(random_bytes(32))` (64 hex). `expires_at = date('Y-m-d H:i:s', strtotime('+30 days'))`. `findValid()` hanya mengembalikan baris dengan `revoked_at IS NULL` dan `expires_at >` sekarang. `extend()` memperbarui `expires_at` +30 hari dan `last_used_at`.

- [ ] **Step 5: Implementasi `ApiTestTrait`**

Insert pelanggan langsung via query builder (jangan lewat model agar validasi tidak mengganggu), default `pin_hash = password_hash('123456', PASSWORD_DEFAULT)`, `is_aktif = 1`. `createTokenFor()` memakai `MApiToken::issue()`.

- [ ] **Step 6: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter ApiTokenModelTest`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/Database/Migrations app/Models/MApiToken.php tests/_support/Api tests/database/ApiTokenModelTest.php
git commit -m "feat(api): migrasi pin pelanggan dan tabel token api"
```

---

### Task 3: Auth guard + `GET /me`

**Files:**
- Create: `app/Libraries/PhoneNumber.php`
- Create: `app/Libraries/ApiContext.php`
- Create: `app/Filters/ApiAuthFilter.php`
- Create: `app/Controllers/Api/V1/AuthController.php` (method `me()` saja di task ini)
- Modify: `app/Config/Filters.php` (alias `apiauth`)
- Modify: `app/Config/Services.php` (service `apiContext`)
- Modify: `app/Config/Routes.php` (route `me` di dalam group dengan filter `apiauth`)
- Test: `tests/unit/Libraries/PhoneNumberTest.php`
- Test: `tests/Feature/Api/AuthGuardTest.php`

**Interfaces:**
- Consumes: `MApiToken::findValid()`, `MApiToken::extend()`.
- Produces:
  - `PhoneNumber::normalize(string $phone): string` → `62...`
  - `PhoneNumber::variants(string $phone): array` → dua bentuk unik (`62...`, `08...`)
  - `service('apiContext')->pelanggan` (array|null), `->idToken` (int|null)
  - `ApiAuthFilter` mengembalikan `401` JSON dan tidak pernah redirect.

- [ ] **Step 1: Tulis test yang gagal**

```php
// tests/unit/Libraries/PhoneNumberTest.php
public function testNormalizeHandlesLocalAndInternational(): void
{
    $this->assertSame('628123456789', PhoneNumber::normalize('08123456789'));
    $this->assertSame('628123456789', PhoneNumber::normalize('+62 812-3456-789'));
    $this->assertSame('628123456789', PhoneNumber::normalize('628123456789'));
    $this->assertSame(['628123456789', '08123456789'], PhoneNumber::variants('08123456789'));
}
```

```php
// tests/Feature/Api/AuthGuardTest.php
public function testMissingTokenReturnsJson401NotRedirect(): void
{
    $result = $this->call('get', 'api/v1/me');
    $result->assertStatus(401);
    $this->assertStringContainsString('AUTH_REQUIRED', $result->getJSON());
    $this->assertStringNotContainsString('<html', strtolower($result->getBody()));
}

public function testRevokedTokenReturns401(): void
{
    $pelanggan = $this->createPelanggan();
    $issued = $this->createTokenFor($pelanggan);
    (new MApiToken())->revoke($issued['token']);

    $result = $this->withHeaders(['Authorization' => 'Bearer ' . $issued['token']])->call('get', 'api/v1/me');
    $result->assertStatus(401);
    $this->assertStringContainsString('AUTH_INVALID_TOKEN', $result->getJSON());
}

public function testValidTokenReturnsOwnProfile(): void
{
    $pelanggan = $this->createPelanggan(['nama_pelanggan' => 'Siti']);
    $issued = $this->createTokenFor($pelanggan);

    $result = $this->withHeaders(['Authorization' => 'Bearer ' . $issued['token']])->call('get', 'api/v1/me');
    $result->assertStatus(200);
    $this->assertSame('Siti', $result->getJSON()->data->nama);
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter "PhoneNumberTest|AuthGuardTest"`
Expected: FAIL — kelas/filter/route belum ada.

- [ ] **Step 3: Implementasi `PhoneNumber`**

Buang semua non-digit, buang `+`. `08...` → `628...`. `62...` tetap. `PhoneNumber::variants()` mengembalikan bentuk `62...` dan `08...` (unique, urutan itu).

- [ ] **Step 4: Implementasi `ApiContext` + service**

`app/Libraries/ApiContext.php` berisi `public ?array $pelanggan = null; public ?int $idToken = null;`. Tambahkan `public static function apiContext(bool $getShared = true)` di `app/Config/Services.php` dengan pola yang sama seperti `loginThrottle`.

- [ ] **Step 5: Implementasi `ApiAuthFilter`**

```php
public function before(RequestInterface $request, $arguments = null)
{
    $header = $request->getHeaderLine('Authorization');
    if (! preg_match('/^Bearer\s+([A-Fa-f0-9]{64})$/', $header, $m)) {
        return service('response')->setStatusCode(401)
            ->setJSON(['error' => ['code' => 'AUTH_REQUIRED', 'message' => 'Token tidak ditemukan.', 'fields' => []]]);
    }
    $row = (new \App\Models\MApiToken())->findValid($m[1]);
    if ($row === null) {
        return service('response')->setStatusCode(401)
            ->setJSON(['error' => ['code' => 'AUTH_INVALID_TOKEN', 'message' => 'Sesi berakhir, silakan masuk lagi.', 'fields' => []]]);
    }
    $pelanggan = (new \App\Models\MPelanggan())->find($row['id_pelanggan']);
    if ($pelanggan === null || (int) $pelanggan['is_aktif'] !== 1) {
        return service('response')->setStatusCode(403)
            ->setJSON(['error' => ['code' => 'ACCOUNT_INACTIVE', 'message' => 'Akun tidak aktif.', 'fields' => []]]);
    }
    $ctx = service('apiContext');
    $ctx->pelanggan = $pelanggan;
    $ctx->idToken = (int) $row['id_token'];
    (new \App\Models\MApiToken())->extend((int) $row['id_token']);
}
```

Daftarkan alias `'apiauth' => \App\Filters\ApiAuthFilter::class`.

- [ ] **Step 6: Implementasi `GET /me`**

Route di dalam group `['filter' => 'apiauth']`. Response:
```json
{"data":{"id_pelanggan":1,"kode_pelanggan":"PLG0001","nama":"Siti","no_telp":"62812...","alamat":"...","poin":0,"total_transaksi":0}}
```
Ambil dari `service('apiContext')->pelanggan`.

- [ ] **Step 7: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter "PhoneNumberTest|AuthGuardTest"`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add app/Libraries app/Filters/ApiAuthFilter.php app/Controllers/Api/V1/AuthController.php app/Config/Filters.php app/Config/Services.php app/Config/Routes.php tests/unit/Libraries/PhoneNumberTest.php tests/Feature/Api/AuthGuardTest.php
git commit -m "feat(api): guard bearer token dan endpoint profil"
```

---

### Task 4: Register, aktivasi, login, logout

**Files:**
- Modify: `app/Controllers/Api/V1/AuthController.php`
- Modify: `app/Config/Routes.php`
- Test: `tests/Feature/Api/AuthFlowTest.php`

**Interfaces:**
- Consumes: `PhoneNumber::variants()`, `MApiToken::issue()`, `service('loginThrottle')`, `MPelanggan::generateKode()`.
- Produces: route `POST auth/register`, `POST auth/activate`, `POST auth/login`, `POST auth/logout`.

- [ ] **Step 1: Tulis test yang gagal**

```php
public function testRegisterCreatesPelangganAndReturnsToken(): void
{
    $result = $this->withBodyFormat('json')->call('post', 'api/v1/auth/register', [
        'nama' => 'Budi', 'no_telp' => '081234567890', 'alamat' => 'Jl. Melati 5', 'pin' => '123456',
    ]);

    $result->assertStatus(201);
    $this->assertSame(64, strlen($result->getJSON()->data->token));
    $row = db_connect('tests')->table('tb_pelanggan')->where('no_telp', '6281234567890')->get()->getRowArray();
    $this->assertNotNull($row);
    $this->assertStringStartsWith('PLG', $row['kode_pelanggan']);
    $this->assertNotSame('123456', $row['pin_hash']);
}

public function testRegisterRejectsDuplicateInOtherPhoneFormat(): void
{
    $this->createPelanggan(['no_telp' => '6281234567890']);
    $result = $this->withBodyFormat('json')->call('post', 'api/v1/auth/register', [
        'nama' => 'Budi', 'no_telp' => '081234567890', 'alamat' => 'Jl. Melati 5', 'pin' => '123456',
    ]);
    $result->assertStatus(409);
    $this->assertStringContainsString('PHONE_TAKEN', $result->getJSON());
}

public function testLoginWorksWithDifferentPhoneFormat(): void
{
    $this->createPelanggan(['no_telp' => '6281234567890']);
    $result = $this->withBodyFormat('json')->call('post', 'api/v1/auth/login', [
        'no_telp' => '081234567890', 'pin' => '123456',
    ]);
    $result->assertStatus(200);
}

public function testSixthWrongPinIsThrottled(): void
{
    $this->createPelanggan(['no_telp' => '6281239999999']);
    for ($i = 0; $i < 5; $i++) {
        $this->withBodyFormat('json')->call('post', 'api/v1/auth/login', ['no_telp' => '081239999999', 'pin' => '000000']);
    }
    $result = $this->withBodyFormat('json')->call('post', 'api/v1/auth/login', ['no_telp' => '081239999999', 'pin' => '123456']);
    $result->assertStatus(429);
    $this->assertStringContainsString('AUTH_BLOCKED', $result->getJSON());
}

public function testActivateUsesLatestNotaBelongingToPhone(): void
{
    $pelanggan = $this->createPelanggan(['no_telp' => '6281200000111', 'pin_hash' => null]);
    $this->createTransaksi($pelanggan, ['no_nota' => 'LAU/20261020/0001']);

    $ok = $this->withBodyFormat('json')->call('post', 'api/v1/auth/activate', [
        'no_telp' => '081200000111', 'no_nota' => 'LAU/20261020/0001', 'pin' => '654321',
    ]);
    $ok->assertStatus(200);

    $other = $this->createPelanggan(['no_telp' => '6281200000222', 'pin_hash' => null]);
    $fail = $this->withBodyFormat('json')->call('post', 'api/v1/auth/activate', [
        'no_telp' => '081200000222', 'no_nota' => 'LAU/20261020/0001', 'pin' => '654321',
    ]);
    $fail->assertStatus(422);
    $this->assertStringContainsString('ACTIVATION_FAILED', $fail->getJSON());
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter AuthFlowTest`
Expected: FAIL — route belum ada.

- [ ] **Step 3: Implementasi validasi & register**

Aturan: `nama required|min_length[3]|max_length[100]`, `no_telp required`, `alamat required|min_length[5]`, `pin required|numeric|exact_length[6]`. Normalisasi nomor lalu cek regex `/^62\d{8,13}$/`. Cek duplikat dengan `whereIn('no_telp', PhoneNumber::variants($input))`. Simpan `pin_hash = password_hash($pin, PASSWORD_DEFAULT)`, `pin_set_at = date('Y-m-d H:i:s')`, `is_aktif = 1`, `kode_pelanggan = (new MPelanggan())->generateKode()`. Return `201` + token.

- [ ] **Step 4: Implementasi login + throttle**

Cari pelanggan via `whereIn('no_telp', variants)`. `pin_hash === null` → `409` `AUTH_NOT_ACTIVATED` dengan pesan `"Akun belum diaktifkan. Gunakan nomor nota terakhir."`. `is_aktif != 1` → `403` `ACCOUNT_INACTIVE`. Sebelum verifikasi, panggil `service('loginThrottle')->isBlocked($ip, $identifier)` dengan `$identifier = 'api_' . PhoneNumber::normalize($noTelp)`; kalau blocked → `429` `AUTH_BLOCKED` + `retry_after` di `fields`. PIN salah → `recordFailure()` + `401` `AUTH_INVALID_CREDENTIALS`. Sukses → `clear()`, update `last_login_at`, issue token.

- [ ] **Step 5: Implementasi aktivasi + logout**

Aktivasi: pelanggan harus `pin_hash === null`; cari transaksi terbaru `where('id_pelanggan', $id)->where('no_nota', $noNota)` (bukan path, jadi `/` aman). Tidak ketemu → `422` `ACTIVATION_FAILED`. Sukses → set `pin_hash`, issue token. Logout: `MApiToken::revoke()` dari header lalu `204`.

- [ ] **Step 6: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter AuthFlowTest`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/Controllers/Api/V1/AuthController.php app/Config/Routes.php tests/Feature/Api/AuthFlowTest.php
git commit -m "feat(api): register, aktivasi, login, logout pelanggan"
```

---

### Task 5: Layanan, info outlet, update profil

**Files:**
- Create: `app/Config/Outlet.php`
- Create: `app/Controllers/Api/V1/LayananController.php`
- Create: `app/Controllers/Api/V1/OutletController.php`
- Modify: `app/Controllers/Api/V1/AuthController.php` (method `updateMe()`)
- Modify: `app/Config/Routes.php`
- Modify: `.env.example`
- Test: `tests/Feature/Api/CatalogTest.php`

**Interfaces:**
- Consumes: `MLayanan`, `apiContext`, `Config\Outlet`.
- Produces: `GET layanan`, `GET outlet`, `PATCH me`.

- [ ] **Step 1: Tulis test yang gagal**

```php
public function testLayananOnlyReturnsActive(): void
{
    $db = db_connect('tests');
    $db->table('tb_layanan')->insertBatch([
        ['nama_layanan' => 'Cuci Kering', 'harga_per_kg' => 7000, 'estimasi_hari' => 2, 'is_aktif' => 1],
        ['nama_layanan' => 'Layanan Mati', 'harga_per_kg' => 5000, 'estimasi_hari' => 1, 'is_aktif' => 0],
    ]);
    $pelanggan = $this->createPelanggan();
    $token = $this->createTokenFor($pelanggan)['token'];

    $result = $this->withHeaders($this->authHeaders($token))->call('get', 'api/v1/layanan');
    $result->assertStatus(200);
    $names = array_column($result->getJSON()->data, 'nama_layanan');
    $this->assertSame(['Cuci Kering'], $names);
    $this->assertIsInt($result->getJSON()->data[0]->harga_per_kg);
}

public function testUpdateMeRejectsPhoneChange(): void
{
    $pelanggan = $this->createPelanggan();
    $token = $this->createTokenFor($pelanggan)['token'];

    $result = $this->withHeaders($this->authHeaders($token))
        ->withBodyFormat('json')
        ->call('patch', 'api/v1/me', ['nama' => 'Nama Baru', 'no_telp' => '081111111111']);
    $result->assertStatus(200);
    $row = db_connect('tests')->table('tb_pelanggan')->where('id_pelanggan', $pelanggan['id_pelanggan'])->get()->getRowArray();
    $this->assertSame('Nama Baru', $row['nama_pelanggan']);
    $this->assertNotSame('081111111111', $row['no_telp']);
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter CatalogTest`
Expected: FAIL.

- [ ] **Step 3: Implementasi**

`GET /layanan` → `where('is_aktif', 1)->orderBy('nama_layanan')`, map ke `{id_layanan, nama_layanan, harga_per_kg: int, estimasi_hari: int}`.
`Config\Outlet` berisi `public string $nama`, `$noWa`, `$alamat`, `$jamBuka = '08:00'`, `$jamTutup = '21:00'`, semuanya dari `env('outlet.*', default)`.
`GET /outlet` → `{nama, no_wa, alamat, jam_buka, jam_tutup}`.
`PATCH /me` hanya menerima `nama` dan `alamat`; field lain diabaikan.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter CatalogTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/Config/Outlet.php app/Controllers/Api/V1 app/Config/Routes.php .env.example tests/Feature/Api/CatalogTest.php
git commit -m "feat(api): endpoint layanan, outlet, dan update profil"
```

---

### Task 6: Daftar transaksi (pagination + isolasi)

**Files:**
- Create: `app/Models/MApiTransaksi.php`
- Create: `app/Libraries/StatusPresenter.php`
- Create: `app/Controllers/Api/V1/TransaksiController.php` (method `index()` di task ini)
- Modify: `app/Config/Routes.php`
- Test: `tests/Feature/Api/TransaksiListTest.php`

**Interfaces:**
- Consumes: `apiContext->pelanggan['id_pelanggan']`.
- Produces:
  - `MApiTransaksi::paginateForPelanggan(int $idPelanggan, string $scope, int $page, int $perPage): array`
    → `['items' => array<int, array>, 'total' => int]`
  - item keys: `id_transaksi, no_nota, tgl_masuk, tgl_selesai_estimasi, total_berat (float), grand_total (int), status (string), status_label (string)`

- [ ] **Step 1: Tulis test yang gagal**

```php
public function testListOnlyReturnsOwnTransactions(): void
{
    $siti = $this->createPelanggan(['no_telp' => '6281200000001']);
    $budi = $this->createPelanggan(['no_telp' => '6281200000002']);
    $this->createTransaksi($siti, ['no_nota' => 'LAU/20261021/0001']);
    $this->createTransaksi($budi, ['no_nota' => 'LAU/20261021/0002']);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($siti)['token']))
        ->call('get', 'api/v1/transaksi');

    $result->assertStatus(200);
    $this->assertSame(1, $result->getJSON()->meta->total);
    $this->assertSame('LAU/20261021/0001', $result->getJSON()->data[0]->no_nota);
}

public function testMoneyIsIntegerAndRounded(): void
{
    $p = $this->createPelanggan();
    $this->createTransaksi($p, ['grand_total' => '42500.50']);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($p)['token']))
        ->call('get', 'api/v1/transaksi');

    $this->assertSame(42501, $result->getJSON()->data[0]->grand_total);
}

public function testEmptyListStillHasMeta(): void
{
    $p = $this->createPelanggan();
    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($p)['token']))
        ->call('get', 'api/v1/transaksi');

    $result->assertStatus(200);
    $this->assertSame(0, $result->getJSON()->meta->total);
    $this->assertSame(1, $result->getJSON()->meta->last_page);
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter TransaksiListTest`
Expected: FAIL.

- [ ] **Step 3: Implementasi query**

```sql
SELECT t.id_transaksi, t.no_nota, t.tgl_masuk, t.tgl_selesai_estimasi,
       t.total_berat, t.grand_total,
       COALESCE(st.nama_status, t.status) AS status
FROM tb_transaksi t
LEFT JOIN tb_master_status_transaksi st ON st.id = t.id_status_transaksi
WHERE t.id_pelanggan = ? AND t.deleted_at IS NULL
ORDER BY t.tgl_masuk DESC, t.id_transaksi DESC
```

Scope: `aktif` → `IN ('menunggu','proses','setrika')`; `selesai` → `IN ('selesai','diambil')`; selain itu semua. `total` dari `countAllResults()` pada builder yang sama tanpa limit.

- [ ] **Step 4: Implementasi controller**

Validasi `status` (default `semua`) dan `per_page` (default 20, maksimal 50). `grand_total` dan `total_berat` di-cast (`int` / `float`). `status_label` memakai `StatusPresenter` (dibuat di Task 7; sementara map inline dilarang — buat `StatusPresenter` sekarang agar tidak dobel, lalu Task 7 hanya menambah `timeline()`).

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter TransaksiListTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/Models/MApiTransaksi.php app/Libraries/StatusPresenter.php app/Controllers/Api/V1/TransaksiController.php app/Config/Routes.php tests/Feature/Api/TransaksiListTest.php
git commit -m "feat(api): daftar transaksi pelanggan dengan pagination"
```

---

### Task 7: Detail transaksi + nota + timeline

**Files:**
- Modify: `app/Models/MApiTransaksi.php` (`findForPelanggan`, `items`, `pembayaran`, `statusLog`)
- Modify: `app/Libraries/StatusPresenter.php` (`timeline()`)
- Modify: `app/Controllers/Api/V1/TransaksiController.php` (`show()`, `nota()`)
- Modify: `app/Config/Routes.php`
- Test: `tests/Feature/Api/TransaksiDetailTest.php`

**Interfaces:**
- Consumes: `paginateForPelanggan` dari Task 6.
- Produces:
  - `MApiTransaksi::findForPelanggan(int $id, int $idPelanggan): ?array`
  - `MApiTransaksi::items(int $idTransaksi): array` → keys `id_detail, id_layanan, nama_layanan, berat (float), harga_satuan (int), subtotal (int)`
  - `MApiTransaksi::pembayaran(int $idTransaksi): array` → `id_pembayaran, tgl_bayar, nominal_bayar (int), metode, status`
  - `MApiTransaksi::statusLog(int $idTransaksi): array` → `status, label, at`
  - `StatusPresenter::timeline(?string $current, array $statusLog): array` → item `{status, label, at, state}` dengan `state` = `done|current|pending`

- [ ] **Step 1: Tulis test yang gagal**

```php
public function testOtherCustomersTransactionReturns404(): void
{
    $siti = $this->createPelanggan(['no_telp' => '6281200000001']);
    $budi = $this->createPelanggan(['no_telp' => '6281200000002']);
    $trx = $this->createTransaksi($budi);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($siti)['token']))
        ->call('get', 'api/v1/transaksi/' . $trx['id_transaksi']);

    $result->assertStatus(404);
    $this->assertStringContainsString('NOT_FOUND', $result->getJSON());
}

public function testDetailIncludesTimelineAndPin(): void
{
    $p = $this->createPelanggan();
    $trx = $this->createTransaksi($p, ['pin_pengambilan' => '4821']);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($p)['token']))
        ->call('get', 'api/v1/transaksi/' . $trx['id_transaksi']);

    $result->assertStatus(200);
    $this->assertSame('4821', $result->getJSON()->data->pin_pengambilan);
    $this->assertCount(5, $result->getJSON()->data->timeline);
    $this->assertSame('Diterima', $result->getJSON()->data->timeline[0]->label);
}

public function testNotaDoesNotExposePickupPin(): void
{
    $p = $this->createPelanggan();
    $trx = $this->createTransaksi($p, ['pin_pengambilan' => '4821']);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($p)['token']))
        ->call('get', 'api/v1/transaksi/' . $trx['id_transaksi'] . '/nota');

    $result->assertStatus(200);
    $this->assertObjectNotHasProperty('pin_pengambilan', $result->getJSON()->data);
}

public function testLegacyTransactionWithoutMasterStatusStillHasLabel(): void
{
    $p = $this->createPelanggan();
    $trx = $this->createTransaksi($p, ['id_status_transaksi' => null, 'status' => 'proses']);

    $result = $this->withHeaders($this->authHeaders($this->createTokenFor($p)['token']))
        ->call('get', 'api/v1/transaksi/' . $trx['id_transaksi']);

    $result->assertStatus(200);
    $this->assertSame('Dicuci', $result->getJSON()->data->status_label);
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter TransaksiDetailTest`
Expected: FAIL.

- [ ] **Step 3: Implementasi `StatusPresenter::timeline()`**

Urutan tetap `menunggu, proses, setrika, selesai, diambil` dengan label `Diterima, Dicuci, Disetrika, Siap Diambil, Selesai`. `at` diambil dari `status_log` bila ada, `null` bila belum. Item sebelum status sekarang `done`, yang sama `current`, sesudahnya `pending`. Status tak dikenal → semua `pending` kecuali item pertama `current`.

- [ ] **Step 4: Implementasi `show()` dan `nota()`**

`show()`: `findForPelanggan((int) $id, $ctx->pelanggan['id_pelanggan'])`; `null` → `404 NOT_FOUND`. Response berisi field list Task 6 + `items`, `pembayaran`, `timeline`, `pin_pengambilan`, `catatan`.
`nota()`: field nota saja (outlet, no_nota, tanggal, items, subtotal, diskon, grand_total, metode, status_pembayaran) **tanpa** `pin_pengambilan`.

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter TransaksiDetailTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/Models/MApiTransaksi.php app/Libraries/StatusPresenter.php app/Controllers/Api/V1/TransaksiController.php app/Config/Routes.php tests/Feature/Api/TransaksiDetailTest.php
git commit -m "feat(api): detail transaksi, timeline, dan nota digital"
```

---

### Task 8: Reset PIN oleh kasir + dokumentasi API

**Files:**
- Modify: `app/Config/Routes.php` (route web `POST pelanggan/reset-pin/(:num)`)
- Modify: `app/Controllers/Pelanggan.php` (`resetPin()`)
- Modify: `app/Views/pelanggan/index.php` (tombol Reset PIN di kolom Aksi)
- Create: `docs/api/sparkleen-mobile-v1.md`
- Create: `docs/api/sparkleen-mobile-v1.postman_collection.json`
- Test: `tests/Feature/Api/ResetPinTest.php`

**Interfaces:**
- Consumes: `MLogAktivitas`, session `id_karyawan`/`level`.
- Produces: `POST /pelanggan/reset-pin/{id}` → set `pin_hash = NULL`, `pin_set_at = NULL`, catat log `modul = 'pelanggan'`, `aksi = 'Reset PIN mobile'`.
- Test helper baru di `ApiTestTrait`: `loginAs(string $level): void` — set session `isLoggedIn`, `level`, dan `id_karyawan` (ambil baris pertama `tb_karyawan` dengan level tersebut, buat bila belum ada).

- [ ] **Step 1: Tulis test yang gagal**

```php
public function testKasirCanResetPinAndItIsLogged(): void
{
    $pelanggan = $this->createPelanggan();
    $this->loginAs('kasir');

    $result = $this->call('post', 'pelanggan/reset-pin/' . $pelanggan['id_pelanggan']);

    $result->assertRedirect();
    $row = db_connect('tests')->table('tb_pelanggan')->where('id_pelanggan', $pelanggan['id_pelanggan'])->get()->getRowArray();
    $this->assertNull($row['pin_hash']);
    $this->assertSame(1, db_connect('tests')->table('tb_log_aktivitas')->where('aksi', 'Reset PIN mobile')->countAllResults());
}

public function testPemilikCannotResetPin(): void
{
    $pelanggan = $this->createPelanggan(['pin_hash' => password_hash('123456', PASSWORD_DEFAULT)]);
    $this->loginAs('pemilik');

    $result = $this->call('post', 'pelanggan/reset-pin/' . $pelanggan['id_pelanggan']);

    $result->assertRedirect();
    $row = db_connect('tests')->table('tb_pelanggan')->where('id_pelanggan', $pelanggan['id_pelanggan'])->get()->getRowArray();
    $this->assertNotNull($row['pin_hash']);
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `php vendor/bin/phpunit --filter ResetPinTest`
Expected: FAIL.

- [ ] **Step 3: Implementasi route + controller + tombol**

Route di group `['filter' => 'role:admin,kasir']`. `resetPin()` memvalidasi pelanggan ada, update dua kolom jadi `null`, insert log via `MLogAktivitas` (field mengikuti `$allowedFields`), redirect balik dengan flash `success`. Tombol di `index.php` memakai `form` POST + `data-confirm` seperti tombol toggle yang sudah ada.

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `php vendor/bin/phpunit --filter ResetPinTest`
Expected: PASS

- [ ] **Step 5: Tulis dokumentasi**

`docs/api/sparkleen-mobile-v1.md`: base URL, auth header, daftar 10 endpoint fase 1, contoh request/response, tabel kode error, dan catatan rate limit. Postman collection berisi semua request dengan variabel `base_url` dan `token`.

- [ ] **Step 6: Jalankan seluruh suite**

Run: `php vendor/bin/phpunit`
Expected: PASS semua (unit + feature + database).

- [ ] **Step 7: Commit**

```bash
git add app/Controllers/Pelanggan.php app/Views/pelanggan/index.php app/Config/Routes.php docs/api tests/Feature/Api/ResetPinTest.php
git commit -m "feat(api): reset pin oleh kasir dan dokumentasi endpoint mobile"
```

---

## Setelah plan ini selesai

Fase 1 backend selesai dan teruji. Langkah berikutnya (plan terpisah):

1. Plan Flutter fase 1 di `C:\Users\R\Documents\@Semester 5\sparkleen_mobile_pelanggan`.
2. Deploy backend ke Railway + smoke test dari device.
3. Plan fase 2 (permintaan jemput + halaman kasir).
