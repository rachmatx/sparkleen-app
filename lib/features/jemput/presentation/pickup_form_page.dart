import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/application/auth_controller.dart';
import '../../home/application/home_providers.dart';
import '../../home/data/layanan.dart';
import '../application/pickup_controller.dart';

class PickupFormPage extends ConsumerStatefulWidget {
  const PickupFormPage({super.key});
  @override
  ConsumerState<PickupFormPage> createState() => _PickupFormPageState();
}

class _PickupFormPageState extends ConsumerState<PickupFormPage> {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _note = TextEditingController();
  late final TextEditingController _address;
  int? _serviceId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _slot = 'siang';
  bool _busy = false;
  ApiException? _error;
  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider).value;
    _address = TextEditingController(
      text: auth is AuthAuthenticated ? auth.pelanggan.alamat : '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    _address.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _error = null);
  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_form.currentState!.validate() || _busy) return;
    final revision = ref.read(customerSessionRevisionProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(pickupRepositoryProvider)
          .create(
            serviceId: _serviceId!,
            weight: double.parse(_weight.text.replaceAll(',', '.')),
            address: _address.text.trim(),
            date: DateFormat('yyyy-MM-dd').format(_date),
            slot: _slot,
            note: _note.text.trim(),
          );
      if (!mounted || revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      ref.invalidate(pickupControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan jemput terkirim. Tunggu konfirmasi outlet.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted || revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      setState(() => _error = error);
      _form.currentState?.validate();
      if (error.code == 'ACTIVE_REQUEST_EXISTS') {
        ref.invalidate(pickupControllerProvider);
      }
    } catch (_) {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        setState(
          () => _error = const ApiException(
            code: 'UNKNOWN',
            message: 'Permintaan belum terkirim. Silakan coba lagi.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Pilih tanggal jemput',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (chosen != null && mounted) {
      setState(() {
        _date = chosen;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = ref.watch(layananProvider);
    final chosen = services.value
        ?.where((item) => item.id == _serviceId)
        .firstOrNull;
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajukan penjemputan')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Jadwal yang cocok untukmu',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Alamat dan nomor telepon akun akan digunakan outlet untuk mengatur penjemputan.',
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(
                    _error!.message,
                    style: TextStyle(color: theme.colorScheme.error),
                    key: const Key('pickup-error'),
                  ),
                  const SizedBox(height: 12),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Layanan & perkiraan cucian',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      AsyncValueView<List<Layanan>>(
                        value: services,
                        onRetry: () => ref.invalidate(layananProvider),
                        isEmpty: (items) => items.isEmpty,
                        emptyBuilder: (_) => const Text(
                          'Layanan belum tersedia. Coba lagi nanti.',
                        ),
                        builder: (context, items) => DropdownButtonFormField<int>(
                          key: ValueKey(
                            'pickup-services-${items.map((item) => item.id).join('-')}',
                          ),
                          initialValue:
                              _serviceId != null &&
                                  items.any((item) => item.id == _serviceId)
                              ? _serviceId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Layanan',
                          ),
                          items: items
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.nama,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                  _serviceId = value;
                                  _error = null;
                                }),
                          validator: (value) =>
                              _error?.fieldError('id_layanan') ??
                              (value == null
                                  ? 'Pilih layanan terlebih dahulu.'
                                  : null),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('pickup-weight'),
                        controller: _weight,
                        enabled: !_busy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Perkiraan berat',
                          suffixText: 'kg',
                          helperText:
                              '0,1–100 kg. Akan ditimbang ulang di outlet.',
                        ),
                        onChanged: (_) => _changed(),
                        validator: (value) {
                          final number = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          return _error?.fieldError('berat_perkiraan') ??
                              (number == null ||
                                      !number.isFinite ||
                                      number < .1 ||
                                      number > 100
                                  ? 'Masukkan berat 0,1–100 kg.'
                                  : null);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Alamat & waktu jemput',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('pickup-address'),
                        controller: _address,
                        enabled: !_busy,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Alamat lengkap',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => _changed(),
                        validator: (value) =>
                            _error?.fieldError('alamat_jemput') ??
                            ((value?.trim().length ?? 0) < 10
                                ? 'Lengkapi alamat, minimal 10 karakter.'
                                : null),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _chooseDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(formatTanggalSingkat(_date)),
                      ),
                      if (_error?.fieldError('tgl_jemput')
                          case final String message)
                        Text(
                          message,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _slot,
                        decoration: const InputDecoration(
                          labelText: 'Waktu jemput (WIB)',
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'pagi',
                            child: Text('Pagi · mulai 08.00'),
                          ),
                          DropdownMenuItem(
                            value: 'siang',
                            child: Text('Siang · mulai 12.00'),
                          ),
                          DropdownMenuItem(
                            value: 'sore',
                            child: Text('Sore · mulai 15.00'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() {
                                _slot = value!;
                                _error = null;
                              }),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Waktu ini adalah perkiraan. Outlet akan memastikan ketersediaan penjemputan.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('pickup-note'),
                        controller: _note,
                        enabled: !_busy,
                        maxLength: 255,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (_) => _changed(),
                        validator: (_) => _error?.fieldError('catatan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (chosen != null &&
                    weight != null &&
                    weight.isFinite &&
                    weight >= .1 &&
                    weight <= 100) ...[
                  Text(
                    'Perkiraan ${formatRupiah((chosen.hargaPerKg * weight).round())}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  'Biaya akhir mengikuti berat aktual dan harga layanan saat cucian diterima di outlet.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Kirim permintaan jemput',
                  icon: Icons.local_shipping_outlined,
                  loading: _busy,
                  onPressed:
                      _busy ||
                          services.isLoading ||
                          services.hasError ||
                          (services.value?.isEmpty ?? true)
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
