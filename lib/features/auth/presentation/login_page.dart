import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_assets.dart';

import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../application/auth_controller.dart';
import 'validators.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/pin_form_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  ApiException? _serverError;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (_serverError != null) setState(() => _serverError = null);
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(noTelp: _phone.text.trim(), pin: _pin.text);
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
      illustrationAsset: AppAssets.login,
      title: 'Cucian beres.\nHari lebih lega.',
      subtitle: 'Masuk untuk pantau cucianmu.',
      footer: Column(
        children: [
          AuthLinkPrompt(
            question: 'Belum punya akun?',
            actionLabel: 'Daftar',
            onPressed: () => context.go('/register'),
          ),
          const SizedBox(height: 8),
          AuthLinkPrompt(
            question: 'Pelanggan lama?',
            actionLabel: 'Aktivasi PIN',
            onPressed: () => context.go('/activate'),
          ),
        ],
      ),
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
              enabled: !isLoading,
              autofillHints: const [AutofillHints.telephoneNumber],
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
            const SizedBox(height: 16),
            PinFormField(
              controller: _pin,
              enabled: !isLoading,
              label: 'PIN',
              hint: '6 digit angka',
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  _serverError?.fieldError('pin') ?? validatePin(value),
              onChanged: (_) => _clearServerError(),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Masuk', loading: isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
