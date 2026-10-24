# Backend: Permintaan Jemput + Pembayaran Online — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menambah API `/api/v1` untuk permintaan jemput dan intent pembayaran QRIS/transfer
yang diinisiasi pelanggan, plus layar "Pesanan Masuk" di web kasir yang mengubah permintaan
menjadi transaksi lewat jalur kasir yang sudah ada.

**Architecture:** Semua pekerjaan terjadi di repo backend CodeIgniter 4
`sparkleen-laundry`. Permintaan hidup di tabel baru `tb_permintaan_pesanan`; `tb_transaksi`
tidak berubah struktur. Panggilan ke Node `payment_api` dikonsolidasikan dalam satu
`PaymentApiService` yang transport-nya bisa distub, dipakai oleh jalur kasir lama maupun
endpoint app baru. Status lunas tetap hanya ditulis `Webhook::payment()`.

**Tech Stack:** PHP 8.2, CodeIgniter 4.7, MySQL 8, PHPUnit 10.5.

**Spec:** `docs/superpowers/specs/2026-10-24-alur-pesan-dan-bayar-online-design.md`
(bab 5, 6, 7, 8, 9.2, 11 adalah bagian yang plan ini realisasikan).

**Lokasi repo backend:**
`C:\Users\R\Documents\@Tugas kampus semester 4\Pemrograman Web\Sparkleen Laundry\sparkleen-laundry`

## Global Constraints

- Repo backend **kotor dan dipakai bersama**: jangan pernah `git add -A` / `git add .`.
  Stage file yang task ini sentuh, satu per satu, dengan path lengkap.
- Tidak ada satu pun perubahan struktur pada `tb_transaksi`. Kolom `payment_ref`
  (`VARCHAR(100) NULL`) dan `payment_detail` (`TEXT NULL`) sudah ada sejak migrasi
  `2026-06-20-091304_AddPaymentApiColumnsToTransaksi`.
- Migrasi bersifat additive saja.
- Test hanya boleh menyentuh DB `laundry_db_test` (`protected $DBGroup = 'tests'`).
  Tidak ada test yang memanggil Node `payment_api` sungguhan.
- Jangan pernah menulis token, PIN, hash, atau isi `payment_detail` penuh ke log.
- Response API memakai envelope yang sudah ada: sukses `{data, meta?}`, gagal
  `{error: {code, message, fields}}`. Uang dibulatkan ke `int` rupiah, tanggal keluar sebagai
  ISO-8601 ber-zona lewat `MApiTransaksi::iso()`.
- Sumber kebenaran lunas tetap `Webhook::payment()` (HMAC-SHA256 atas raw body,
  `hash_equals()`). Tidak boleh ada endpoint yang menandai transaksi lunas langsung.
- `PAYMENT_API_KEY` hanya dibaca di server. Tidak pernah dikirim ke klien.
- Semua form kasir baru wajib menyertakan `<?= csrf_field() ?>` karena filter `csrf` aktif
  sebagai global `before` (kecuali `api/v1/*`, `webhook/payment`, sebagian `pelanggan-bayar/*`).
- Perintah test dijalankan dari direktori repo backend, memakai PHP yang ada di PATH:
  `php vendor/bin/phpunit --filter <NamaTest>`. Sudah terverifikasi jalan di mesin ini
  (PHPUnit 10.5.63, PHP 8.2.12).

## Peta File

Dibuat:

| File | Tanggung jawab |
|---|---|
| `app/Database/Migrations/2026-10-24-000001_CreatePermintaanPesananTable.php` | Skema `tb_permintaan_pesanan` |
| `app/Models/MPermintaanPesanan.php` | Write + query + klaim atomik permintaan |
| `app/Services/PaymentTransport.php` | Interface transport HTTP ke Node API |
| `app/Services/CurlPaymentTransport.php` | Implementasi nyata (CI4 CURLRequest) |
| `app/Services/PaymentApiService.php` | Kamus metode, buat/batalkan intent, validasi respons |
| `app/Services/PaymentApiException.php` | Satu tipe kegagalan untuk semua jalur payment |
| `app/Controllers/Api/V1/PermintaanController.php` | CRUD permintaan untuk app |
| `app/Controllers/Api/V1/PembayaranController.php` | Create/read/cancel intent bayar |
| `app/Controllers/Permintaan.php` | Layar kasir: daftar, konfirmasi, tolak |
| `app/Views/permintaan/daftar.php` | Tabel Pesanan Masuk + tab status |
| `app/Views/permintaan/konfirmasi.php` | Form berat actual → transaksi |
| `tests/_support/Api/ApiTestTrait.php` (ubah) | Helper `createLayanan`, `createPermintaan` |
| `tests/_support/Services/FakePaymentTransport.php` | Stub Node API untuk test |
| `tests/database/PermintaanPesananModelTest.php` | Skema + klaim atomik |
| `tests/unit/Services/PaymentApiServiceTest.php` | Mapping metode, parsing, error |
| `tests/Feature/TransaksiPembayaranApiTest.php` | Perilaku kasir lama tidak berubah |
| `tests/Feature/Api/PermintaanFlowTest.php` | Endpoint permintaan end-to-end |
| `tests/Feature/Api/PembayaranFlowTest.php` | Endpoint pembayaran end-to-end |
| `tests/Feature/PermintaanKonfirmasiTest.php` | Konfirmasi kasir → transaksi |

Diubah:

| File | Perubahan |
|---|---|
| `app/Config/Services.php` | daftarkan `paymentApi()` |
| `app/Services/TransaksiService.php:237-335` | pakai `PaymentApiService`, hapak duplikasi |
| `app/Controllers/Api/V1/BaseApiController.php` | `findOwnTransaction()` dipindah ke sini |
| `app/Controllers/Api/V1/TransaksiController.php` | buang helper privat, tambah `sisa_tagihan` |
| `app/Config/Routes.php` | rute `api/v1/permintaan`, `api/v1/transaksi/(:num)/pembayaran`, `permintaan` kasir |
| `app/Views/backend/template/sidebar.php` | menu "Pesanan Masuk" + badge |
| `docs/api/sparkleen-mobile-v1.md` | dokumentasi endpoint baru (juga disalin ke repo app) |

---

## Baseline sebelum Task 1

Jalankan sekali di awal, catat angkanya, dan pakai angka itu sebagai pembanding di semua task:

```bash
php vendor/bin/phpunit 2>&1 | tail -6
```

Sudah terverifikasi di mesin ini (2026-10-24): `--filter TransaksiFeatureTest` menghasilkan
`Tests: 10, Assertions: 23, Failures: 7`, contoh gagalnya `Key 'kembalian' is not in the current
$_SESSION` di `tests/Feature/TransaksiFeatureTest.php:283`. Repo backend sedang dipakai pekerjaan
lain, jadi suite lama memang tidak hijau. **Semua step "Expected: OK" di plan ini berlaku untuk
test yang task itu tulis sendiri**; untuk suite lama aturannya adalah *jumlah failure tidak
bertambah*, bukan *nol*. Kalau angka baseline berbeda saat lu mulai, pakai angka yang lu catat.

Baseline suite penuh yang dicatat tepat sebelum Task 1 (tree = branch `feature/mobile-api` dengan
13 file WIP milik pekerjaan lain masih belum di-commit):

```
Tests: 118, Assertions: 288, Failures: 17.
```

Rinciannya: `Tests\Unit\Models\TransaksiModelTest` 1, `Tests\Feature\AuthFeatureTest` 5,
`Tests\Feature\RateLimitTest` 4, `Tests\Feature\TransaksiFeatureTest` 7. Yang penting:
**nol error dan nol failure di `tests/Feature/Api/`** — semua test kontrak API mobile yang
sudah ada masih hijau, jadi gate task-task di plan ini (`--filter` ke test API) tidak terganggu
kekacauan suite lama. Contoh kegagalannya juga murni web (`Redirect URL '…/login' does not match
'…/'`), akibat WIP di `app/Controllers/Auth.php`, bukan akibat kode API.

## Task 1: Tabel `tb_permintaan_pesanan` + model

**Files:**
- Create: `app/Database/Migrations/2026-10-24-000001_CreatePermintaanPesananTable.php`
- Create: `app/Models/MPermintaanPesanan.php`
- Modify: `tests/_support/Api/ApiTestTrait.php` (helper `createPermintaan` + `createLayanan`, Step 5)
- Test: `tests/database/PermintaanPesananModelTest.php`

**Interfaces:**
- Consumes: tabel `tb_pelanggan`, `tb_layanan`, `tb_transaksi`, `tb_karyawan`.
- Produces (dipakai Task 4, 5, 7 — nama ini final): konstanta `MPermintaanPesanan::MENUNGGU`,
  `DIPROSES`, `DIKONFIRMASI`, `DITOLAK`, `DIBATALKAN` dan `SLOT_START`
  (`['pagi'=>'08:00:00','siang'=>'12:00:00','sore'=>'15:00:00']`), lalu
  `countMenunggu(int $idPelanggan): int`,
  `findForPelanggan(int $idPermintaan, int $idPelanggan): ?array`,
  `findForPelangganByStatus(int $idPelanggan, string $status): ?array`,
  `paginateForPelanggan(int $idPelanggan, string $scope, int $page, int $perPage): array{items,total}`,
  `claimUntukDiproses(int $idPermintaan, int $idPelanggan): bool`,
  `finalize(int $idPermintaan, string $status, ?int $idTransaksi, int $idKasir, ?string $alasan = null): bool`,
  `assignKasir(int $idPermintaan, int $idKasir): bool`.
  Baris hasil query sudah berisi `nama_layanan` dan `harga_per_kg` dari join `tb_layanan`.

- [ ] **Step 1: Tulis migration gagal lebih dulu (test yang belum bisa jalan)**

Buat `tests/database/PermintaanPesananModelTest.php`:

```php
<?php

namespace Tests\Database;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use App\Models\MPermintaanPesanan;
use Tests\Support\Api\ApiTestTrait;

/**
 * @internal
 */
final class PermintaanPesananModelTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    use ApiTestTrait;

    protected $migrate     = true;
    protected $migrateOnce = true;
    protected $DBGroup     = 'tests';
    protected $namespace   = null;

    public function testKlaimAtomikHanyaMenangSekali(): void
    {
        $p = $this->createPelanggan();
        $this->createPermintaan($p);

        $model = new MPermintaanPesanan();
        $first = $model->findForPelangganByStatus((int) $p['id_pelanggan'], 'menunggu');

        $this->assertTrue($model->claimUntukDiproses((int) $first['id_permintaan'], (int) $p['id_pelanggan']));
        $this->assertFalse($model->claimUntukDiproses((int) $first['id_permintaan'], (int) $p['id_pelanggan']));
    }
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PermintaanPesananModelTest`
Expected: FAIL — tabel `tb_permintaan_pesanan` tidak ditemukan / kelas `MPermintaanPesanan` belum ada.

- [ ] **Step 3: Tulis migration**

Buat `app/Database/Migrations/2026-10-24-000001_CreatePermintaanPesananTable.php`.
Gaya mengikuti `2026-10-23-000002_CreateApiTokenTable.php`:

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreatePermintaanPesananTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id_permintaan' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'id_pelanggan' => [
                'type' => 'INT', 'constraint' => 11, 'unsigned' => true,
            ],
            'id_layanan' => [
                'type' => 'INT', 'constraint' => 11, 'unsigned' => true,
            ],
            'berat_perkiraan' => [
                'type' => 'DECIMAL', 'constraint' => '6,2',
            ],
            'catatan' => [
                'type' => 'VARCHAR', 'constraint' => 255, 'null' => true,
            ],
            'alamat_jemput' => [
                'type' => 'VARCHAR', 'constraint' => 255,
            ],
            'tgl_jemput' => [
                'type' => 'DATETIME',
            ],
            'slot_jemput' => [
                'type' => 'VARCHAR', 'constraint' => 10,
            ],
            'status' => [
                'type' => 'VARCHAR', 'constraint' => 20, 'default' => 'menunggu',
            ],
            'id_transaksi' => [
                'type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'null' => true,
            ],
            'alasan_penolakan' => [
                'type' => 'VARCHAR', 'constraint' => 255, 'null' => true,
            ],
            'dikonfirmasi_oleh' => [
                'type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'null' => true,
            ],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);

        $this->forge->addKey('id_permintaan', true);
        $this->forge->addKey(['id_pelanggan', 'status']);
        $this->forge->addForeignKey('id_pelanggan', 'tb_pelanggan', 'id_pelanggan', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('id_layanan', 'tb_layanan', 'id_layanan', 'RESTRICT', 'CASCADE');
        $this->forge->addForeignKey('id_transaksi', 'tb_transaksi', 'id_transaksi', 'SET NULL', 'CASCADE');
        $this->forge->addForeignKey('dikonfirmasi_oleh', 'tb_karyawan', 'id_karyawan', 'SET NULL', 'CASCADE');
        $this->forge->createTable('tb_permintaan_pesanan');
    }

    public function down()
    {
        $this->forge->dropTable('tb_permintaan_pesanan');
    }
}
```

- [ ] **Step 4: Tulis model**

Buat `app/Models/MPermintaanPesanan.php`:

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class MPermintaanPesanan extends Model
{
    public const MENUNGGU     = 'menunggu';
    public const DIPROSES     = 'diproses';
    public const DIKONFIRMASI = 'dikonfirmasi';
    public const DITOLAK      = 'ditolak';
    public const DIBATALKAN   = 'dibatalkan';

    /** Jam mulai tiap slot; tgl_jemput disimpan sebagai tanggal + jam ini. */
    public const SLOT_START = ['pagi' => '08:00:00', 'siang' => '12:00:00', 'sore' => '15:00:00'];

    protected $table            = 'tb_permintaan_pesanan';
    protected $primaryKey       = 'id_permintaan';
    protected $returnType       = 'array';
    protected $useTimestamps    = true;
    protected $createdField     = 'created_at';
    protected $updatedField     = 'updated_at';
    protected $allowedFields    = [
        'id_pelanggan', 'id_layanan', 'berat_perkiraan', 'catatan', 'alamat_jemput',
        'tgl_jemput', 'slot_jemput', 'status', 'id_transaksi', 'alasan_penolakan',
        'dikonfirmasi_oleh',
    ];

    public function countMenunggu(int $idPelanggan): int
    {
        return $this->where('id_pelanggan', $idPelanggan)
            ->where('status', self::MENUNGGU)
            ->countResults();
    }

    /**
     * @return array<string, mixed>|null
     */
    public function findForPelanggan(int $idPermintaan, int $idPelanggan): ?array
    {
        $row = $this->baseSelect()
            ->where('p.id_permintaan', $idPermintaan)
            ->where('p.id_pelanggan', $idPelanggan)
            ->get()
            ->getRowArray();

        return $row ?: null;
    }

    /**
     * @return array<string, mixed>|null
     */
    public function findForPelangganByStatus(int $idPelanggan, string $status): ?array
    {
        $row = $this->baseSelect()
            ->where('p.id_pelanggan', $idPelanggan)
            ->where('p.status', $status)
            ->orderBy('p.id_permintaan', 'DESC')
            ->get()
            ->getRowArray();

        return $row ?: null;
    }

    /**
     * @return array{items: list<array<string, mixed>>, total: int}
     */
    public function paginateForPelanggan(int $idPelanggan, string $scope, int $page, int $perPage): array
    {
        $filter = static function ($builder) use ($idPelanggan, $scope) {
            $builder->where('p.id_pelanggan', $idPelanggan);

            if ($scope === 'aktif') {
                // `diproses` harus ikut: itu permintaan yang sedang dipegang kasir. Kalau tidak,
                // kartu di app hilang tepat saat pesanan mulai dikerjakan.
                $builder->whereIn('p.status', [self::MENUNGGU, self::DIPROSES, self::DIKONFIRMASI]);
            } elseif ($scope === 'selesai') {
                $builder->whereIn('p.status', [self::DITOLAK, self::DIBATALKAN]);
            } elseif ($scope !== 'semua') {
                throw new \InvalidArgumentException('Scope permintaan tidak dikenal: ' . $scope);
            }
        };

        $count = $this->db->table('tb_permintaan_pesanan p');
        $filter($count);
        $total = $count->countAllResults();

        $rows = $this->baseSelect();
        $filter($rows);
        $rows = $rows->orderBy('p.id_permintaan', 'DESC')
            ->limit($perPage, ($page - 1) * $perPage)
            ->get()
            ->getResultArray();

        return ['items' => $rows, 'total' => $total];
    }

    /**
     * Klaim atomik: hanya permintaan berstatus `menunggu` milik pelanggan itu yang bisa
     * dibuka. Menang = boleh lanjut membuat transaksi.
     *
     * `affectedRows()` dipanggil dari `$this->db` (BaseConnection), bukan dari model —
     * CI4 Model tidak punya method affectedRows().
     */
    public function claimUntukDiproses(int $idPermintaan, int $idPelanggan): bool
    {
        $updated = $this->where('id_permintaan', $idPermintaan)
            ->where('id_pelanggan', $idPelanggan)
            ->where('status', self::MENUNGGU)
            ->update(['status' => self::DIPROSES]);

        return $updated && $this->db->affectedRows() === 1;
    }

    /**
     * Kasir selesai memproses: simpan hasil + id transaksi. Hanya boleh dari `diproses`
     * yang dikonfirmasi_oleh-nya sudah diisi kasir yang sama lewat assignKasir().
     */
    public function finalize(int $idPermintaan, string $status, ?int $idTransaksi, int $idKasir, ?string $alasan = null): bool
    {
        $updated = $this->where('id_permintaan', $idPermintaan)
            ->where('status', self::DIPROSES)
            ->where('dikonfirmasi_oleh', $idKasir)
            ->update([
                'status'            => $status,
                'id_transaksi'      => $idTransaksi,
                'alasan_penolakan'  => $alasan,
            ]);

        return $updated && $this->db->affectedRows() === 1;
    }

    /**
     * Menandai siapa kasir yang sedang menggarap, dipakai finalize sebagai guard.
     */
    public function assignKasir(int $idPermintaan, int $idKasir): bool
    {
        return $this->update($idPermintaan, ['dikonfirmasi_oleh' => $idKasir]);
    }

    private function baseSelect()
    {
        return $this->db->table('tb_permintaan_pesanan p')
            ->select('p.*, l.nama_layanan, l.harga_per_kg, l.estimasi_hari')
            ->join('tb_layanan l', 'l.id_layanan = p.id_layanan', 'left')
            ->orderBy('p.id_permintaan', 'DESC');
    }
}
```

Catatan implementasi: tiga langkah ini harus berurutan dan masing-masing dikunci oleh `WHERE`-nya
sendiri, bukan oleh lock eksplisit — UPDATE dengan predikat dijalankan atomik oleh MySQL, jadi
hanya satu caller yang bisa cocok dengan `status = 'menunggu'`:
`claimUntukDiproses()` (hanya menang kalau status masih `menunggu`) → `assignKasir()` (menulis
`dikonfirmasi_oleh`) → buat transaksi → `finalize()` (hanya jalan kalau status masih `diproses`
**dan** `dikonfirmasi_oleh` = kasir yang sama). Guard kasir di `finalize()` membuat kasir A tidak
mungkin menutup baris yang sedang dipegang kasir B. Status `diproses` adalah detail implementasi
dan **tidak** diekspos ke app — `PermintaanController` memetakannya kembali ke `menunggu` saat
presentasi (Task 4). Di layar kasir, `diproses` tampil di tab "menunggu" supaya baris yang
gantung tetap terlihat.

- [ ] **Step 5: Tambah helper `createPermintaan` di ApiTestTrait**

Ubah `tests/_support/Api/ApiTestTrait.php`: tambahkan method ini di dalam trait, setelah
`createTransaksi()`, dan counter `protected static int $apiPermintaanCounter = 0;` di
deklarasi counter paling atas:

```php
    /**
     * @param array<string, mixed> $pelanggan
     * @param array<string, mixed> $override
     *
     * @return array<string, mixed>
     */
    protected function createPermintaan(array $pelanggan, array $override = []): array
    {
        $db = db_connect('tests');
        $layanan = $override['id_layanan'] ?? $this->createLayanan('Kiloan', 7000)['id_layanan'];

        $defaults = [
            'id_pelanggan'    => $pelanggan['id_pelanggan'],
            'id_layanan'      => $layanan,
            'berat_perkiraan' => 3.00,
            'alamat_jemput'   => 'Jl. Uji No. 1',
            'tgl_jemput'      => date('Y-m-d 08:00:00', strtotime('+1 day')),
            'slot_jemput'     => 'pagi',
            'status'          => 'menunggu',
            'created_at'      => date('Y-m-d H:i:s'),
            'updated_at'      => date('Y-m-d H:i:s'),
        ];

        $data = array_merge($defaults, $override);
        $db->table('tb_permintaan_pesanan')->insert($data);

        $id = (int) $db->insertID();
        $data['id_permintaan'] = $id;

        return $data;
    }

    /**
     * @return array<string, mixed>
     */
    protected function createLayanan(string $nama = 'Kiloan', int $harga = 7000): array
    {
        $db = db_connect('tests');
        $db->table('tb_layanan')->insert([
            'nama_layanan'  => $nama,
            'harga_per_kg'  => $harga,
            'estimasi_hari' => 2,
            'is_aktif'      => 1,
            'created_at'    => date('Y-m-d H:i:s'),
            'updated_at'    => date('Y-m-d H:i:s'),
        ]);

        return [
            'id_layanan'    => (int) $db->insertID(),
            'nama_layanan'  => $nama,
            'harga_per_kg'  => $harga,
        ];
    }
```

- [ ] **Step 6: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PermintaanPesananModelTest`
Expected: OK (1 test).

- [ ] **Step 7: Stage + commit**

```bash
git add "app/Database/Migrations/2026-10-24-000001_CreatePermintaanPesananTable.php" \
        "app/Models/MPermintaanPesanan.php" \
        "tests/database/PermintaanPesananModelTest.php" \
        "tests/_support/Api/ApiTestTrait.php"
git commit -m "feat(api): tabel dan model permintaan jemput pelanggan"
```

---

## Task 2: `PaymentApiService` (belum dipasang ke siapa pun)

**Files:**
- Create: `app/Services/PaymentTransport.php`, `app/Services/CurlPaymentTransport.php`,
  `app/Services/PaymentApiService.php`, `app/Services/PaymentApiException.php`
- Create: `tests/_support/Services/FakePaymentTransport.php`
- Create: `tests/unit/Services/PaymentApiServiceTest.php`
- Modify: `app/Config/Services.php`

**Interfaces:**
- Consumes: env `PAYMENT_API_URL`, `PAYMENT_API_KEY`; kontrak Node
  `POST {PAYMENT_API_URL}` dengan header `X-Api-Key` dan body
  `{amount, method, customer_ref}`; balasan
  `{success: true, data: {transaction_id, amount, method, payment_detail, expired_at, status}}`.
- Produces: `service('paymentApi')` dengan
  `buatIntent(string $noNota, float $nominal, string $metode): array` mengembalikan
  `array{transaction_id: string, nominal: float, metode: string, payment_detail: array, expired_at: ?string}`,
  `batalkanIntent(string $transactionId): void`,
  `PaymentApiService::QRIS`, `PaymentApiService::TRANSFER`,
  `PaymentApiService::idMetode(string $metode): int`, dan `PaymentApiException`.

- [ ] **Step 1: Tulis test gagal**

Buat `tests/unit/Services/PaymentApiServiceTest.php`:

```php
<?php

namespace Tests\Unit\Services;

use App\Services\PaymentApiException;
use App\Services\PaymentApiService;
use CodeIgniter\Test\CIUnitTestCase;
use Tests\Support\Services\FakePaymentTransport;

/**
 * @internal
 */
final class PaymentApiServiceTest extends CIUnitTestCase
{
    public function testQrisDikirimDenganNamaMethodNode(): void
    {
        $transport = new FakePaymentTransport();
        $service   = new PaymentApiService($transport);

        $intent = $service->buatIntent('LAU/20261024/0001', 21000.0, PaymentApiService::QRIS);

        $this->assertSame('QRIS', $transport->lastPayload['method']);
        $this->assertSame('LAU/20261024/0001', $transport->lastPayload['customer_ref']);
        $this->assertSame(21000.0, $transport->lastPayload['amount']);
        $this->assertSame('PAY-1', $intent['transaction_id']);
        $this->assertSame(PaymentApiService::QRIS, $intent['metode']);
        $this->assertSame('QRIS-FAKE', $intent['payment_detail']['qris_data']);
        $this->assertArrayHasKey('expired_at', $intent['payment_detail']);
    }

    public function testTransferDiterjemahkanKeBankTransfer(): void
    {
        $transport = new FakePaymentTransport();
        $service   = new PaymentApiService($transport);

        $service->buatIntent('LAU/20261024/0002', 15000.0, PaymentApiService::TRANSFER);

        $this->assertSame('BANK_TRANSFER', $transport->lastPayload['method']);
        $this->assertSame(3, PaymentApiService::idMetode(PaymentApiService::TRANSFER));
        $this->assertSame(2, PaymentApiService::idMetode(PaymentApiService::QRIS));
    }

    public function testMetodeTakDikenalDitolakSebelumBertanyaKeNode(): void
    {
        $transport = new FakePaymentTransport();
        $service   = new PaymentApiService($transport);

        $this->expectException(PaymentApiException::class);
        $service->buatIntent('LAU/1', 1000.0, 'CASH');

        $this->assertSame(0, $transport->callCount);
    }

    public function testSuccessFalseMelemparException(): void
    {
        $transport               = new FakePaymentTransport();
        $transport->respondFail  = true;
        $service                 = new PaymentApiService($transport);

        $this->expectException(PaymentApiException::class);
        $service->buatIntent('LAU/1', 1000.0, PaymentApiService::QRIS);
    }

    public function testBatalkanIntentBersifatBestEffort(): void
    {
        $transport         = new FakePaymentTransport();
        $transport->throwOnPost = true;
        $service           = new PaymentApiService($transport);

        $service->batalkanIntent('PAY-1');

        $this->assertSame(1, $transport->callCount);
    }

    protected function setUp(): void
    {
        parent::setUp();
        putenv('PAYMENT_API_URL=http://127.0.0.1:3000/api/transactions');
        putenv('PAYMENT_API_KEY=key-uji');
    }
}
```

- [ ] **Step 2: Buat fake transport**

Buat `tests/_support/Services/FakePaymentTransport.php`:

```php
<?php

namespace Tests\Support\Services;

use App\Services\PaymentTransport;

class FakePaymentTransport implements PaymentTransport
{
    /** @var array<string, mixed> */
    public array $lastPayload = [];

    public int $callCount = 0;

    public bool $respondFail = false;

    public bool $throwOnPost = false;

    public string $expiredAt = '2026-10-24T12:00:00+07:00';

    public function post(string $url, array $payload, string $apiKey): array
    {
        $this->callCount++;
        $this->lastPayload = $payload;

        if ($this->throwOnPost) {
            throw new \RuntimeException('connection refused');
        }

        if ($this->respondFail) {
            return ['success' => false, 'error' => 'Amount tidak valid'];
        }

        return [
            'success' => true,
            'data'    => [
                'transaction_id' => 'PAY-' . $this->callCount,
                'amount'         => $payload['amount'],
                'method'         => $payload['method'],
                'payment_detail' => $payload['method'] === 'QRIS'
                    ? ['qris_data' => 'QRIS-FAKE', 'merchant_name' => 'Sparkleen']
                    : ['bank_name' => 'Bank BCA', 'account_number' => '1234567890', 'account_holder' => 'Sparkleen'],
                'expired_at'     => $this->expiredAt,
                'status'         => 'PENDING',
            ],
        ];
    }

    public function postEmpty(string $url, string $apiKey): void
    {
        $this->callCount++;

        if ($this->throwOnPost) {
            throw new \RuntimeException('connection refused');
        }
    }
}
```

- [ ] **Step 3: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PaymentApiServiceTest`
Expected: FAIL — kelas `PaymentTransport` / `PaymentApiService` belum ada.

- [ ] **Step 4: Tulis interface transport**

Buat `app/Services/PaymentTransport.php`:

```php
<?php

namespace App\Services;

interface PaymentTransport
{
    /**
     * @param array<string, mixed> $payload
     *
     * @return array<string, mixed> body JSON yang sudah didecode
     *
     * @throws \RuntimeException ketika permintaan tidak bisa dikirim
     */
    public function post(string $url, array $payload, string $apiKey): array;

    /**
     * POST tanpa body, untuk endpoint yang tidak menerima payload.
     *
     * @throws \RuntimeException ketika permintaan tidak bisa dikirim
     */
    public function postEmpty(string $url, string $apiKey): void;
}
```

- [ ] **Step 5: Tulis transport nyata**

Buat `app/Services/CurlPaymentTransport.php`:

```php
<?php

namespace App\Services;

use CodeIgniter\HTTP\Exceptions\HTTPException;

class CurlPaymentTransport implements PaymentTransport
{
    private const TIMEOUT = 5;

    public function post(string $url, array $payload, string $apiKey): array
    {
        try {
            $response = service('curlrequest')->post($url, $this->options($apiKey, [
                'json' => $payload,
            ]));
        } catch (HTTPException $e) {
            throw new \RuntimeException($e->getMessage(), 0, $e);
        }

        $decoded = json_decode((string) $response->getBody(), true);

        return is_array($decoded) ? $decoded : [];
    }

    public function postEmpty(string $url, string $apiKey): void
    {
        try {
            service('curlrequest')->post($url, $this->options($apiKey));
        } catch (HTTPException $e) {
            throw new \RuntimeException($e->getMessage(), 0, $e);
        }
    }

    /**
     * @param array<string, mixed> $extra
     *
     * @return array<string, mixed>
     */
    private function options(string $apiKey, array $extra = []): array
    {
        return $extra + [
            'headers' => [
                'X-Api-Key'    => $apiKey,
                'Accept'       => 'application/json',
                'Content-Type' => 'application/json',
            ],
            'timeout' => self::TIMEOUT,
        ];
    }
}
```

- [ ] **Step 6: Tulis service + exception**

Buat `app/Services/PaymentApiException.php`:

```php
<?php

namespace App\Services;

class PaymentApiException extends \RuntimeException
{
}
```

Buat `app/Services/PaymentApiService.php`:

```php
<?php

namespace App\Services;

class PaymentApiService
{
    public const QRIS     = 'QRIS';
    public const TRANSFER = 'TRANSFER';

    /**
     * Kamus tunggal: nama di sisi klien → nama di Node API → id master metode pembayaran.
     * Node hanya menerima QRIS / BANK_TRANSFER (payment_api/src/routes/transactions.js).
     * tb_master_metode_pembayaran: 1 cash, 2 qris, 3 transfer.
     */
    private const METHODS = [
        self::QRIS     => ['api' => 'QRIS', 'id' => 2],
        self::TRANSFER => ['api' => 'BANK_TRANSFER', 'id' => 3],
    ];

    public function __construct(private readonly PaymentTransport $transport)
    {
    }

    public static function idMetode(string $metode): int
    {
        $config = self::METHODS[$metode] ?? null;

        if ($config === null) {
            throw new PaymentApiException('Metode pembayaran tidak dikenal.');
        }

        return $config['id'];
    }

    /**
     * @return array{transaction_id: string, nominal: float, metode: string, payment_detail: array<string, mixed>, expired_at: ?string}
     *
     * @throws PaymentApiException
     */
    public function buatIntent(string $noNota, float $nominal, string $metode): array
    {
        $config = self::METHODS[$metode] ?? null;

        if ($config === null) {
            throw new PaymentApiException('Metode pembayaran tidak dikenal.');
        }

        if ($nominal <= 0) {
            throw new PaymentApiException('Nominal pembayaran tidak valid.');
        }

        $url  = $this->url();
        $key  = $this->key();

        try {
            $body = $this->transport->post($url, [
                'amount'       => $nominal,
                'method'       => $config['api'],
                'customer_ref' => $noNota,
            ], $key);
        } catch (\RuntimeException $e) {
            throw new PaymentApiException('Payment API tidak dapat dihubungi: ' . $e->getMessage(), 0, $e);
        }

        if (($body['success'] ?? false) !== true) {
            throw new PaymentApiException((string) ($body['error'] ?? 'Payment API menolak permintaan.'));
        }

        $transactionId = (string) ($body['data']['transaction_id'] ?? '');
        if ($transactionId === '') {
            throw new PaymentApiException('Payment API tidak mengembalikan transaction_id.');
        }

        $detail           = (array) ($body['data']['payment_detail'] ?? []);
        $detail['expired_at'] = $body['data']['expired_at'] ?? null;
        $detail['metode']     = $metode;

        return [
            'transaction_id' => $transactionId,
            'nominal'        => $nominal,
            'metode'         => $metode,
            'payment_detail' => $detail,
            'expired_at'     => $detail['expired_at'],
        ];
    }

    /**
     * Pembatalan bersifat best-effort: kegagalan di Node tidak boleh membuat
     * sisi kita menggantung, karena payment_ref sudah kami kosongkan sendiri.
     */
    public function batalkanIntent(string $transactionId): void
    {
        try {
            $this->transport->postEmpty(
                $this->url() . '/' . rawurlencode($transactionId) . '/cancel',
                $this->key()
            );
        } catch (\Throwable $e) {
            log_message('error', 'Gagal membatalkan intent di Payment API: ' . $e->getMessage());
        }
    }

    private function url(): string
    {
        // env() sudah membaca $_ENV, $_SERVER, dan getenv() berurutan — tidak perlu fallback ganda.
        $url = trim((string) env('PAYMENT_API_URL'));

        if ($url === '') {
            throw new PaymentApiException('Payment API belum dikonfigurasi (PAYMENT_API_URL kosong).');
        }

        return rtrim($url, '/');
    }

    private function key(): string
    {
        $key = trim((string) env('PAYMENT_API_KEY'));

        if ($key === '') {
            throw new PaymentApiException('Payment API belum dikonfigurasi (PAYMENT_API_KEY kosong).');
        }

        return $key;
    }
}
```

- [ ] **Step 7: Daftarkan sebagai service**

Ubah `app/Config/Services.php`, tambah method berikut di dalam kelas, sejajar dengan
`apiContext()`:

```php
    public static function paymentApi(bool $getShared = true)
    {
        if ($getShared) {
            return static::getSharedInstance('paymentApi');
        }

        return new \App\Services\PaymentApiService(new \App\Services\CurlPaymentTransport());
    }
```

- [ ] **Step 8: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PaymentApiServiceTest`
Expected: OK (5 test).

- [ ] **Step 9: Stage + commit**

```bash
git add "app/Services/PaymentTransport.php" "app/Services/CurlPaymentTransport.php" \
        "app/Services/PaymentApiService.php" "app/Services/PaymentApiException.php" \
        "app/Config/Services.php" \
        "tests/_support/Services/FakePaymentTransport.php" \
        "tests/unit/Services/PaymentApiServiceTest.php"
git commit -m "feat(api): service terpusat untuk payment api node"
```

---

## Task 3: Jalur kasir lama memakai service yang sama (tanpa perubahan perilaku)

**Files:**
- Modify: `app/Services/TransaksiService.php` (blok QRIS/Transfer di `prosesPembayaran()`)
- Test: `tests/Feature/TransaksiPembayaranApiTest.php`

**Interfaces:**
- Consumes: `service('paymentApi')` dari Task 2; `TransaksiService::prosesPembayaran(int, array): array`.
- Produces: perilaku `prosesPembayaran()` yang identik untuk kasir: sukses mengembalikan
  `['success' => true, 'message' => 'Permintaan {QRIS|BANK_TRANSFER} berhasil dikirim ke API. ...']`,
  gagal mengembalikan `success: false`, dan **tidak pernah** menulis `tb_pembayaran`.

**Baseline yang sudah terbukti (2026-10-24):** di repo backend yang sedang kotor,
`php vendor/bin/phpunit --filter TransaksiFeatureTest` menghasilkan
`Tests: 10, Assertions: 23, Failures: 7` (mis. `Key 'kembalian' is not in the current $_SESSION`
di `tests/Feature/TransaksiFeatureTest.php:283`). Itu kegagalan lama, bukan akibat refactor ini.
Standar Task 3 bukan "suite lama hijau", tapi "jumlah kegagalan Task 3 ini tidak bertambah".

- [ ] **Step 0: Catat baseline sebelum menyentuh apa pun**

Run: `php vendor/bin/phpunit --filter TransaksiFeatureTest 2>&1 | tail -5`
Salin baris `Tests: N, Assertions: N, Failures: N` ke catatan commit nanti. Kalau angkanya bukan
`10 / 23 / 7`, yang jadi acuan adalah angka yang baru dicatat itu.

- [ ] **Step 1: Tulis test karakterisasi**

Buat `tests/Feature/TransaksiPembayaranApiTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Services\PaymentApiService;
use App\Services\TransaksiService;
use CodeIgniter\Config\Services as ConfigServices;
use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use Config\Services;
use Tests\Support\Api\ApiTestTrait;
use Tests\Support\Services\FakePaymentTransport;

/**
 * @internal
 */
final class TransaksiPembayaranApiTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    use ApiTestTrait;

    protected $migrate     = true;
    protected $migrateOnce = true;
    protected $DBGroup     = 'tests';
    protected $namespace   = null;

    private FakePaymentTransport $transport;

    protected function setUp(): void
    {
        parent::setUp();

        putenv('PAYMENT_API_URL=http://127.0.0.1:3000/api/transactions');
        putenv('PAYMENT_API_KEY=key-uji');

        $this->transport = new FakePaymentTransport();
        ConfigServices::injectMock('paymentApi', new PaymentApiService($this->transport));
    }

    protected function tearDown(): void
    {
        ConfigServices::reset(true);
        parent::tearDown();
    }

    public function testQrisMenyimpanPaymentRefDanTidakMencatatPembayaran(): void
    {
        $p   = $this->createPelanggan();
        $trx = $this->createTransaksi($p, ['grand_total' => 21000]);

        $result = (new TransaksiService())->prosesPembayaran((int) $trx['id_transaksi'], [
            'nominal_bayar'        => 21000,
            'id_metode_pembayaran' => 2,
        ]);

        $this->assertTrue($result['success']);

        $tersimpan = db_connect('tests')->table('tb_transaksi')
            ->where('id_transaksi', $trx['id_transaksi'])->get()->getRowArray();

        $this->assertSame('PAY-1', $tersimpan['payment_ref']);
        $this->assertSame(2, (int) $tersimpan['id_metode_pembayaran']);
        $detail = json_decode((string) $tersimpan['payment_detail'], true);
        $this->assertSame('QRIS-FAKE', $detail['qris_data']);
        $this->assertNotNull($detail['expired_at']);

        $this->assertSame(0, db_connect('tests')->table('tb_pembayaran')
            ->where('id_transaksi', $trx['id_transaksi'])->countAllResults());
        $this->assertSame('QRIS', $this->transport->lastPayload['method']);
    }

    public function testPaymentApiTolakPermintaanTidakMenyimpanApaPun(): void
    {
        $p   = $this->createPelanggan();
        $trx = $this->createTransaksi($p, ['grand_total' => 21000]);
        $this->transport->respondFail = true;

        $result = (new TransaksiService())->prosesPembayaran((int) $trx['id_transaksi'], [
            'nominal_bayar'        => 21000,
            'id_metode_pembayaran' => 3,
        ]);

        $this->assertFalse($result['success']);

        $tersimpan = db_connect('tests')->table('tb_transaksi')
            ->where('id_transaksi', $trx['id_transaksi'])->get()->getRowArray();

        $this->assertNull($tersimpan['payment_ref']);
        $this->assertSame(0, db_connect('tests')->table('tb_pembayaran')
            ->where('id_transaksi', $trx['id_transaksi'])->countAllResults());
    }

    public function testPaymentApiBelumDikonfigurasiGagalRapi(): void
    {
        putenv('PAYMENT_API_URL=');
        putenv('PAYMENT_API_KEY=');

        $p   = $this->createPelanggan();
        $trx = $this->createTransaksi($p, ['grand_total' => 21000]);

        $result = (new TransaksiService())->prosesPembayaran((int) $trx['id_transaksi'], [
            'nominal_bayar'        => 21000,
            'id_metode_pembayaran' => 2,
        ]);

        $this->assertFalse($result['success']);
    }
}
```

Jalankan sekarang terhadap kode lama. Test ini **wajib** hijau sebelum dan sesudah refactor —
itu gunanya. Kalau salah satu gagal di kode lama, berarti gw salah baca perilaku yang ada;
stop dan laporkan, jangan lanjut refactor.

- [ ] **Step 2: Jalankan test pada kode lama**

Run: `php vendor/bin/phpunit --filter TransaksiPembayaranApiTest`
Expected: OK (3 test). Kalau FAIL, perbaiki pemahaman dulu — jangan menormalkan kegagalan.

- [ ] **Step 3: Ganti blok QRIS/Transfer di `prosesPembayaran()`**

Di `app/Services/TransaksiService.php`, blok yang dimulai komentar
`// INTEGRASI PAYMENT API NODE.JS (Untuk QRIS dan Transfer)` sampai penutup `catch (\Throwable $e)`
blok metode 2/3 diganti seluruhnya menjadi:

```php
        // INTEGRASI PAYMENT API (QRIS & Transfer): intent dibuat, uang dicatat nanti
        // oleh Webhook::payment() supaya hanya sisi pembayar yang menyatakan lunas.
        // 1 = Cash, 2 = QRIS, 3 = Transfer
        if ($id_metode_pembayaran === 2 || $id_metode_pembayaran === 3) {
            $metode = $id_metode_pembayaran === 2
                ? PaymentApiService::QRIS
                : PaymentApiService::TRANSFER;

            try {
                $intent = service('paymentApi')->buatIntent(
                    (string) $transaksi['no_nota'],
                    (float) $nominal_bayar,
                    $metode
                );
            } catch (PaymentApiException $e) {
                // Jangan pernah fallback ke pencatatan cash: uangnya belum masuk.
                log_message('error', 'Payment API gagal: ' . $e->getMessage());

                return [
                    'success' => false,
                    'message' => 'Payment API tidak dapat dihubungi. Pembayaran TIDAK dicatat; '
                        . 'silakan coba lagi atau gunakan metode Cash.',
                ];
            }

            $saved = $this->transaksiModel->update($id_transaksi, [
                'payment_ref'            => $intent['transaction_id'],
                'payment_detail'         => json_encode($intent['payment_detail']),
                'id_metode_pembayaran'   => $id_metode_pembayaran,
            ]);

            if (! $saved) {
                log_message('error', 'Gagal menyimpan payment_ref ' . $intent['transaction_id']
                    . ' untuk id_transaksi=' . $id_transaksi);

                service('paymentApi')->batalkanIntent($intent['transaction_id']);

                return [
                    'success' => false,
                    'message' => 'Pembayaran dibuat di Payment API tetapi gagal disimpan di sistem. '
                        . 'Catat manual dan hubungi admin.',
                ];
            }

            return [
                'success' => true,
                'message' => "Permintaan {$metode} berhasil dikirim ke API. "
                    . 'Menunggu pembayaran pelanggan/kasir via Node API.',
            ];
        }
```

Tambahkan di bagian `use` paling atas file:

```php
use App\Services\PaymentApiException;
use App\Services\PaymentApiService;
```

Catatan: pesan sukses lama memakai kata `QRIS`/`BANK_TRANSFER`; versi baru memakai
`QRIS`/`TRANSFER`. Kalau view kasir mencocokkan string itu, cek dulu:
`grep -rn "berhasil dikirim ke API" app/Views`. Kalau ada yang mencocokkan, simpan nama metode
Node di variabel terpisah dan pakai di message, jangan ubah view.

- [ ] **Step 4: Jalankan test karakterisasi lagi**

Run: `php vendor/bin/phpunit --filter TransaksiPembayaranApiTest`
Expected: OK (3 test).

- [ ] **Step 5: Jalankan suite transaksi lama, pastikan tidak ada regresi**

Run: `php vendor/bin/phpunit --filter TransaksiFeatureTest`
Expected: sama seperti baseline Step 0 (`Failures: 7`). **Bukan** berarti "OK" — suite itu sudah
merah sebelum Task ini. Yang boleh berubah hanya nol: jumlah failure dan nama test yang gagal
wajib identik dengan Step 0. Kalau bertambah satu saja, refactor ini yang menyebabkannya —
perbaiki sebelum commit.

- [ ] **Step 6: Stage + commit**

```bash
git add "app/Services/TransaksiService.php" "tests/Feature/TransaksiPembayaranApiTest.php"
git commit -m "refactor(api): jalur kasir memakai payment service terpusat"
```

---

## Task 4: Endpoint permintaan (buat + validasi + batas satu)

**Files:**
- Create: `app/Controllers/Api/V1/PermintaanController.php`
- Modify: `app/Config/Routes.php`
- Test: `tests/Feature/Api/PermintaanFlowTest.php`

**Interfaces:**
- Consumes: `service('apiContext')->pelanggan`, `MPermintaanPesanan` (Task 1), `MLayanan`,
  `MApiTransaksi::iso()`, `BaseApiController::ok()/fail()`.
- Produces: bentuk JSON `permintaan` yang dipakai app (Task B Flutter):

```json
{
  "id_permintaan": 12,
  "status": "menunggu",
  "id_layanan": 3,
  "nama_layanan": "Kiloan",
  "berat_perkiraan": 3.0,
  "estimasi_harga": 21000,
  "alamat_jemput": "Jl. Uji No. 1",
  "tgl_jemput": "2026-10-25T08:00:00+07:00",
  "slot_jemput": "pagi",
  "catatan": null,
  "id_transaksi": null,
  "alasan_penolakan": null,
  "created_at": "2026-10-24T10:00:00+07:00"
}
```

- [ ] **Step 1: Tulis test gagal**

Buat `tests/Feature/Api/PermintaanFlowTest.php`:

```php
<?php

namespace Tests\Feature\Api;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use CodeIgniter\Test\FeatureTestTrait;
use Tests\Support\Api\ApiTestTrait;

/**
 * @internal
 */
final class PermintaanFlowTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    use FeatureTestTrait;
    use ApiTestTrait;

    protected $migrate     = true;
    protected $migrateOnce = true;
    protected $DBGroup     = 'tests';
    protected $namespace   = null;

    private function payload(array $layanan, array $override = []): array
    {
        return array_merge([
            'id_layanan'      => $layanan['id_layanan'],
            'berat_perkiraan' => 4.5,
            'alamat_jemput'   => 'Jl. Melati No. 7, RT 2',
            'tgl_jemput'      => date('Y-m-d', strtotime('+1 day')),
            'slot_jemput'     => 'siang',
            'catatan'         => 'Cuci pisah dengan handuk',
        ], $override);
    }

    public function testBuatPermintaanMengembalikan201DanEstimasiHarga(): void
    {
        $p       = $this->createPelanggan();
        $layanan = $this->createLayanan('Kiloan', 7000);
        $token   = $this->createTokenFor($p)['token'];

        $result = $this->withHeaders($this->authHeaders($token))
            ->withJSON($this->payload($layanan))
            ->post('api/v1/permintaan');

        $result->assertStatus(201);
        $data = json_decode($result->getJSON(), true)['data'];

        $this->assertSame('menunggu', $data['status']);
        $this->assertSame(31500, $data['estimasi_harga']);
        $this->assertSame(4.5, $data['berat_perkiraan']);
        $this->assertSame('siang', $data['slot_jemput']);
        $this->assertSame(date('Y-m-d', strtotime('+1 day')) . 'T12:00:00+07:00', $data['tgl_jemput']);
        $this->assertNull($data['id_transaksi']);
    }

    public function testDuaPermintaanMenungguDitolak409(): void
    {
        $p       = $this->createPelanggan();
        $layanan = $this->createLayanan();
        $token   = $this->createTokenFor($p)['token'];

        $this->withHeaders($this->authHeaders($token))->withJSON($this->payload($layanan))
            ->post('api/v1/permintaan')->assertStatus(201);

        $result = $this->withHeaders($this->authHeaders($token))->withJSON($this->payload($layanan))
            ->post('api/v1/permintaan');

        $result->assertStatus(409);
        $this->assertStringContainsString('ACTIVE_REQUEST_EXISTS', (string) $result->getJSON());

        $this->assertSame(1, db_connect('tests')->table('tb_permintaan_pesanan')->countAllResults());
    }

    public function testValidasiMenolakSlotSalahDanBeratNol(): void
    {
        $p       = $this->createPelanggan();
        $layanan = $this->createLayanan();
        $token   = $this->createTokenFor($p)['token'];

        $result = $this->withHeaders($this->authHeaders($token))
            ->withJSON($this->payload($layanan, ['slot_jemput' => 'malam', 'berat_perkiraan' => 0]))
            ->post('api/v1/permintaan');

        $result->assertStatus(422);
        $body = json_decode($result->getJSON(), true);
        $this->assertSame('VALIDATION_ERROR', $body['error']['code']);
        $this->assertArrayHasKey('slot_jemput', $body['error']['fields']);
        $this->assertArrayHasKey('berat_perkiraan', $body['error']['fields']);
    }

    public function testLayananNonaktifDitolak(): void
    {
        $p     = $this->createPelanggan();
        $db    = db_connect('tests');
        $db->table('tb_layanan')->insert([
            'nama_layanan' => 'Nonaktif', 'harga_per_kg' => 8000,
            'estimasi_hari' => 2, 'is_aktif' => 0,
            'created_at' => date('Y-m-d H:i:s'), 'updated_at' => date('Y-m-d H:i:s'),
        ]);
        $id_layanan = (int) $db->insertID();
        $token      = $this->createTokenFor($p)['token'];

        $result = $this->withHeaders($this->authHeaders($token))
            ->withJSON($this->payload(['id_layanan' => $id_layanan]))
            ->post('api/v1/permintaan');

        $result->assertStatus(422);
    }

    public function testPermintaanTanpaTokenDitolak401(): void
    {
        $this->withJSON([])->post('api/v1/permintaan')->assertStatus(401);
    }
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PermintaanFlowTest`
Expected: FAIL — rute `api/v1/permintaan` belum ada (404).

- [ ] **Step 3: Tulis controller**

Buat `app/Controllers/Api/V1/PermintaanController.php`:

```php
<?php

namespace App\Controllers\Api\V1;

use App\Models\MApiTransaksi;
use App\Models\MLayanan;
use App\Models\MPermintaanPesanan;

class PermintaanController extends BaseApiController
{
    public function store()
    {
        $pelanggan = service('apiContext')->pelanggan;
        $idPelanggan = (int) $pelanggan['id_pelanggan'];

        $input   = $this->payload();
        $fields  = $this->validateStore($input);

        if ($fields !== []) {
            return $this->fail('VALIDATION_ERROR', 'Data yang dikirim belum valid.', 422, $fields);
        }

        $layanan = (new MLayanan())->where('id_layanan', (int) $input['id_layanan'])
            ->where('is_aktif', 1)->get()->getRowArray();

        if ($layanan === null) {
            return $this->fail('VALIDATION_ERROR', 'Data yang dikirim belum valid.', 422, [
                'id_layanan' => ['Layanan tidak tersedia.'],
            ]);
        }

        $model = new MPermintaanPesanan();

        if ($model->countMenunggu($idPelanggan) > 0) {
            return $this->fail(
                'ACTIVE_REQUEST_EXISTS',
                'Masih ada permintaan yang menunggu diproses kasir.',
                409
            );
        }

        $berat  = round((float) $input['berat_perkiraan'], 2);
        $tglMasuk = $input['tgl_jemput'] . ' ' . MPermintaanPesanan::SLOT_START[$input['slot_jemput']];

        $id = $model->insert([
            'id_pelanggan'    => $idPelanggan,
            'id_layanan'      => (int) $layanan['id_layanan'],
            'berat_perkiraan' => $berat,
            'catatan'         => trim((string) ($input['catatan'] ?? '')) ?: null,
            'alamat_jemput'   => trim((string) $input['alamat_jemput']),
            'tgl_jemput'      => $tglMasuk,
            'slot_jemput'     => $input['slot_jemput'],
            'status'          => MPermintaanPesanan::MENUNGGU,
        ]);

        if ($id === false) {
            return $this->fail('VALIDATION_ERROR', 'Data yang dikirim belum valid.', 422, $model->errors());
        }

        $permintaan = $model->findForPelanggan((int) $id, $idPelanggan);

        return $this->ok($this->present($permintaan), [], 201);
    }

    /**
     * @return array<string, list<string>>
     */
    private function validateStore(array $input): array
    {
        $fields = [];

        if (empty($input['id_layanan']) || ! is_numeric($input['id_layanan'])) {
            $fields['id_layanan'][] = 'Layanan wajib dipilih.';
        }

        $berat = $input['berat_perkiraan'] ?? null;
        if (! is_numeric($berat) || (float) $berat <= 0 || (float) $berat > 100) {
            $fields['berat_perkiraan'][] = 'Berat perkiraan harus antara 0.1 dan 100 kg.';
        }

        $alamat = trim((string) ($input['alamat_jemput'] ?? ''));
        if (mb_strlen($alamat) < 10) {
            $fields['alamat_jemput'][] = 'Alamat penjemputan minimal 10 karakter.';
        }

        if (empty($input['tgl_jemput']) || ! $this->isValidDate($input['tgl_jemput'])) {
            $fields['tgl_jemput'][] = 'Tanggal jemput tidak valid.';
        } elseif (strtotime((string) $input['tgl_jemput']) < strtotime(date('Y-m-d'))) {
            $fields['tgl_jemput'][] = 'Tanggal jemput tidak boleh di masa lalu.';
        }

        $slot = (string) ($input['slot_jemput'] ?? '');
        if (! isset(MPermintaanPesanan::SLOT_START[$slot])) {
            $fields['slot_jemput'][] = 'Slot harus pagi, siang, atau sore.';
        }

        if (mb_strlen(trim((string) ($input['catatan'] ?? ''))) > 255) {
            $fields['catatan'][] = 'Catatan maksimal 255 karakter.';
        }

        return $fields;
    }

    private function isValidDate(string $value): bool
    {
        return \DateTimeImmutable::createFromFormat('Y-m-d', $value) !== false;
    }

    /**
     * @param array<string, mixed> $row
     * @return array<string, mixed>
     */
    private function present(array $row): array
    {
        $estimasi = (float) $row['harga_per_kg'] * (float) $row['berat_perkiraan'];

        return [
            'id_permintaan'     => (int) $row['id_permintaan'],
            'status'            => $this->statusUntukKlien((string) $row['status']),
            'id_layanan'        => (int) $row['id_layanan'],
            'nama_layanan'      => $row['nama_layanan'],
            'berat_perkiraan'   => (float) $row['berat_perkiraan'],
            'estimasi_harga'    => (int) round($estimasi),
            'alamat_jemput'     => $row['alamat_jemput'],
            'tgl_jemput'        => MApiTransaksi::iso($row['tgl_jemput']),
            'slot_jemput'       => $row['slot_jemput'],
            'catatan'           => $row['catatan'],
            'estimasi_hari'     => (int) $row['estimasi_hari'],
            'id_transaksi'      => $row['id_transaksi'] === null ? null : (int) $row['id_transaksi'],
            'alasan_penolakan'  => $row['alasan_penolakan'],
            'created_at'        => MApiTransaksi::iso($row['created_at']),
        ];
    }

    /**
     * `diproses` adalah state internal kasir; bagi pelanggan itu masih `menunggu`.
     */
    private function statusUntukKlien(string $status): string
    {
        return $status === MPermintaanPesanan::DIPROSES
            ? MPermintaanPesanan::MENUNGGU
            : $status;
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(): array
    {
        $json = $this->request->getJSON(true);

        return is_array($json) ? $json : (array) $this->request->getPost();
    }
}
```

- [ ] **Step 4: Cek sintaks**

Run: `php -l app/Controllers/Api/V1/PermintaanController.php`
Expected: "No syntax errors detected".

- [ ] **Step 5: Daftarkan rute**

Di `app/Config/Routes.php`, di dalam group `api/v1` yang terproteksi
(`['namespace' => 'App\Controllers\Api\V1', 'filter' => ['cors', 'apiauth']]`), tambah setelah
rute transaksi:

```php
    $routes->get('permintaan', 'PermintaanController::index');
    $routes->post('permintaan', 'PermintaanController::store');
    $routes->get('permintaan/(:num)', 'PermintaanController::show/$1');
    $routes->post('permintaan/(:num)/batal', 'PermintaanController::batal/$1');
```

- [ ] **Step 6: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PermintaanFlowTest`
Expected: OK (5 test).

- [ ] **Step 7: Stage + commit**

```bash
git add "app/Controllers/Api/V1/PermintaanController.php" "app/Config/Routes.php" \
        "tests/Feature/Api/PermintaanFlowTest.php"
git commit -m "feat(api): endpoint buat permintaan jemput"
```

---

## Task 5: Endpoint daftar, detail, dan batal permintaan

**Files:**
- Modify: `app/Controllers/Api/V1/PermintaanController.php`
- Test: `tests/Feature/Api/PermintaanFlowTest.php` (tambah method)

**Interfaces:**
- Consumes: `MPermintaanPesanan::paginateForPelanggan()`, `findForPelanggan()`,
  `claimUntukDiproses()` (dipakai ulang untuk membatalkan secara atomik).
- Produces: `GET /api/v1/permintaan` (meta pagination sama seperti `/transaksi`),
  `GET /api/v1/permintaan/{id}`, `POST /api/v1/permintaan/{id}/batal`.

- [ ] **Step 1: Tulis test gagal**

Tambahkan method berikut ke `tests/Feature/Api/PermintaanFlowTest.php`:

```php
    public function testDaftarMemisahkanAktifDanSelesai(): void
    {
        $p       = $this->createPelanggan();
        $layanan = $this->createLayanan();
        $token   = $this->createTokenFor($p)['token'];

        $aktif = $this->createPermintaan($p, ['id_layanan' => $layanan['id_layanan']]);
        $ditolak = $this->createPermintaan($p, [
            'id_layanan' => $layanan['id_layanan'],
            'status'     => 'ditolak',
        ]);

        $result = $this->withHeaders($this->authHeaders($token))
            ->get('api/v1/permintaan?status=aktif');
        $result->assertStatus(200);
        $items = json_decode($result->getJSON(), true)['data'];
        $this->assertCount(1, $items);
        $this->assertSame((int) $aktif['id_permintaan'], $items[0]['id_permintaan']);

        $selesai = $this->withHeaders($this->authHeaders($token))
            ->get('api/v1/permintaan?status=selesai');
        $selesaiItems = json_decode($selesai->getJSON(), true)['data'];
        $this->assertCount(1, $selesaiItems);
        $this->assertSame((int) $ditolak['id_permintaan'], $selesaiItems[0]['id_permintaan']);
        $this->assertSame('ditolak', $selesaiItems[0]['status']);
    }

    public function testDetailPunyaOrangLainMengembalikan404(): void
    {
        $pemilik = $this->createPelanggan(['no_telp' => '6281200000011']);
        $asing   = $this->createPelanggan(['no_telp' => '6281200000012']);
        $id      = (int) $this->createPermintaan($pemilik)['id_permintaan'];

        $result = $this->withHeaders($this->authHeaders($this->createTokenFor($asing)['token']))
            ->get('api/v1/permintaan/' . $id);

        $result->assertStatus(404);
    }

    public function testBatalHanyaSaatMenunggu(): void
    {
        $p         = $this->createPelanggan();
        $layanan   = $this->createLayanan();
        $token     = $this->createTokenFor($p)['token'];
        $menunggu  = (int) $this->createPermintaan($p, ['id_layanan' => $layanan['id_layanan']])['id_permintaan'];
        $selesai   = (int) $this->createPermintaan($p, [
            'id_layanan' => $layanan['id_layanan'],
            'status'     => 'dikonfirmasi',
        ])['id_permintaan'];

        $this->withHeaders($this->authHeaders($token))
            ->post('api/v1/permintaan/' . $menunggu . '/batal')->assertStatus(200);

        $row = db_connect('tests')->table('tb_permintaan_pesanan')
            ->where('id_permintaan', $menunggu)->get()->getRowArray();
        $this->assertSame('dibatalkan', $row['status']);

        $result = $this->withHeaders($this->authHeaders($token))
            ->post('api/v1/permintaan/' . $selesai . '/batal');
        $result->assertStatus(409);
    }
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PermintaanFlowTest`
Expected: FAIL — `index`, `show`, `batal` belum ada (404).

- [ ] **Step 3: Implementasikan tiga method**

Tambahkan ke `PermintaanController` (di dalam kelas, sebelum `payload()`):

```php
    public function index()
    {
        $pelanggan = service('apiContext')->pelanggan;

        $scope = (string) ($this->request->getGet('status') ?? 'semua');
        if (! in_array($scope, ['aktif', 'selesai', 'semua'], true)) {
            $scope = 'semua';
        }

        $page    = max(1, (int) ($this->request->getGet('page') ?? 1));
        $perPage = (int) ($this->request->getGet('per_page') ?? 20);
        $perPage = max(1, min(50, $perPage));

        $result = (new MPermintaanPesanan())->paginateForPelanggan(
            (int) $pelanggan['id_pelanggan'],
            $scope,
            $page,
            $perPage,
        );

        return $this->ok(array_map(fn (array $row): array => $this->present($row), $result['items']), [
            'page'      => $page,
            'per_page'  => $perPage,
            'total'     => $result['total'],
            'last_page' => max(1, (int) ceil($result['total'] / $perPage)),
        ]);
    }

    public function show($id = null)
    {
        $pelanggan = service('apiContext')->pelanggan;
        $permintaan = (new MPermintaanPesanan())->findForPelanggan((int) $id, (int) $pelanggan['id_pelanggan']);

        if ($permintaan === null) {
            return $this->fail('NOT_FOUND', 'Permintaan tidak ditemukan.', 404);
        }

        return $this->ok($this->present($permintaan));
    }

    public function batal($id = null)
    {
        $pelanggan = service('apiContext')->pelanggan;
        $model     = new MPermintaanPesanan();
        $idPelanggan = (int) $pelanggan['id_pelanggan'];

        $permintaan = $model->findForPelanggan((int) $id, $idPelanggan);

        if ($permintaan === null) {
            return $this->fail('NOT_FOUND', 'Permintaan tidak ditemukan.', 404);
        }

        if ($permintaan['status'] !== MPermintaanPesanan::MENUNGGU) {
            return $this->fail(
                'CANNOT_CANCEL',
                'Permintaan hanya bisa dibatalkan selama belum diproses kasir.',
                409
            );
        }

        // Klaim atomik lalu timpa statusnya: dua tap cepat hanya boleh menghasilkan satu batal.
        if (! $model->claimUntukDiproses((int) $id, $idPelanggan)) {
            return $this->fail('CANNOT_CANCEL', 'Permintaan sudah sedang diproses.', 409);
        }

        $model->update((int) $id, ['status' => MPermintaanPesanan::DIBATALKAN]);

        return $this->ok($this->present($model->findForPelanggan((int) $id, $idPelanggan)));
    }
```

- [ ] **Step 4: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PermintaanFlowTest`
Expected: OK (8 test).

- [ ] **Step 5: Stage + commit**

```bash
git add "app/Controllers/Api/V1/PermintaanController.php" "tests/Feature/Api/PermintaanFlowTest.php"
git commit -m "feat(api): daftar, detail, dan batal permintaan jemput"
```

---

## Task 6: Endpoint pembayaran (intent dibuat pelanggan)

**Files:**
- Modify: `app/Controllers/Api/V1/BaseApiController.php`
- Modify: `app/Controllers/Api/V1/TransaksiController.php` (buang helper privat, tambah `sisa_tagihan`)
- Create: `app/Controllers/Api/V1/PembayaranController.php`
- Modify: `app/Config/Routes.php`
- Test: `tests/Feature/Api/PembayaranFlowTest.php`

**Interfaces:**
- Consumes: `service('paymentApi')` (Task 2), `MApiTransaksi::findForPelanggan()`,
  `MApiTransaksi::sisaTagihan()`.
- Produces:
  `findOwnTransaction(int $id): ?array` di `BaseApiController`,
  `sisaTagihan(int $idTransaksi): float` di `MApiTransaksi`,
  field `sisa_tagihan` (int) di `GET /api/v1/transaksi/{id}`, dan bentuk JSON pembayaran:

```json
{
  "status": "PENDING",
  "metode": "QRIS",
  "nominal": 21000,
  "total_dibayar": 0,
  "sisa": 21000,
  "status_pembayaran": "belum",
  "expired_at": "2026-10-24T12:15:00+07:00",
  "payment_detail": {"qris_data": "...", "merchant_name": "Sparkleen", "metode": "QRIS"}
}
```

`status` pembayaran adalah enum string: `NONE`, `PENDING`, `EXPIRED`, `SUCCESS`.

- [ ] **Step 1: Tulis test gagal**

Buat `tests/Feature/Api/PembayaranFlowTest.php`:

```php
<?php

namespace Tests\Feature\Api;

use App\Services\PaymentApiService;
use CodeIgniter\Config\Services as ConfigServices;
use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use CodeIgniter\Test\FeatureTestTrait;
use Tests\Support\Api\ApiTestTrait;
use Tests\Support\Services\FakePaymentTransport;

/**
 * @internal
 */
final class PembayaranFlowTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    use FeatureTestTrait;
    use ApiTestTrait;

    protected $migrate     = true;
    protected $migrateOnce = true;
    protected $DBGroup     = 'tests';
    protected $namespace   = null;

    private FakePaymentTransport $transport;
    private string $token = '';
    private int $idTrx = 0;

    protected function setUp(): void
    {
        parent::setUp();

        putenv('PAYMENT_API_URL=http://127.0.0.1:3000/api/transactions');
        putenv('PAYMENT_API_KEY=key-uji');

        $this->transport = new FakePaymentTransport();
        ConfigServices::injectMock('paymentApi', new PaymentApiService($this->transport));

        $p     = $this->createPelanggan();
        $trx   = $this->createTransaksi($p, ['grand_total' => 21000]);
        $this->token  = $this->createTokenFor($p)['token'];
        $this->idTrx  = (int) $trx['id_transaksi'];
    }

    protected function tearDown(): void
    {
        ConfigServices::reset(true);
        parent::tearDown();
    }

    public function testDetailTransaksiMenyediakanSisaTagihan(): void
    {
        $result = $this->withHeaders($this->authHeaders($this->token))
            ->get('api/v1/transaksi/' . $this->idTrx);

        $result->assertStatus(200);
        $data = json_decode($result->getJSON(), true)['data'];
        $this->assertSame(21000, $data['sisa_tagihan']);
    }

    public function testBuatIntentQrisMenyimpanRefDanMengembalikanDetail(): void
    {
        $result = $this->withHeaders($this->authHeaders($this->token))
            ->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(201);
        $data = json_decode($result->getJSON(), true)['data'];
        $this->assertSame('PENDING', $data['status']);
        $this->assertSame(21000, $data['nominal']);
        $this->assertSame('QRIS-FAKE', $data['payment_detail']['qris_data']);

        $row = db_connect('tests')->table('tb_transaksi')->where('id_transaksi', $this->idTrx)
            ->get()->getRowArray();
        $this->assertSame('PAY-1', $row['payment_ref']);
        $this->assertSame(2, (int) $row['id_metode_pembayaran']);
        $this->assertSame('QRIS', $this->transport->lastPayload['method']);
    }

    public function testIntentKeduaMetodeSamaIdempoten(): void
    {
        $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran')->assertStatus(201);

        $result = $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(200);
        $this->assertSame(1, $this->transport->callCount);
    }

    public function testIntentMetodeLainDitolak409(): void
    {
        $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result = $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'TRANSFER'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(409);
        $this->assertStringContainsString('CONFLICT_METHOD', (string) $result->getJSON());
    }

    public function testTransaksiLunasTidakBisaDibayarLagi(): void
    {
        db_connect('tests')->table('tb_transaksi')->where('id_transaksi', $this->idTrx)
            ->update(['id_status_pembayaran' => 1]);

        $result = $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(409);
        $this->assertStringContainsString('ALREADY_PAID', (string) $result->getJSON());
        $this->assertSame(0, $this->transport->callCount);
    }

    public function testNominalIntentAdalahSisaBukanGrandTotal(): void
    {
        db_connect('tests')->table('tb_pembayaran')->insert([
            'id_transaksi' => $this->idTrx, 'tgl_bayar' => date('Y-m-d H:i:s'),
            'nominal_bayar' => 6000, 'sisa_tagihan' => 15000, 'id_metode_pembayaran' => 1,
        ]);

        $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran')->assertStatus(201);

        $this->assertSame(15000.0, $this->transport->lastPayload['amount']);
    }

    public function testReadTanpaIntentMengembalikanNone(): void
    {
        $result = $this->withHeaders($this->authHeaders($this->token))
            ->get('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(200);
        $data = json_decode($result->getJSON(), true)['data'];
        $this->assertSame('NONE', $data['status']);
        $this->assertSame(21000, $data['sisa']);
    }

    public function testReadKedaluwarsa(): void
    {
        $this->transport->expiredAt = date('c', strtotime('-1 hour'));

        $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result = $this->withHeaders($this->authHeaders($this->token))
            ->get('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $data = json_decode($result->getJSON(), true)['data'];
        $this->assertSame('EXPIRED', $data['status']);
    }

    public function testBatalMengosongkanRefDanMembatalkanDiNode(): void
    {
        $this->withHeaders($this->authHeaders($this->token))->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result = $this->withHeaders($this->authHeaders($this->token))
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran/batal');

        $result->assertStatus(200);

        $row = db_connect('tests')->table('tb_transaksi')->where('id_transaksi', $this->idTrx)
            ->get()->getRowArray();
        $this->assertNull($row['payment_ref']);
        $this->assertNull($row['payment_detail']);
        $this->assertSame(2, $this->transport->callCount);
    }

    public function testTransaksiPunyaOrangLain404(): void
    {
        $asing = $this->createPelanggan(['no_telp' => '6281200000099']);

        $result = $this->withHeaders($this->authHeaders($this->createTokenFor($asing)['token']))
            ->withJSON(['metode' => 'QRIS'])
            ->post('api/v1/transaksi/' . $this->idTrx . '/pembayaran');

        $result->assertStatus(404);
    }
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PembayaranFlowTest`
Expected: FAIL — rute belum ada, `sisa_tagihan` belum ada.

- [ ] **Step 3: Pindah helper kepemilikan ke base**

Di `app/Controllers/Api/V1/BaseApiController.php`, tambah method berikut (di bawah `noContent()`):

```php
    /**
     * Transaksi milik pelanggan yang token-nya dipakai sekarang. 404 untuk siapa pun
     * yang bukan pemilik, supaya keberadaan data tidak bocor lewat 403.
     *
     * @return array<string, mixed>|null
     */
    protected function findOwnTransaction(int $id): ?array
    {
        if ($id <= 0) {
            return null;
        }

        $pelanggan = service('apiContext')->pelanggan;

        return (new \App\Models\MApiTransaksi())->findForPelanggan($id, (int) $pelanggan['id_pelanggan']);
    }

    /**
     * @return array<string, mixed>
     */
    protected function payload(): array
    {
        $json = $this->request->getJSON(true);

        return is_array($json) ? $json : (array) $this->request->getPost();
    }
```

Sekarang hapus **semua** salinan privat `payload()` di subclass — meninggalkan salah satunya
adalah fatal error PHP, bukan sekadar duplikasi: method `private` di child yang menimpa method
`protected` di parent membuat class itu tidak bisa dimuat sama sekali
(`Access level to C::payload() must be protected (as in class P) or weaker`), dan itu meledak
saat route-nya disentuh, bukan saat test ditulis.

1. `app/Controllers/Api/V1/AuthController.php` — hapus `private function payload(): array`
   (sekarang di baris ±238) dan `use` yang jadi tidak terpakai.
2. `app/Controllers/Api/V1/PermintaanController.php` — hapus `private function payload(): array`
   yang Task 4 tulis.
3. `app/Controllers/Api/V1/TransaksiController.php` — hapus method privat
   `findOwnTransaction()` (baris ±100-110), ia sekarang diwarisi.

Setelah menghapus, panggil `php -l` di ketiga file dan jalan
`php vendor/bin/phpunit --filter Auth` untuk memastikan `AuthController` masih hidup —
method itu dipakai `register()`, `login()`, dan `aktivasi()`.

- [ ] **Step 4: Tambah `sisaTagihan()` di MApiTransaksi**

Tambahkan method ini ke `app/Models/MApiTransaksi.php`, sebelum `baseSelect`-nya (file itu
memakai builder inline, jadi cukup):

```php
    /**
     * Sisa tagihan = grand_total - seluruh nominal yang sudah tercatat di tb_pembayaran.
     */
    public function sisaTagihan(int $idTransaksi): float
    {
        $transaksi = $this->find($idTransaksi);

        if ($transaksi === null) {
            return 0.0;
        }

        $sudah = $this->db->table('tb_pembayaran')
            ->selectSum('nominal_bayar', 'total')
            ->where('id_transaksi', $idTransaksi)
            ->get()->getRowArray();

        return (float) $transaksi['grand_total'] - (float) ($sudah['total'] ?? 0);
    }
```

Lalu di `TransaksiController::show()`, tambahkan satu field ke array response, sejajar
`grand_total`:

```php
            'sisa_tagihan'         => (int) round(max(0, $model->sisaTagihan((int) $transaksi['id_transaksi']))),
```

`$model` di situ sudah tersedia (`$model = new MApiTransaksi()` di method yang sama).

Catatan yang sengaja ditinggal: `TransaksiService::hitungSisaTagihan()` (baris ±396) sudah
melakukan aritmetika yang sama. Dua salinan ini **dipertahankan sadar**, bukan kelalaian —
`MApiTransaksi` adalah lapisan baca murni (dipakai `PembayaranController` dan `show()`, dan
merupakan kontrak Task 6), sedangkan `TransaksiService` adalah kelas tulis berat tempat jalur
kasir memanggil Node API. Menyatukannya berarti controller API mobile ikut menarik
`TransaksiService`, yang konstruksinya menyeret model transaksi + pembayaran + jalur HTTP.
Kalau reviewer nanti menandai duplikasi ini, itu sudah dijawab di sini — bukan untuk diubah
di task ini.

- [ ] **Step 5: Tulis controller pembayaran**

Buat `app/Controllers/Api/V1/PembayaranController.php`:

```php
<?php

namespace App\Controllers\Api\V1;

use App\Models\MApiTransaksi;
use App\Services\PaymentApiException;
use App\Services\PaymentApiService;

class PembayaranController extends BaseApiController
{
    public function store($id = null)
    {
        $transaksi = $this->findOwnTransaction((int) $id);

        if ($transaksi === null) {
            return $this->fail('NOT_FOUND', 'Transaksi tidak ditemukan.', 404);
        }

        $metode = strtoupper(trim((string) ($this->payload()['metode'] ?? '')));

        if (! in_array($metode, [PaymentApiService::QRIS, PaymentApiService::TRANSFER], true)) {
            return $this->fail('VALIDATION_ERROR', 'Metode harus QRIS atau TRANSFER.', 422, [
                'metode' => ['Metode pembayaran tidak dikenal.'],
            ]);
        }

        $sisa = max(0.0, (new MApiTransaksi())->sisaTagihan((int) $transaksi['id_transaksi']));

        if ($sisa <= 0) {
            return $this->fail('ALREADY_PAID', 'Tagihan transaksi ini sudah lunas.', 409);
        }

        $aktif = $this->bacaIntent($transaksi);

        if ($aktif !== null) {
            if ($aktif['metode'] === $metode && $aktif['status'] === 'PENDING') {
                return $this->ok($aktif);
            }

            return $this->fail(
                'CONFLICT_METHOD',
                'Masih ada tagihan ' . $aktif['metode'] . ' yang berjalan. Batalkan dulu sebelum ganti metode.',
                409
            );
        }

        try {
            $intent = service('paymentApi')->buatIntent(
                (string) $transaksi['no_nota'],
                $sisa,
                $metode
            );
        } catch (PaymentApiException $e) {
            log_message('error', 'Payment API gagal untuk trx ' . $transaksi['id_transaksi'] . ': ' . $e->getMessage());

            return $this->fail('PAYMENT_API_UNAVAILABLE', 'Payment API tidak dapat dihubungi. Coba lagi sebentar.', 502);
        }

        // Klaim atomik: kalau kasir membuka intent bersamaan, yang kalah tidak menimpa.
        // Catatan: BaseBuilder::update() mengembalikan bool, BUKAN jumlah baris. Yang harus
        // dibaca adalah affectedRows() dari connection-nya.
        $db      = db_connect();
        $claimed = $db->table('tb_transaksi')
            ->where('id_transaksi', (int) $transaksi['id_transaksi'])
            ->where('payment_ref', null)
            ->update([
                'payment_ref'          => $intent['transaction_id'],
                'payment_detail'       => json_encode($intent['payment_detail']),
                'id_metode_pembayaran' => PaymentApiService::idMetode($metode),
            ]);

        if ($claimed === false || $db->affectedRows() !== 1) {
            service('paymentApi')->batalkanIntent($intent['transaction_id']);

            $fresh = $this->findOwnTransaction((int) $transaksi['id_transaksi']);

            return $this->ok($this->bacaIntent($fresh ?? []));
        }

        $fresh = $this->findOwnTransaction((int) $transaksi['id_transaksi']);

        return $this->ok($this->bacaIntent($fresh ?? []), [], 201);
    }

    public function show($id = null)
    {
        $transaksi = $this->findOwnTransaction((int) $id);

        if ($transaksi === null) {
            return $this->fail('NOT_FOUND', 'Transaksi tidak ditemukan.', 404);
        }

        return $this->ok($this->bacaIntent($transaksi));
    }

    public function batal($id = null)
    {
        $transaksi = $this->findOwnTransaction((int) $id);

        if ($transaksi === null) {
            return $this->fail('NOT_FOUND', 'Transaksi tidak ditemukan.', 404);
        }

        $paymentRef = $transaksi['payment_ref'] ?? null;

        if ($paymentRef === null || $paymentRef === '') {
            return $this->fail('NO_ACTIVE_PAYMENT', 'Tidak ada tagihan online yang berjalan.', 409);
        }

        $db  = db_connect();
        $kosongkan = $db->table('tb_transaksi')
            ->where('id_transaksi', (int) $transaksi['id_transaksi'])
            ->where('payment_ref', $paymentRef)
            ->update(['payment_ref' => null, 'payment_detail' => null]);

        if ($kosongkan === false || $db->affectedRows() !== 1) {
            return $this->fail('NO_ACTIVE_PAYMENT', 'Tagihan sudah diproses.', 409);
        }

        service('paymentApi')->batalkanIntent((string) $paymentRef);

        return $this->ok($this->bacaIntent($this->findOwnTransaction((int) $transaksi['id_transaksi']) ?? []));
    }

    /**
     * Dibaca murni dari DB lokal. Status hanya berubah kalau Webhook::payment() sudah masuk;
     * dengan begitu app tidak pernah bisa menyatakan dirinya lunas.
     *
     * @param array<string, mixed> $transaksi
     *
     * @return array<string, mixed>
     */
    private function bacaIntent(array $transaksi): array
    {
        $model = new MApiTransaksi();
        $sisa  = max(0.0, $model->sisaTagihan((int) ($transaksi['id_transaksi'] ?? 0)));

        $detail = json_decode((string) ($transaksi['payment_detail'] ?? ''), true);
        $detail = is_array($detail) ? $detail : [];

        // expired_at ditulis oleh PaymentApiService::buatIntent() ke dalam payment_detail,
        // bukan kolom baru di tb_transaksi (spec §5.2: nol perubahan struktur).
        $expiredAt = $detail['expired_at'] ?? null;

        $totalDibayar = (float) ($transaksi['grand_total'] ?? 0) - $sisa;

        $ref  = $transaksi['payment_ref'] ?? null;
        $paid = (float) ($transaksi['grand_total'] ?? 0);
        $metode = $detail['metode'] ?? $transaksi['metode_pembayaran'] ?? null;

        // Lunas lebih dulu, sebelum cek payment_ref. Webhook justru MENGOSONGKAN payment_ref
        // dan payment_detail sebagai klaim anti-callback-ganda (Webhook.php:59-63), jadi barusan
        // dibayar = payment_ref null + tb_pembayaran penuh. Tanpa urutan ini, pembayaran yang
        // sukses balik ke status NONE.
        if ($sisa <= 0 && $paid > 0) {
            return [
                'status'            => 'SUCCESS',
                'metode'            => $metode,
                'nominal'           => (int) round($paid),
                'total_dibayar'     => (int) round($totalDibayar),
                'sisa'              => 0,
                'status_pembayaran' => $transaksi['status_pembayaran'] ?? 'lunas',
                'expired_at'        => $expiredAt === null ? null : MApiTransaksi::iso((string) $expiredAt),
                'payment_detail'    => $detail === [] ? new \stdClass() : $detail,
            ];
        }

        if ($ref === null || $ref === '') {
            return [
                'status'            => 'NONE',
                'metode'            => $metode,
                'nominal'           => (int) round($sisa),
                'total_dibayar'     => (int) round($totalDibayar),
                'sisa'              => (int) round($sisa),
                'status_pembayaran' => $transaksi['status_pembayaran'] ?? 'belum',
                'expired_at'        => null,
                'payment_detail'    => new \stdClass(),
            ];
        }

        $kedaluwarsa = $expiredAt !== null && strtotime((string) $expiredAt) < time();

        return [
            'status'            => $kedaluwarsa ? 'EXPIRED' : 'PENDING',
            'metode'            => $metode,
            'nominal'           => (int) round($sisa),
            'total_dibayar'     => (int) round($totalDibayar),
            'sisa'              => (int) round($sisa),
            'status_pembayaran' => $transaksi['status_pembayaran'] ?? 'belum',
            'expired_at'        => $expiredAt === null ? null : MApiTransaksi::iso((string) $expiredAt),
            'payment_detail'    => $detail,
        ];
    }
}
```

- [ ] **Step 6: Daftarkan rute**

Di `app/Config/Routes.php`, dalam group `api/v1` terproteksi, tambah setelah rute permintaan:

```php
    $routes->get('transaksi/(:num)/pembayaran', 'PembayaranController::show/$1');
    $routes->post('transaksi/(:num)/pembayaran', 'PembayaranController::store/$1');
    $routes->post('transaksi/(:num)/pembayaran/batal', 'PembayaranController::batal/$1');
```

Preflight CORS sudah ditanggung rute `options('api/v1/(:any)/(:any)/(:any)')` yang ada
(kedua jalur baru memiliki 5 segmen atau kurang).

- [ ] **Step 7: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PembayaranFlowTest`
Expected: OK (10 test).

- [ ] **Step 8: Jalankan suite API yang sudah ada**

Run: `php vendor/bin/phpunit --filter TransaksiDetailTest`
Expected: OK. Test itu mengecek isi `data` detail transaksi; penambahan field `sisa_tagihan` tidak
boleh merusak assertion yang ada. Kalau pecah, perbaikinya di pihak test baru, jangan ubah
assertion lama.

Jangan jalankan `--testsuite Feature` sebagai gerbang di sini: `TransaksiFeatureTest` bawaan repo
sudah merah 7 failure (lihat baseline Task 3). Kalau mau menjalankan suite Feature penuh,
bandingkan jumlah failure dengan baseline, bukan berharap "OK".

- [ ] **Step 9: Stage + commit**

```bash
git add "app/Controllers/Api/V1/BaseApiController.php" \
        "app/Controllers/Api/V1/TransaksiController.php" \
        "app/Controllers/Api/V1/PembayaranController.php" \
        "app/Models/MApiTransaksi.php" "app/Config/Routes.php" \
        "tests/Feature/Api/PembayaranFlowTest.php"
git commit -m "feat(api): intent pembayaran dari sisi pelanggan"
```

---

## Task 7: Layar kasir "Pesanan Masuk" (konfirmasi → transaksi)

**Files:**
- Create: `app/Controllers/Permintaan.php`
- Create: `app/Views/permintaan/daftar.php`, `app/Views/permintaan/konfirmasi.php`
- Modify: `app/Config/Routes.php`, `app/Views/backend/template/sidebar.php`
- Test: `tests/Feature/PermintaanKonfirmasiTest.php`

**Interfaces:**
- Consumes: `MPermintaanPesanan` (Task 1), `TransaksiService::prosesTransaksiBaru()`,
  `MPelanggan::find()`, `MPermintaanPesanan::finalize()`.
- Produces: rute web `permintaan`, `permintaan/konfirmasi/(:num)`, `permintaan/prosesKonfirmasi`,
  `permintaan/prosesTolak`, dan satu baris transaksi `tb_transaksi` asli per konfirmasi.

- [ ] **Step 1: Tulis test gagal**

Buat `tests/Feature/PermintaanKonfirmasiTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Models\MPermintaanPesanan;
use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use CodeIgniter\Test\FeatureTestTrait;
use Tests\Support\Api\ApiTestTrait;

/**
 * @internal
 */
final class PermintaanKonfirmasiTest extends CIUnitTestCase
{
    use DatabaseTestTrait;
    use FeatureTestTrait;
    use ApiTestTrait;

    protected $migrate     = true;
    protected $migrateOnce = true;
    protected $DBGroup     = 'tests';
    protected $namespace   = null;

    protected function setUp(): void
    {
        parent::setUp();

        $filterConfig = config('Filters');
        $filterConfig->methods = [];
        $filterConfig->globals['before']['csrf'] = ['except' => ['*']];
        \CodeIgniter\Config\Factories::injectMock('config', 'Filters', $filterConfig);
    }

    public function testHalamanDaftarTerbukaUntukKasir(): void
    {
        $this->loginAs('kasir');
        $p = $this->createPelanggan();
        $this->createPermintaan($p);

        $result = $this->call('get', 'permintaan');
        $result->assertOK();
        $result->assertSee('Pesanan Masuk');
    }

    public function testHalamanDaftarDitolakUntukPemilikLevelSalah(): void
    {
        // Spec §9.2 membatasi layar ini ke role admin,kasir. RoleFilter untuk request
        // non-AJAX BUKAN menghasilkan 403: dia set flashdata 'error' lalu redirect()->back().
        // Jadi yang diuji = redirect + flashdata, bukan status code.
        $this->loginAs('pemilik');

        $result = $this->call('get', 'permintaan');
        $result->assertRedirect();
        $this->assertNotEmpty(session()->getFlashdata('error'));
    }

    public function testKonfirmasiMembuatTransaksiLewatJalurKasir(): void
    {
        $this->loginAs('kasir');
        $p       = $this->createPelanggan(['poin' => 0, 'total_transaksi' => 0]);
        $layanan = $this->createLayanan('Kiloan', 7000);
        $req     = $this->createPermintaan($p, ['id_layanan' => $layanan['id_layanan'], 'berat_perkiraan' => 4.0]);
        $idReq   = (int) $req['id_permintaan'];

        // loginAs('kasir') di atas sudah mengisi session lengkap; jangan panggil
        // withSession() lagi (itu akan membuat karyawan kedua dan membatalkan yang pertama).
        $result = $this->post('permintaan/prosesKonfirmasi', [
            'id_permintaan'          => $idReq,
            'berat_actual'           => 5.5,
            'tgl_selesai_estimasi'   => date('Y-m-d H:i:s', strtotime('+2 days')),
            'poin_ditebus'           => 0,
        ]);

        $result->assertRedirect();

        $model = new MPermintaanPesanan();
        $permintaan = $model->find((int) $idReq);
        $this->assertSame('dikonfirmasi', $permintaan['status']);
        $this->assertNotNull($permintaan['id_transaksi']);

        $trx = db_connect('tests')->table('tb_transaksi')
            ->where('id_transaksi', $permintaan['id_transaksi'])->get()->getRowArray();

        $this->assertSame((int) $p['id_pelanggan'], (int) $trx['id_pelanggan']);
        $this->assertSame(5.5, (float) $trx['total_berat']);
        $this->assertSame(38500, (int) round((float) $trx['grand_total']));
        $this->assertSame(3, (int) $trx['id_status_pembayaran']); // BELUM, uang belum masuk
        $this->assertSame(5.5 * 7000, (float) db_connect('tests')->table('tb_detail_transaksi')
            ->where('id_transaksi', $permintaan['id_transaksi'])->get()->getRowArray()['subtotal']);
    }

    public function testKonfirmasiDuaKaliHanyaMenghasilkanSatuTransaksi(): void
    {
        $this->loginAs('kasir');
        $p       = $this->createPelanggan();
        $layanan = $this->createLayanan();
        $idReq   = (int) $this->createPermintaan($p, ['id_layanan' => $layanan['id_layanan']])['id_permintaan'];

        $sebelum = db_connect('tests')->table('tb_transaksi')->countAllResults();

        $this->post('permintaan/prosesKonfirmasi', ['id_permintaan' => $idReq, 'berat_actual' => 3])
            ->assertRedirect();
        $hasilPertama = db_connect('tests')->table('tb_transaksi')->countAllResults();

        $this->post('permintaan/prosesKonfirmasi', ['id_permintaan' => $idReq, 'berat_actual' => 3])
            ->assertRedirect();
        $hasilKedua = db_connect('tests')->table('tb_transaksi')->countAllResults();

        $this->assertSame($sebelum + 1, $hasilPertama);
        $this->assertSame($hasilPertama, $hasilKedua);
    }

    public function testTolakWajibAlasan(): void
    {
        $this->loginAs('kasir');
        $p     = $this->createPelanggan();
        $idReq = (int) $this->createPermintaan($p)['id_permintaan'];

        $this->post('permintaan/prosesTolak', ['id_permintaan' => $idReq, 'alasan' => ''])
            ->assertRedirect()->assertSession('error');

        $this->assertSame('menunggu', (new MPermintaanPesanan())->find((int) $idReq)['status']);

        $this->post('permintaan/prosesTolak', ['id_permintaan' => $idReq, 'alasan' => 'Outlet penuh hari ini'])
            ->assertRedirect();

        $row = (new MPermintaanPesanan())->find((int) $idReq);
        $this->assertSame('ditolak', $row['status']);
        $this->assertSame('Outlet penuh hari ini', $row['alasan_penolakan']);
    }
}
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

Run: `php vendor/bin/phpunit --filter PermintaanKonfirmasiTest`
Expected: FAIL — rute `permintaan` belum ada.

- [ ] **Step 3: Tulis controller kasir**

Buat `app/Controllers/Permintaan.php`:

```php
<?php

namespace App\Controllers;

use App\Models\MPelanggan;
use App\Models\MPermintaanPesanan;
use App\Services\TransaksiService;
use CodeIgniter\Session\Session;

class Permintaan extends BaseController
{
    /** @var Session */
    protected $session;

    public function __construct()
    {
        $this->session = session();
    }

    public function daftar()
    {
        $model  = new MPermintaanPesanan();
        $filter = (string) ($this->request->getGet('status') ?? 'menunggu');

        // Satu builder untuk kedua tab; yang berbeda cuma predikat statusnya.
        // `db_connect()` dipakai langsung karena controller kasir di repo ini memang
        // pakai pola itu (lihat Webhook.php:45) — CI4 BaseController tidak punya $this->db().
        $rows = db_connect()->table('tb_permintaan_pesanan p')
            ->select('p.*, l.nama_layanan, l.harga_per_kg, pl.nama_pelanggan, pl.no_telp, pl.alamat')
            ->join('tb_layanan l', 'l.id_layanan = p.id_layanan', 'left')
            ->join('tb_pelanggan pl', 'pl.id_pelanggan = p.id_pelanggan', 'left');

        if ($filter === 'riwayat') {
            $rows = $rows->whereIn('p.status', ['dikonfirmasi', 'ditolak', 'dibatalkan']);
        } else {
            $filter = 'menunggu';
            // Tab "menunggu" ikut menampilkan `diproses`: itu baris yang klaimnya menggantung
            // (kasir klik tapi insert gagal). Kalau tidak, baris itu hilang dari kedua tab.
            $rows   = $rows->whereIn('p.status', [MPermintaanPesanan::MENUNGGU, MPermintaanPesanan::DIPROSES]);
        }

        $data = [
            'permintaan'    => $rows->orderBy('p.id_permintaan', 'DESC')->limit(200)->get()->getResultArray(),
            'status'        => $filter,
            'menungguCount' => $model->where('status', MPermintaanPesanan::MENUNGGU)->countResults(),
            'activeMenu'    => 'permintaan',
        ];

        return view('permintaan/daftar', $data);
    }

    public function konfirmasi($id = null)
    {
        $model = new MPermintaanPesanan();
        $row   = $model->find((int) $id);

        if ($row === null) {
            return redirect()->to('/permintaan')->with('error', 'Permintaan tidak ditemukan.');
        }

        $pelanggan = (new MPelanggan())->find((int) $row['id_pelanggan']);

        return view('permintaan/konfirmasi', [
            'permintaan' => $row,
            'pelanggan'  => $pelanggan,
            'activeMenu' => 'permintaan',
        ]);
    }

    public function prosesKonfirmasi()
    {
        $idPermintaan = (int) $this->request->getPost('id_permintaan');
        $beratActual  = (float) $this->request->getPost('berat_actual');
        $idKasir      = (int) $this->session->get('id_karyawan');
        $model        = new MPermintaanPesanan();

        $permintaan = $model->find($idPermintaan);

        if ($permintaan === null) {
            return redirect()->to('/permintaan')->with('error', 'Permintaan tidak ditemukan.');
        }

        if ($beratActual <= 0 || $beratActual > 100) {
            return redirect()->back()->withInput()->with('error', 'Berat actual harus antara 0.1 dan 100 kg.');
        }

        // Klaim lebih dulu. Kalau dua kasir klik bersamaan, yang kalah berhenti di sini dan
        // tidak membuat transaksi kedua. Risikonya (permintaan jadi `diproses` lalu insert
        // gagal) lebih murah daripada nota ganda: kasir masih bisa buat transaksi manual.
        if (! $model->claimUntukDiproses($idPermintaan, (int) $permintaan['id_pelanggan'])) {
            return redirect()->to('/permintaan')->with('error', 'Permintaan sudah diproses kasir lain.');
        }

        $model->assignKasir($idPermintaan, $idKasir);

        $pelanggan = (new MPelanggan())->find((int) $permintaan['id_pelanggan']);

        $hasil = (new TransaksiService())->prosesTransaksiBaru(
            [
                'tgl_selesai_estimasi' => $this->request->getPost('tgl_selesai_estimasi')
                    ?: date('Y-m-d H:i:s', strtotime('+2 days')),
                'poin_ditebus'         => (int) ($this->request->getPost('poin_ditebus') ?? 0),
            ],
            $idKasir,
            [['id_layanan' => (int) $permintaan['id_layanan'], 'berat' => $beratActual]],
            $pelanggan
        );

        if (! ($hasil['success'] ?? false)) {
            // Kembalikan klaim supaya kasir bisa mencoba lagi.
            $model->update($idPermintaan, ['status' => MPermintaanPesanan::MENUNGGU, 'dikonfirmasi_oleh' => null]);

            return redirect()->back()->withInput()->with('error', $hasil['message'] ?? 'Gagal membuat transaksi.');
        }

        $ditutup = $model->finalize(
            $idPermintaan,
            MPermintaanPesanan::DIKONFIRMASI,
            (int) $hasil['id_transaksi'],
            $idKasir
        );

        if (! $ditutup) {
            log_message('error', 'Permintaan ' . $idPermintaan . ' terkonfirmasi tapi finalize gagal; id_transaksi='
                . $hasil['id_transaksi']);
        }

        return redirect()->to('/transaksi/detail/' . $hasil['id_transaksi'])
            ->with('success', 'Permintaan dikonfirmasi. Nota ' . $hasil['id_transaksi'] . ' dibuat.');
    }

    public function prosesTolak()
    {
        $idPermintaan = (int) $this->request->getPost('id_permintaan');
        $alasan       = trim((string) $this->request->getPost('alasan'));
        $model        = new MPermintaanPesanan();

        if ($alasan === '') {
            return redirect()->back()->withInput()->with('error', 'Alasan penolakan wajib diisi.');
        }

        $permintaan = $model->find($idPermintaan);

        if ($permintaan === null) {
            return redirect()->to('/permintaan')->with('error', 'Permintaan tidak ditemukan.');
        }

        if (! $model->claimUntukDiproses($idPermintaan, (int) $permintaan['id_pelanggan'])) {
            return redirect()->to('/permintaan')->with('error', 'Permintaan sudah diproses kasir lain.');
        }

        $idKasir = (int) $this->session->get('id_karyawan');
        // finalize() menuntut dikonfirmasi_oleh = $idKasir, jadi klaim kasirnya dulu —
        // sama seperti jalur konfirmasi.
        $model->assignKasir($idPermintaan, $idKasir);

        $model->finalize(
            $idPermintaan,
            MPermintaanPesanan::DITOLAK,
            null,
            $idKasir,
            mb_substr($alasan, 0, 255)
        );

        return redirect()->to('/permintaan')->with('success', 'Permintaan ditolak.');
    }
}
```

- [ ] **Step 4: Tulis dua view**

Buat `app/Views/permintaan/daftar.php` mengikuti pola `app/Views/transaksi/daftar.php`
(extend `backend/template/layout`, section `content`, `card card-outline card-primary shadow-sm border-0`):

```php
<?= $this->extend('backend/template/layout') ?>
<?= $this->section('content') ?>

<div class="row">
    <div class="col-12">
        <div class="card card-outline card-primary shadow-sm border-0">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h3 class="card-title m-0">Pesanan Masuk</h3>
                <ul class="nav nav-pills card-header-pills">
                    <li class="nav-item">
                        <a class="nav-link <?= $status === 'menunggu' ? 'active' : '' ?>"
                           href="<?= base_url('/permintaan?status=menunggu') ?>">
                            Menunggu <span class="badge bg-warning text-dark"><?= (int) $menungguCount ?></span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?= $status === 'riwayat' ? 'active' : '' ?>"
                           href="<?= base_url('/permintaan?status=riwayat') ?>">Riwayat</a>
                    </li>
                </ul>
            </div>
            <div class="card-body p-0">
                <?php if ($permintaan === []): ?>
                    <p class="text-center text-muted py-5 m-0">Tidak ada permintaan jemput.</p>
                <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Nota/ID</th><th>Pelanggan</th><th>Layanan</th>
                                <th>Perkiraan</th><th>Jemput</th><th>Status</th><th class="text-end">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($permintaan as $row): ?>
                            <tr>
                                <td><?= (int) $row['id_permintaan'] ?></td>
                                <td>
                                    <div><?= esc($row['nama_pelanggan']) ?></div>
                                    <small class="text-muted"><?= esc($row['no_telp']) ?></small>
                                </td>
                                <td><?= esc($row['nama_layanan']) ?></td>
                                <td>
                                    <div><?= esc(number_format((float) $row['berat_perkiraan'], 1)) ?> kg</div>
                                    <small class="text-muted">
                                        estimasi Rp<?= esc(number_format((float) $row['harga_per_kg'] * (float) $row['berat_perkiraan'], 0, ',', '.')) ?>
                                    </small>
                                </td>
                                <td>
                                    <div><?= esc(date('d/m/Y H:i', strtotime((string) $row['tgl_jemput']))) ?></div>
                                    <small class="text-muted">slot <?= esc($row['slot_jemput']) ?></small>
                                    <div><small class="text-muted"><?= esc($row['alamat_jemput']) ?></small></div>
                                </td>
                                <td>
                                    <?php
                                    $lencana = [
                                        'menunggu' => 'warning', 'diproses' => 'info',
                                        'dikonfirmasi' => 'success', 'ditolak' => 'danger',
                                        'dibatalkan' => 'secondary',
                                    ][$row['status']] ?? 'secondary';
                                    ?>
                                    <span class="badge bg-<?= $lencana ?>"><?= esc(ucfirst($row['status'])) ?></span>
                                </td>
                                <td class="text-end">
                                    <?php if (in_array($row['status'], ['menunggu', 'diproses'], true)): ?>
                                        <a class="btn btn-primary btn-sm"
                                           href="<?= base_url('/permintaan/konfirmasi/' . $row['id_permintaan']) ?>">Konfirmasi</a>
                                        <form method="post" class="d-inline" id="tolak-<?= (int) $row['id_permintaan'] ?>"
                                              action="<?= base_url('/permintaan/prosesTolak') ?>">
                                            <?= csrf_field() ?>
                                            <input type="hidden" name="id_permintaan" value="<?= (int) $row['id_permintaan'] ?>">
                                            <input type="hidden" name="alasan" value="">
                                            <button type="button" class="btn btn-outline-danger btn-sm"
                                                    onclick="tolakPermintaan(<?= (int) $row['id_permintaan'] ?>)">Tolak</button>
                                        </form>
                                    <?php elseif ($row['id_transaksi'] !== null): ?>
                                        <a class="btn btn-link btn-sm p-0"
                                           href="<?= base_url('/transaksi/detail/' . $row['id_transaksi']) ?>">Lihat nota</a>
                                    <?php else: ?>
                                        <span class="text-muted small">-</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<script>
    function tolakPermintaan(id) {
        const alasan = prompt('Alasan menolak permintaan #' + id + ':');
        if (alasan === null) return;
        if (alasan.trim() === '') {
            alert('Alasan wajib diisi.');
            return;
        }
        document.getElementById('tolak-' + id).alasan.value = alasan.trim();
        document.getElementById('tolak-' + id).submit();
    }
</script>
```

Layout backend hanya punya satu section (`content`, lihat `app/Views/backend/template/layout.php:4`),
jadi `<script>` di atas memang ditaruh setelah `endSection()` seperti view transaksi lama — jangan
mencoba `section('script')`.

Validasi `alasan` wajib tetap ada di server (`prosesTolak()`): `testTolakWajibAlasan` menembak
route itu langsung dengan `alasan` kosong, jadi JS di atas cuma UX, bukan satu-satunya penjaga.

Buat `app/Views/permintaan/konfirmasi.php`:

```php
<?= $this->extend('backend/template/layout') ?>
<?= $this->section('content') ?>

<div class="row">
    <div class="col-12 col-lg-8">
        <div class="card card-outline card-primary shadow-sm border-0">
            <div class="card-header"><h3 class="card-title m-0">Konfirmasi Permintaan #<?= (int) $permintaan['id_permintaan'] ?></h3></div>
            <div class="card-body">
                <dl class="row mb-4">
                    <dt class="col-sm-4">Pelanggan</dt>
                    <dd class="col-sm-8"><?= esc($pelanggan['nama_pelanggan']) ?> (<?= esc($pelanggan['no_telp']) ?>)</dd>
                    <dt class="col-sm-4">Alamat jemput</dt>
                    <dd class="col-sm-8"><?= esc($permintaan['alamat_jemput']) ?></dd>
                    <dt class="col-sm-4">Jadwal</dt>
                    <dd class="col-sm-8"><?= esc(date('d/m/Y', strtotime((string) $permintaan['tgl_jemput']))) ?> · slot <?= esc($permintaan['slot_jemput']) ?></dd>
                    <dt class="col-sm-4">Layanan</dt>
                    <dd class="col-sm-8"><?= esc($permintaan['catatan'] ?: 'Tanpa catatan') ?></dd>
                    <dt class="col-sm-4">Perkiraan pelanggan</dt>
                    <dd class="col-sm-8"><?= esc(number_format((float) $permintaan['berat_perkiraan'], 1)) ?> kg</dd>
                </dl>

                <form method="post" action="<?= base_url('/permintaan/prosesKonfirmasi') ?>">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id_permintaan" value="<?= (int) $permintaan['id_permintaan'] ?>">

                    <div class="row g-3">
                        <div class="col-12 col-md-4">
                            <label class="form-label">Berat actual (kg)</label>
                            <input type="number" step="0.1" min="0.1" max="100" name="berat_actual" class="form-control"
                                   value="<?= esc($this->request->getPost('berat_actual')) ?>" required>
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label">Estimasi selesai</label>
                            <input type="datetime-local" name="tgl_selesai_estimasi" class="form-control"
                                   value="<?= esc(date('Y-m-d\TH:i', strtotime('+2 days'))) ?>">
                        </div>
                        <div class="col-12 col-md-4">
                            <label class="form-label">Poin ditebus</label>
                            <input type="number" min="0" max="<?= (int) ($pelanggan['poin'] ?? 0) ?>" name="poin_ditebus"
                                   class="form-control" value="0">
                            <small class="text-muted">Tersedia <?= (int) ($pelanggan['poin'] ?? 0) ?> poin</small>
                        </div>
                    </div>

                    <div class="mt-4 d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Simpan &amp; Buat Nota</button>
                        <a href="<?= base_url('/permintaan') ?>" class="btn btn-outline-secondary">Batal</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>
```

- [ ] **Step 5: Daftarkan rute web**

Di `app/Config/Routes.php`, setelah group `layanan`, tambah:

```php
// Permintaan jemput dari app pelanggan
$routes->group('permintaan', ['filter' => 'role:admin,kasir'], static function ($routes) {
    $routes->get('/', 'Permintaan::daftar');
    $routes->get('konfirmasi/(:num)', 'Permintaan::konfirmasi/$1');
    $routes->post('prosesKonfirmasi', 'Permintaan::prosesKonfirmasi');
    $routes->post('prosesTolak', 'Permintaan::prosesTolak');
});
```

- [ ] **Step 6: Tambah menu sidebar**

Di `app/Views/backend/template/sidebar.php`, salin persis blok `<li class="nav-item">` milik
`daftar_transaksi` (baris 43-48) lalu ganti empat isinya. Jangan tambahkan badge jumlah menunggu:
sidebar tidak punya akses model, dan menaruh `\App\Models\...::where(...)->countResults()` di view
adalah query tersembunyi di setiap render halaman backend.

```php
                <li class="nav-item">
                    <a href="<?= base_url('/permintaan') ?>" class="nav-link <?= ($activeMenu ?? '') == 'permintaan' ? 'active' : '' ?>">
                        <i class="nav-icon fas fa-inbox"></i>
                        <p>Pesanan Masuk</p>
                    </a>
                </li>
```

Sisipkan tepat setelah blok `daftar_transaksi` itu, masih di dalam `<ul>` yang sama (sebelum
`<li class="nav-header pt-3">MASTER DATA</li>`), dan ikut di dalam kondisi role yang sama dengan
blok transaksi kalau blok tersebut dibungkus `<?php if ... endif; ?>`.

- [ ] **Step 7: Jalankan test, pastikan hijau**

Run: `php vendor/bin/phpunit --filter PermintaanKonfirmasiTest`
Expected: OK (5 test).

- [ ] **Step 8: Jalankan seluruh suite, bandingkan dengan baseline**

Run: `php vendor/bin/phpunit 2>&1 | tail -6`
Expected: `Failures` tidak lebih dari baseline Task 3 Step 0 (`TransaksiFeatureTest` = 7 failure
sebelum Task mana pun dimulai). Target gerbang ini: **tidak menambah failure baru**, bukan
"suite hijau". Catat angka final di pesan commit supaya reviewer bisa membandingkan sendiri.
Kalau angka failure naik, `git stash` perubahan terakhir satu per satu sampai ketemu penyebabnya.

- [ ] **Step 9: Stage + commit**

```bash
git add "app/Controllers/Permintaan.php" "app/Views/permintaan/daftar.php" \
        "app/Views/permintaan/konfirmasi.php" "app/Config/Routes.php" \
        "app/Views/backend/template/sidebar.php" "tests/Feature/PermintaanKonfirmasiTest.php"
git commit -m "feat(web): layar pesanan masuk untuk kasir konfirmasi permintaan jemput"
```

---

## Task 8: Dokumentasi kontrak API + salin ke repo app

**Files:**
- Modify: `docs/api/sparkleen-mobile-v1.md` (repo backend)
- Modify: `docs/api/sparkleen-mobile-v1.postman_collection.json` (repo backend)
- Modify: `docs/api/sparkleen-mobile-v1.md` (repo app, hasil salinan)

**Interfaces:**
- Consumes: bentuk JSON final dari Task 4-6.
- Produces: dokumen yang dibaca Plan B (Flutter) sebagai kontrak.

- [ ] **Step 1: Tambah bagian endpoint**

Di `docs/api/sparkleen-mobile-v1.md`, setelah seksi `### GET /transaksi/{id}/nota`,
tambah dokumentasi untuk setiap endpoint baru dengan skema request + response + kode error,
memakai gaya yang sudah dipakai di file itu (tabel field + contoh JSON):

- `POST /permintaan` — field `id_layanan`, `berat_perkiraan`, `alamat_jemput`, `tgl_jemput`
  (`YYYY-MM-DD`), `slot_jemput` (`pagi|siang|sore`), `catatan?`. Balasan 201 bentuk
  `permintaan`. Error: `VALIDATION_ERROR` 422, `ACTIVE_REQUEST_EXISTS` 409.
- `GET /permintaan` — query `status` (`aktif|selesai|semua`), `page`, `per_page`, meta sama
  seperti `/transaksi`.
- `GET /permintaan/{id}` — 404 `NOT_FOUND` bila bukan milik pelanggan.
- `POST /permintaan/{id}/batal` — 200, atau 409 `CANNOT_CANCEL`.
- `GET /transaksi/{id}` — sekarang juga mengembalikan `sisa_tagihan` (int rupiah).
- `POST /transaksi/{id}/pembayaran` — body `{metode}`; 201 intent baru, 200 idempoten metode
  sama; error `ALREADY_PAID`, `CONFLICT_METHOD`, `PAYMENT_API_UNAVAILABLE`.
- `GET /transaksi/{id}/pembayaran` — status `NONE|PENDING|EXPIRED|SUCCESS`; dibaca dari DB
  lokal saja.
- `POST /transaksi/{id}/pembayaran/batal` — 200 atau 409 `NO_ACTIVE_PAYMENT`.

Tambahkan juga catatan di seksi `## Kode error` untuk semua `code` baru di atas, dan satu
paragraf "Cara intent jadi lunas" yang menjelaskan webhook adalah satu-satunya penulis
`tb_pembayaran`, sehingga app tidak punya tombol "sudah bayar".

- [ ] **Step 2: Perbarui Postman collection**

Tambahkan folder "Permintaan" dan "Pembayaran" ke
`docs/api/sparkleen-mobile-v1.postman_collection.json` dengan satu request per endpoint di
Step 1, masing-masing punya contoh body JSON. Validasi:

Run: `php -r "var_dump(json_decode(file_get_contents('docs/api/sparkleen-mobile-v1.postman_collection.json')) !== null);"`
Expected: `bool(true)`

- [ ] **Step 3: Salin ke repo app**

```bash
cp docs/api/sparkleen-mobile-v1.md "/c/Users/R/Documents/@Semester 5/sparkleen_mobile_pelanggan/docs/api/sparkleen-mobile-v1.md"
cp docs/api/sparkleen-mobile-v1.postman_collection.json "/c/Users/R/Documents/@Semester 5/sparkleen_mobile_pelanggan/docs/api/sparkleen-mobile-v1.postman_collection.json"
```

Kedua repo menyimpan salinan dokumen yang sama; Plan B membaca yang ada di repo app.

- [ ] **Step 4: Stage + commit (dua repo)**

```bash
git add "docs/api/sparkleen-mobile-v1.md" "docs/api/sparkleen-mobile-v1.postman_collection.json"
git commit -m "docs(api): kontrak permintaan jemput dan pembayaran online"

cd "/c/Users/R/Documents/@Semester 5/sparkleen_mobile_pelanggan"
git add "docs/api/sparkleen-mobile-v1.md" "docs/api/sparkleen-mobile-v1.postman_collection.json"
git commit -m "docs(api): salinan kontrak permintaan dan pembayaran"
```

---

## Verifikasi Manual Sebelum Dianggap Selesai

Gw tidak menganggap task selesai dari test saja; alur bayar harus dibuktikan hidup.

- [ ] **Step 1: Kunci callback lokal**

Sebelum menyalakan apa pun yang menyentuh Node, pastikan `CALLBACK_URL` tidak menunjuk
produksi. Cek dari repo `C:\xampp\htdocs\payment_api`:

Run: `grep -n "CALLBACK_URL" .env src/db/index.js`
Expected: `.env` berisi `CALLBACK_URL=http://127.0.0.1:8082/webhook/payment`. Kalau kosong,
tulis dulu. Default di `src/db/index.js:28` adalah `https://sparkleen.rachmatx.me/...` —
domain produksi, dan menyalakan webhook ke sana akan mencatat pembayaran ke DB live.

- [ ] **Step 2: Nyalakan kedua server**

```bash
# Node payment API
cd /c/xampp/htdocs/payment_api && npm start

# Backend CI4 di port 8082 (DB test), dengan trik auto_prepend yang sudah terbukti
cd "/c/Users/R/Documents/@Tugas kampus semester 4/Pemrograman Web/Sparkleen Laundry/sparkleen-laundry"
CI_ENVIRONMENT=testing php -S 127.0.0.1:8082 -t public vendor/codeigniter4/framework/system/rewrite.php
```

- [ ] **Step 3: Siapkan token pelanggan**

Semua request app butuhBearer token dari `POST /api/v1/auth/login`. Ambil pelanggan yang sudah
ada di `laundry_db_test` (atau buat lewat layar daftar pelanggan web) dan pakai PIN-nya:

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8082/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"no_telp":"<no_telp pelanggan>","pin":"123456"}' \
  | php -r 'echo json_decode(stream_get_contents(STDIN), true)["data"]["token"] ?? "";')
echo "$TOKEN"
```
Expected: string token tidak kosong. Kalau kosong, cetak whole response-nya dulu — jangan lanjut
dengan token kosong.

- [ ] **Step 4: Tempur lewat curl, bukan cuma test**

```bash
# 1. buat permintaan (id_layanan diambil dari tb_layanan di DB test)
curl -s -X POST http://127.0.0.1:8082/api/v1/permintaan \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"id_layanan":1,"berat_perkiraan":4,"alamat_jemput":"Jl. Melati 7","tgl_jemput":"2026-10-26","slot_jemput":"siang"}'

# 2. buka http://127.0.0.1:8082/permintaan di Chrome (login kasir) → Konfirmasi, berat actual 4.0
#    Catat id_transaksi dari URL hasil redirect (/transaksi/detail/<id>).
ID_TRX=<id dari langkah 2>

# 3. buat intent dari sisi pelanggan
curl -s -X POST http://127.0.0.1:8082/api/v1/transaksi/$ID_TRX/pembayaran \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"metode":"QRIS"}'

# 4. baca status → harus PENDING, payment_detail.qris_data terisi
curl -s http://127.0.0.1:8082/api/v1/transaksi/$ID_TRX/pembayaran -H "Authorization: Bearer $TOKEN"

# 5. simulasi pembayar menutup QRIS: endpoint confirm sisi merchant di Node API.
#    Ini BUKAN jalur "app menyatakan lunas"; ini yang memicu webhook, sama seperti kasir
#    memverifikasi transfer di dunia nyata.
REF=<transaction_id dari langkah 3>
curl -s -X POST http://127.0.0.1:3000/api/transactions/$REF/confirm \
  -H "X-Api-Key: $(grep -o 'API_KEY=.*' /c/xampp/htdocs/payment_api/.env | cut -d= -f2)"

# 6. baca lagi
curl -s http://127.0.0.1:8082/api/v1/transaksi/$ID_TRX/pembayaran -H "Authorization: Bearer $TOKEN"
```

Expected: langkah 6 berubah dari `PENDING` menjadi `SUCCESS` dengan `sisa` nol setelah webhook
masuk, dan hanya ada **satu** baris baru di `tb_pembayaran`. `sendCallback()` di Node
fire-and-forget, jadi kasih jeda ~2 detik antara langkah 5 dan 6; kalau masih `PENDING`, cek
`WRITEPATH . logs` backend dulu sebelum menyimpulkan alurnya rusak.

- [ ] **Step 4: Matikan server yang dinyalakan sendiri**

Node API dan `php -S` dimatikan setelah verifikasi. Jangan ditinggal jalan.

## Catatan Urutan Pengerjaan

Task 1 → 2 → 3 wajib berurutan (model dipakai service, service dipakai refactor kasir yang
harus tetap hijau). Task 4 → 5 berurutan. Task 6 butuh 2 dan 3. Task 7 butuh 1 dan 3.
Task 8 paling akhir. Setelah plan ini selesai, tulis **Plan B (Flutter)** yang mengonsumsi
dokumentasi dari Task 8; jangan mulai UI app sebelum kontraknya stabil.
