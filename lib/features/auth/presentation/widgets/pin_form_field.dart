import '../../../../core/widgets/app_text_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinFormField extends StatefulWidget {
  const PinFormField({
    super.key,
    required this.controller,
    this.label = 'PIN',
    this.hint = '6 digit angka',
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  State<PinFormField> createState() => _PinFormFieldState();
}

class _PinFormFieldState extends State<PinFormField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => AppTextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: !_visible,
    enableSuggestions: false,
    autocorrect: false,
    keyboardType: TextInputType.number,
    textInputAction: widget.textInputAction,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: '${_visible ? 'Sembunyikan' : 'Tampilkan'} ${widget.label}',
        isSelected: _visible,
        onPressed: widget.enabled
            ? () => setState(() => _visible = !_visible)
            : null,
        icon: const Icon(Icons.visibility_outlined),
        selectedIcon: const Icon(Icons.visibility_off_outlined),
      ),
    ),
    validator: widget.validator,
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onFieldSubmitted,
  );
}
