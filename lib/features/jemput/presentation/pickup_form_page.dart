import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_artwork.dart';
import '../../../core/theme/app_assets.dart';

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
  DateTime _date = jakartaCalendarDate(daysAfter: 1);
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
    final today = jakartaCalendarDate();
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
    final items = services.value ?? <Layanan>[];
    final matching = items.where((item) => item.id == _serviceId);
    final chosen = matching.isEmpty ? null : matching.first;
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    final estimate =
        chosen != null &&
            weight != null &&
            weight.isFinite &&
            weight >= .1 &&
            weight <= 100
        ? (chosen.hargaPerKg * weight).round()
        : null;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.labelLarge),
    );
    final dateField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('Tanggal jemput'),
        OutlinedButton.icon(
          onPressed: _busy ? null : _chooseDate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(
            formatTanggalSingkat(_date),
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (_error?.fieldError('tgl_jemput') case final String error)
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
      ],
    );
    final slotField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('Slot waktu'),
        DropdownButtonFormField<String>(
          style: theme.textTheme.bodyMedium,
          initialValue: _slot,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          ),
          items: const [
            DropdownMenuItem(value: 'pagi', child: Text('Pagi · 08.00')),
            DropdownMenuItem(value: 'siang', child: Text('Siang · 12.00')),
            DropdownMenuItem(value: 'sore', child: Text('Sore · 15.00')),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _slot = value!;
                  _error = null;
                }),
        ),
      ],
    );
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajukan penjemputan')),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pilih jadwal yang cocok untukmu.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                Text('Cucianmu', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            label('Layanan'),
                            AsyncValueView<List<Layanan>>(
                              value: services,
                              onRetry: () => ref.invalidate(layananProvider),
                              isEmpty: (items) => items.isEmpty,
                              emptyBuilder: (_) => const Text(
                                'Layanan belum tersedia. Coba lagi nanti.',
                              ),
                              builder: (context, items) =>
                                  DropdownButtonFormField<int>(
                                    style: theme.textTheme.bodyMedium,
                                    key: ValueKey(
                                      'pickup-services-${items.map((item) => item.id).join('-')}',
                                    ),
                                    initialValue:
                                        items.any(
                                          (item) => item.id == _serviceId,
                                        )
                                        ? _serviceId
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Pilih layanan',
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
                                            ? 'Pilih layanan.'
                                            : null),
                                  ),
                            ),
                            const SizedBox(height: 14),
                            AppTextFormField(
                              key: const Key('pickup-weight'),
                              controller: _weight,
                              enabled: !_busy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Perkiraan berat',
                                suffixText: 'kg',
                                helperText: '0,1–100 kg',
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
                      if (MediaQuery.sizeOf(context).width >= 370 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 17) ...[
                        const SizedBox(width: 8),
                        AppArtwork(
                          asset: chosen == null
                              ? AppAssets.cuciSetrika
                              : (AppAssets.serviceArtwork(name: chosen.nama) ??
                                    AppAssets.home),
                          width: 100,
                          height: 100,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Lokasi & jadwal', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        key: const Key('pickup-address'),
                        controller: _address,
                        enabled: !_busy,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Alamat lengkap',
                        ),
                        onChanged: (_) => _changed(),
                        validator: (value) =>
                            _error?.fieldError('alamat_jemput') ??
                            ((value?.trim().length ?? 0) < 10
                                ? 'Lengkapi alamat, minimal 10 karakter.'
                                : null),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth < 280 ||
                                MediaQuery.textScalerOf(context).scale(14) > 18
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dateField,
                                  const SizedBox(height: 14),
                                  slotField,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: dateField),
                                  const SizedBox(width: 10),
                                  Expanded(child: slotField),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'WIB · Waktu dikonfirmasi outlet.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: AppTextFormField(
                    key: const Key('pickup-note'),
                    controller: _note,
                    enabled: !_busy,
                    maxLength: 255,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Petunjuk lokasi atau detail cucian',
                    ),
                    onChanged: (_) => _changed(),
                    validator: (_) => _error?.fieldError('catatan'),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Perkiraan biaya',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            estimate == null
                                ? 'Belum dihitung'
                                : formatRupiah(estimate),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Biaya akhir mengikuti berat aktual di outlet.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _error!.message,
                      key: const Key('pickup-error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Kirim permintaan jemput',
                  loading: _busy,
                  onPressed: services.hasValue && items.isNotEmpty
                      ? _submit
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
