import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_country_picker_field.dart';
import '../../../core/widgets/caren_password_field.dart';
import '../../../core/widgets/caren_text_field.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_brand_header.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedCountry = 'United States';
  bool _agreeToPrivacy = true;
  String? _errorMessage;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordsMatch);
    _confirmPasswordController.addListener(_validatePasswordsMatch);
  }

  void _validatePasswordsMatch() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (confirm.isEmpty) {
      if (_confirmPasswordError != null) {
        setState(() => _confirmPasswordError = null);
      }
      return;
    }

    if (password != confirm) {
      if (_confirmPasswordError != 'Passwords do not match.') {
        setState(() => _confirmPasswordError = 'Passwords do not match.');
      }
    } else {
      if (_confirmPasswordError != null) {
        setState(() => _confirmPasswordError = null);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordsMatch);
    _confirmPasswordController.removeListener(_validatePasswordsMatch);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final city = _cityController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required fields.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match.';
        _errorMessage = 'Please ensure both passwords match.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _confirmPasswordError = null;
    });

    try {
      // Security: Only send the primary password to Firebase Auth, never the confirmation field
      await ref.read(authNotifierProvider.notifier).register(
            email: email,
            password: password,
            displayName: name,
            country: _selectedCountry,
            city: city,
          );
      if (mounted) {
        context.go('/family');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AuthBrandHeader(showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Create your caren account',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Care, closer. Build a safe, voluntary connection with your family.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                CarenTextField(
                  label: 'Full Name',
                  hint: 'e.g. Eleanor Vance',
                  controller: _nameController,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),

                CarenTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),

                CarenPasswordField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                CarenPasswordField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  errorText: _confirmPasswordError,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                CarenCountryPickerField(
                  selectedCountry: _selectedCountry,
                  onCountrySelected: (c) => setState(() => _selectedCountry = c),
                ),
                const SizedBox(height: AppSpacing.md),

                CarenTextField(
                  label: 'City (Optional)',
                  hint: 'e.g. Seattle, Portland, Bengaluru',
                  controller: _cityController,
                  autofillHints: const [AutofillHints.addressCity],
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreeToPrivacy,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _agreeToPrivacy = v ?? true),
                    ),
                    Expanded(
                      child: Text(
                        'I understand that all health measurements and check-ins are voluntary and private by default.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                CarenButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onPressed: _agreeToPrivacy ? _handleRegister : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
