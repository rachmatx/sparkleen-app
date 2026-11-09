import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
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
  late final TextEditingController _alamat;
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
    _alamat = TextEditingController(text: pelanggan?.alamat ?? '');
    _noTelp = pelanggan?.noTelp ?? '';
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
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
          .updateProfile(nama: _nama.text.trim(), alamat: _alamat.text.trim());
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

    return AppBackdrop(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ubah Profil')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_serverError != null) ...[
                  AuthErrorBanner(message: _serverError!.message),
                  const SizedBox(height: 16),
                ],
                AppCard(
                  padding: const EdgeInsets.all(18),
                  shadow: AppColors.softShadow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Informasi akun',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nama,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            _serverError?.fieldError('nama') ??
                            validateNama(value),
                        onChanged: (_) => _clearServerError(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _alamat,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) =>
                            _serverError?.fieldError('alamat') ??
                            validateAlamat(value),
                        onChanged: (_) => _clearServerError(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: _noTelp,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Nomor telepon',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppColors.soft,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hubungi outlet untuk mengubah nomor telepon.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
