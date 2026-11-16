import 'dart:async';

import 'package:sparkleen_mobile/core/api/api_client.dart';
import 'package:sparkleen_mobile/features/alamat/data/address_repository.dart';

import '../support/auth_fakes.dart';

CustomerAddress savedAddress({
  int id = 1,
  String label = 'Rumah',
  bool primary = true,
  String? address,
}) => CustomerAddress(
  id: id,
  label: label,
  address: address ?? testPelanggan.alamat,
  landmark: 'Pagar biru',
  isDefault: primary,
);

class FakeAddresses implements AddressRepository {
  @override
  ApiClient get client => throw UnimplementedError();
  List<CustomerAddress> items = [savedAddress()];
  int saves = 0, deletes = 0, primaries = 0;
  int lastPage = 1;
  AddressList? next;
  Object? error;
  Completer<void>? pending;
  @override
  Future<AddressList> list({int page = 1}) async {
    if (error != null) throw error!;
    return page > 1 && next != null
        ? next!
        : AddressList(items: List.of(items), page: page, lastPage: lastPage);
  }

  @override
  Future<CustomerAddress> get(int id) async =>
      items.firstWhere((a) => a.id == id);
  @override
  Future<void> save({
    int? id,
    required String label,
    required String address,
    required String landmark,
    required bool isDefault,
  }) async {
    saves++;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
    id ??= items.fold(0, (int prev, a) => a.id > prev ? a.id : prev) + 1;
    final primary =
        isDefault ||
        items.isEmpty ||
        items.any((a) => a.id == id && a.isDefault);
    items = [
      for (final a in items)
        if (a.id != id)
          CustomerAddress(
            id: a.id,
            label: a.label,
            address: a.address,
            landmark: a.landmark,
            isDefault: primary ? false : a.isDefault,
          ),
      CustomerAddress(
        id: id,
        label: label,
        address: address,
        landmark: landmark,
        isDefault: primary,
      ),
    ];
  }

  @override
  Future<void> primary(int id) async {
    primaries++;
    if (error != null) throw error!;
    items = [
      for (final a in items)
        CustomerAddress(
          id: a.id,
          label: a.label,
          address: a.address,
          landmark: a.landmark,
          isDefault: a.id == id,
        ),
    ];
  }

  @override
  Future<void> delete(int id) async {
    deletes++;
    if (error != null) throw error!;
    items = items.where((a) => a.id != id).toList();
    if (items.isNotEmpty && !items.any((a) => a.isDefault)) {
      await primary(items.first.id);
    }
  }
}
