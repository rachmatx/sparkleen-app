import '../../../../core/theme/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six visual cells backed by one real protected input, retaining paste,
/// numeric keyboards, validation, and a single accessible focus target.
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
  final String label, hint;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged, onFieldSubmitted;
  final bool enabled;
  @override
  State<PinFormField> createState() => _PinFormFieldState();
}

class _PinFormFieldState extends State<PinFormField> {
  bool _visible = false;
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.textScalerOf(context).scale(20) > 30
        ? 68.0
        : 56.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(widget.label, style: theme.textTheme.labelLarge),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (context, value, _) => SizedBox(
                          height: height,
                          child: Row(
                            children: [
                              for (var i = 0; i < 6; i++) ...[
                                if (i > 0) const SizedBox(width: 5),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: .75),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            _focus.hasFocus &&
                                                i ==
                                                    value.text.length.clamp(
                                                      0,
                                                      5,
                                                    )
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Text(
                                      i < value.text.length
                                          ? (_visible ? value.text[i] : '•')
                                          : '',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    label: '${widget.label}, ${widget.hint}',
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focus,
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
                      style: const TextStyle(color: Colors.transparent),
                      showCursor: false,
                      decoration: InputDecoration(
                        filled: false,
                        constraints: BoxConstraints(minHeight: height),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: (height - 20) / 2,
                        ),
                        errorMaxLines: 3,
                      ),
                      onTapOutside: (_) => _focus.unfocus(),
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      onFieldSubmitted: widget.onFieldSubmitted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              height: height,
              child: IconButton(
                tooltip:
                    '${_visible ? 'Sembunyikan' : 'Tampilkan'} ${widget.label}',
                isSelected: _visible,
                onPressed: widget.enabled
                    ? () => setState(() => _visible = !_visible)
                    : null,
                icon: const Icon(AppIcons.visibility_outlined),
                selectedIcon: const Icon(AppIcons.visibility_off_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
