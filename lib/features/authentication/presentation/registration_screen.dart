import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_text_field.dart';
import '../../profile/domain/user_profile.dart';
import 'controllers/auth_controller.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedCountry = 'United States';
  bool _agreeToPrivacy = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final city = _cityController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required fields.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _errorMessage = null);

    try {
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
    final localizedEmergencyNumber = EmergencyDirectory.getNumber(_selectedCountry);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join caren',
                style: AppTypography.displayMedium.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Care, closer. Build a safe wellness connection with your loved ones.',
                style: AppTypography.bodyMedium,
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
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              CarenTextField(
                label: 'Email address',
                hint: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              CarenTextField(
                label: 'Password',
                hint: 'At least 6 characters',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                decoration: const InputDecoration(
                  labelText: 'Country (for Emergency Localization)',
                  prefixIcon: Icon(Icons.public, color: AppColors.primary),
                ),
                items: EmergencyDirectory.countryNumbers.keys.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCountry = val);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Localized emergency number: $localizedEmergencyNumber',
                style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.md),
              CarenTextField(
                label: 'City (Optional)',
                hint: 'e.g. Seattle, Portland, Bengaluru',
                controller: _cityController,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: AppTypography.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
