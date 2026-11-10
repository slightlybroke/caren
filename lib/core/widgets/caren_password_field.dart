import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'caren_text_field.dart';

/// Reusable password input field with show/hide visibility toggle.
///
/// Guarantees:
/// - Obscured by default.
/// - Integrated eye/eye-off toggle inside the field suffix.
/// - Preserves entered text and cursor position across toggles.
/// - Accessible semantic labels for screen readers.
/// - Visual styling matching all other [CarenTextField] instances.
class CarenPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;

  const CarenPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = 'At least 6 characters',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
  });

  @override
  State<CarenPasswordField> createState() => _CarenPasswordFieldState();
}

class _CarenPasswordFieldState extends State<CarenPasswordField> {
  bool _obscured = true;

  void _toggleVisibility() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CarenTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      errorText: widget.errorText,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints ?? const [AutofillHints.password],
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: AppColors.primary,
        size: 20,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        tooltip: _obscured ? 'Show ${widget.label}' : 'Hide ${widget.label}',
        onPressed: _toggleVisibility,
      ),
    );
  }
}

