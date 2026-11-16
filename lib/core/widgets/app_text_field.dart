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
    this.onTap,
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
  final VoidCallback? onTap;
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
            decoration: _withoutInlineLabel(decoration),
            validator: validator,
            onChanged: onChanged,
            onTap: onTap,
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

// copyWith cannot clear labelText. Preserve adornments without an inline label
// so the placeholder is also visible before the field receives focus.
InputDecoration _withoutInlineLabel(InputDecoration source) => InputDecoration(
  icon: source.icon,
  iconColor: source.iconColor,
  labelStyle: source.labelStyle,
  helper: source.helper,
  helperText: source.helperText,
  helperStyle: source.helperStyle,
  helperMaxLines: source.helperMaxLines,
  hintText: source.hintText,
  hint: source.hint,
  hintStyle: source.hintStyle,
  hintTextDirection: source.hintTextDirection,
  hintMaxLines: source.hintMaxLines,
  hintFadeDuration: source.hintFadeDuration,
  maintainHintSize: source.maintainHintSize,
  maintainLabelSize: source.maintainLabelSize,
  error: source.error,
  errorText: source.errorText,
  errorStyle: source.errorStyle,
  errorMaxLines: source.errorMaxLines,
  isCollapsed: source.isCollapsed,
  isDense: source.isDense,
  contentPadding: source.contentPadding,
  prefixIcon: source.prefixIcon,
  prefixIconConstraints: source.prefixIconConstraints,
  prefix: source.prefix,
  prefixText: source.prefixText,
  prefixStyle: source.prefixStyle,
  prefixIconColor: source.prefixIconColor,
  suffixIcon: source.suffixIcon,
  suffix: source.suffix,
  suffixText: source.suffixText,
  suffixStyle: source.suffixStyle,
  suffixIconColor: source.suffixIconColor,
  suffixIconConstraints: source.suffixIconConstraints,
  counter: source.counter,
  counterText: source.counterText,
  counterStyle: source.counterStyle,
  filled: source.filled,
  fillColor: source.fillColor,
  focusColor: source.focusColor,
  hoverColor: source.hoverColor,
  errorBorder: source.errorBorder,
  focusedBorder: source.focusedBorder,
  focusedErrorBorder: source.focusedErrorBorder,
  disabledBorder: source.disabledBorder,
  enabledBorder: source.enabledBorder,
  border: source.border,
  enabled: source.enabled,
  semanticCounterText: source.semanticCounterText,
  alignLabelWithHint: source.alignLabelWithHint,
  constraints: source.constraints,
  visualDensity: source.visualDensity,
);
