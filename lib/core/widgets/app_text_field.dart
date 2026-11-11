import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A stable label outside the input keeps forms readable while typing.
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.decoration = const InputDecoration(),
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
  });
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled, readOnly, obscureText, enableSuggestions, autocorrect;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final int? minLines, maxLines, maxLength;
  @override
  Widget build(BuildContext context) {
    final label = decoration.labelText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          label: label,
          child: TextFormField(
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            controller: controller,
            initialValue: initialValue,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            enableSuggestions: enableSuggestions,
            autocorrect: autocorrect,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            decoration: decoration.copyWith(
              labelText: '',
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
          ),
        ),
      ],
    );
  }
}
