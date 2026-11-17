import '../../../core/theme/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/application/auth_controller.dart';
import '../application/address_controller.dart';
import '../data/address_repository.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key, this.select = false});
  final bool select;
  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  bool _busy = false;
  Future<void> _edit([CustomerAddress? address]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddressEditPage(initial: address)),
    );
  }

  Future<void> _act(CustomerAddress address, String action) async {
    if (_busy) return;
    if (action == 'edit') {
      await _edit(address);
      return;
    }
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus alamat?'),
          content: Text(
            'Alamat “${address.label}” akan dihapus. Penjemputan yang sudah diajukan tetap memakai alamat semula.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final revision = ref.read(customerSessionRevisionProvider);
    setState(() => _busy = true);
    try {
      final repo = ref.read(addressRepositoryProvider);
      if (action == 'delete') {
        await repo.delete(address.id);
      } else {
        await repo.primary(address.id);
      }
      if (!mounted || revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      await ref.read(addressesProvider.notifier).refresh();
      // The write already committed; profile refresh failure must not invite a duplicate write.
      try {
        await ref.read(authControllerProvider.notifier).refreshMe();
      } catch (_) {}
    } catch (e) {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Alamat belum dapat diperbarui.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.select ? 'Pilih alamat' : 'Alamat saya'),
          actions: [
            IconButton(
              tooltip: 'Tambah alamat',
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(AppIcons.add_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: AsyncValueView<AddressList>(
            value: ref.watch(addressesProvider),
            onRetry: () => ref.read(addressesProvider.notifier).refresh(),
            builder: (context, result) => RefreshIndicator(
              onRefresh: () => ref.read(addressesProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: result.items.isEmpty
                    ? 1
                    : result.items.length +
                          (result.page < result.lastPage ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (result.items.isEmpty) {
                    return AppCard(
                      child: Column(
                        children: [
                          const Icon(AppIcons.location_on_outlined, size: 30),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada alamat',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _edit(),
                            child: const Text('Tambah alamat'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (index == result.items.length) {
                    return TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(addressesProvider.notifier).loadMore();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Alamat berikutnya belum dapat dimuat.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Lihat alamat lainnya'),
                    );
                  }
                  final a = result.items[index];
                  return AppCard(
                    onTap: _busy
                        ? null
                        : () {
                            if (widget.select) {
                              Navigator.pop(context, a);
                            } else {
                              _edit(a);
                            }
                          },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.location_on_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    a.label,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (a.isDefault)
                                    Text(
                                      'Utama',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(a.address),
                              if (a.landmark.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  a.landmark,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Kelola ${a.label}',
                          icon: const Icon(AppIcons.more_horiz),
                          enabled: !_busy,
                          onSelected: (v) => _act(a, v),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Ubah'),
                            ),
                            if (!a.isDefault)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Jadikan utama'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddressEditPage extends ConsumerStatefulWidget {
  const AddressEditPage({super.key, this.initial});
  final CustomerAddress? initial;
  @override
  ConsumerState<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends ConsumerState<AddressEditPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label, _address, _landmark;
  late bool _primary;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initial?.label ?? '');
    _address = TextEditingController(text: widget.initial?.address ?? '');
    _landmark = TextEditingController(text: widget.initial?.landmark ?? '');
    _primary = widget.initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving || !_form.currentState!.validate()) return;
    final revision = ref.read(customerSessionRevisionProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(addressRepositoryProvider)
          .save(
            id: widget.initial?.id,
            label: _label.text.trim(),
            address: _address.text.trim(),
            landmark: _landmark.text.trim(),
            isDefault: _primary,
          );
      if (!mounted || revision != ref.read(customerSessionRevisionProvider)) {
        return;
      }
      await ref.read(addressesProvider.notifier).refresh();
      try {
        await ref.read(authControllerProvider.notifier).refreshMe();
      } catch (_) {}
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && revision == ref.read(customerSessionRevisionProvider)) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Alamat belum tersimpan. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppBackdrop(
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Tambah alamat' : 'Ubah alamat'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextFormField(
                      controller: _label,
                      enabled: !_saving,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        hintText: 'Rumah, kos, atau kantor',
                        counterText: '',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Isi label alamat.' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextFormField(
                      controller: _address,
                      enabled: !_saving,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Alamat lengkap',
                        hintText: 'Jalan, nomor rumah, RT/RW, dan kecamatan',
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().length < 10
                          ? 'Alamat minimal 10 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextFormField(
                      controller: _landmark,
                      enabled: !_saving,
                      maxLength: 255,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Patokan (opsional)',
                        hintText: 'Contoh: pagar biru, sebelah minimarket',
                        counterText: '',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alamat utama'),
                      value: _primary,
                      onChanged: _saving || widget.initial?.isDefault == true
                          ? null
                          : (v) => setState(() => _primary = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan…' : 'Simpan alamat'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
