// Opt-in integration against disposable localhost fixtures only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/core/api/api_config.dart';
import 'package:sparkleen_mobile/core/api/api_exception.dart';
import 'package:sparkleen_mobile/features/alamat/data/address_repository.dart';
import 'package:sparkleen_mobile/features/auth/data/auth_repository.dart';
import 'package:sparkleen_mobile/features/jemput/data/pickup_repository.dart';

import '../test/support/auth_fakes.dart';

void main() {
  testWidgets('real HTTP address CRUD → pickup snapshot → delete → isolation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      if (![
            '127.0.0.1',
            'localhost',
          ].contains(Uri.parse(ApiConfig.baseUrl).host) ||
          Platform.environment['LAUNDRY_TEST_ROOT'] == null) {
        fail('Disposable localhost fixture required.');
      }
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      final storage = FakeTokenStorage();
      final client = ApiClient(tokenStorage: storage);
      final auth = AuthRepository(client, storage);
      final addresses = AddressRepository(client);
      await auth.login(noTelp: '081298765432', pin: '654321');
      final original = (await addresses.list()).items.single;
      await addresses.save(
        label: 'Kos',
        address: 'Jl. Kos Nomor 21, Depok',
        landmark: 'Pagar biru',
        isDefault: true,
      );
      var selected = (await addresses.list()).items.first;
      expect(selected.isDefault, true);
      expect(selected.label, 'Kos');
      expect((await auth.me()).alamat, selected.address);
      await addresses.save(
        id: selected.id,
        label: 'Kantor',
        address: 'Jl. Kantor Nomor 50, Depok',
        landmark: 'Lobi depan',
        isDefault: true,
      );
      selected = await addresses.get(selected.id);
      expect(selected.label, 'Kantor');
      final tomorrow = DateTime.now().toUtc().add(
        const Duration(hours: 7, days: 1),
      );
      final date =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final pickups = PickupRepository(client);
      final request = await pickups.create(
        serviceId: 1,
        weight: 2,
        address: 'Forged address must be ignored',
        addressId: selected.id,
        date: date,
        slot: 'siang',
      );
      expect(request.address, selected.address);
      expect(request.landmark, 'Lobi depan');
      await addresses.delete(selected.id);
      await expectLater(
        addresses.get(selected.id),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
      final snapshot = (await pickups.list()).items.single;
      expect(snapshot.address, selected.address);
      expect(snapshot.landmark, 'Lobi depan');
      final otherStorage = FakeTokenStorage();
      final otherClient = ApiClient(tokenStorage: otherStorage);
      await AuthRepository(otherClient, otherStorage).register(
        nama: 'Pelanggan Lain',
        noTelp: '081277788899',
        alamat: 'Jl. Akun Lain Nomor 10',
        pin: '123456',
      );
      await expectLater(
        AddressRepository(otherClient).delete(original.id),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
      await addresses.delete(original.id);
      expect((await addresses.list()).items, isEmpty);
      expect((await auth.me()).alamat, '');
      await addresses.save(
        label: 'Rumah baru',
        address: 'Jl. Rumah Baru Nomor 12',
        landmark: '',
        isDefault: false,
      );
      expect((await addresses.list()).items.single.isDefault, true);
    });
  });
}
