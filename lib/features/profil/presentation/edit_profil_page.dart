import '../../../core/theme/app_icons.dart';

import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_text_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/validators.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';

class EditProfilPage extends ConsumerStatefulWidget {
  const EditProfilPage({super.key});

  @override
  ConsumerState<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends ConsumerState<EditProfilPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final String _noTelp;
  ApiException? _serverError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pelanggan = switch (ref.read(authControllerProvider).value) {
      AuthAuthenticated(:final pelanggan) => pelanggan,
      _ => null,
    };
    _nama = TextEditingController(text: pelanggan?.nama ?? '');
    _noTelp = pelanggan?.noTelp ?? '';
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (_serverError != null) setState(() => _serverError = null);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(nama: _nama.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _serverError = error);
      _formKey.currentState?.validate();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _serverError = const ApiException(
          code: 'UNKNOWN',
          message: 'Gagal menyimpan profil. Silakan coba lagi.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _nama.text.trim();
    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ubah profil')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        name.isEmpty
                            ? '?'
                            : name.characters.first.toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi akun',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pastikan data penjemputanmu sesuai.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_serverError != null) ...[
                  AuthErrorBanner(message: _serverError!.message),
                  const SizedBox(height: 16),
                ],
                AppTextFormField(
                  controller: _nama,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(AppIcons.person_outline_rounded),
                  ),
                  validator: (value) =>
                      _serverError?.fieldError('nama') ?? validateNama(value),
                  onChanged: (_) => _clearServerError(),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.location_on_outlined),
                  title: const Text('Alamat penjemputan'),
                  trailing: const Icon(AppIcons.chevron_right_rounded),
                  onTap: _saving ? null : () => context.push('/alamat'),
                ),
                const SizedBox(height: 24),
                AppTextFormField(
                  initialValue: _noTelp,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon',
                    prefixIcon: Icon(AppIcons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hubungi outlet untuk mengubah nomor telepon.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Simpan',
                  loading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
