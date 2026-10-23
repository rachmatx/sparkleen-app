import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _phone = TextEditingController();
  final _alamat = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirmation = TextEditingController();
  ApiException? _serverError;

  @override
  void dispose() {
    _nama.dispose();
    _phone.dispose();
    _alamat.dispose();
    _pin.dispose();
    _pinConfirmation.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (_serverError != null) setState(() => _serverError = null);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            nama: _nama.text.trim(),
            noTelp: _phone.text.trim(),
            alamat: _alamat.text.trim(),
            pin: _pin.text,
          );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _serverError = error);
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authControllerProvider.select((value) => value.isLoading),
    );

    return AuthScaffold(
      showBack: true,
      title: 'Buat akun baru',
      subtitle: 'Satu akun untuk semua riwayat laundry-mu.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_serverError != null) ...[
              AuthErrorBanner(message: _serverError!.message),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nama,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                hintText: 'Budi Santoso',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) =>
                  _serverError?.fieldError('nama') ?? validateNama(value),
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nomor telepon',
                hintText: '0812xxxxxxx',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
              validator: (value) =>
                  _serverError?.fieldError('no_telp') ?? validatePhone(value),
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _alamat,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Jl. Merdeka No. 10',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) =>
                  _serverError?.fieldError('alamat') ?? validateAlamat(value),
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: '6 digit angka',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) =>
                  _serverError?.fieldError('pin') ?? validatePin(value),
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pinConfirmation,
              obscureText: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Ulangi PIN',
                hintText: 'Ketik ulang PIN',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: (value) => validatePinConfirmation(value, _pin.text),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Daftar'),
            ),
            const SizedBox(height: 18),
            AuthLinkPrompt(
              question: 'Sudah punya akun?',
              actionLabel: 'Masuk',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
