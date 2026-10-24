import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_scaffold.dart';

class ActivatePage extends ConsumerStatefulWidget {
  const ActivatePage({super.key});

  @override
  ConsumerState<ActivatePage> createState() => _ActivatePageState();
}

class _ActivatePageState extends ConsumerState<ActivatePage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _noNota = TextEditingController();
  final _pin = TextEditingController();
  ApiException? _serverError;

  @override
  void dispose() {
    _phone.dispose();
    _noNota.dispose();
    _pin.dispose();
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
          .activate(
            noTelp: _phone.text.trim(),
            noNota: _noNota.text.trim(),
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
      title: 'Aktivasi PIN',
      subtitle:
          'Pelanggan lama cukup masukkan nomor nota terakhir untuk membuat PIN.',
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
              controller: _noNota,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nomor nota',
                hintText: 'LAU/20261021/0001',
                prefixIcon: Icon(Icons.receipt_long_rounded),
              ),
              validator: (value) =>
                  _serverError?.fieldError('no_nota') ?? validateNoNota(value),
              onChanged: (_) => _clearServerError(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'PIN baru',
                hintText: '6 digit angka',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) =>
                  _serverError?.fieldError('pin') ?? validatePin(value),
              onChanged: (_) => _clearServerError(),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppGradientButton(
              label: 'Aktifkan',
              loading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            AuthLinkPrompt(
              question: 'Sudah punya PIN?',
              actionLabel: 'Masuk',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
