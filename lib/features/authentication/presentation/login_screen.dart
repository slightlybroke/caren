import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_password_field.dart';
import '../../../core/widgets/caren_text_field.dart';
import '../../../services/firebase/firebase_service.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_brand_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() => _errorMessage = null);

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: email,
            password: password,
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

  void _showPasswordResetDialog() {
    _resetEmailController.text = _emailController.text;
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool sending = false;
        String? dialogMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              title: Text(
                'Reset Password',
                style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your account email address. We will send you a secure link to reset your password.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CarenTextField(
                    label: 'Email address',
                    hint: 'you@example.com',
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                  ),
                  if (dialogMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      dialogMessage!,
                      style: AppTypography.caption.copyWith(
                        color: dialogMessage!.startsWith('Error')
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = _resetEmailController.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() {
                              dialogMessage = 'Please enter your email address.';
                            });
                            return;
                          }
                          setDialogState(() => sending = true);
                          try {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .sendPasswordReset(email);
                            setDialogState(() {
                              sending = false;
                              dialogMessage =
                                   'Password reset link sent! Check your inbox.';
                            });
                          } catch (e) {
                            setDialogState(() {
                              sending = false;
                              dialogMessage = 'Error: ${e.toString()}';
                            });
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final fbState = ref.watch(firebaseStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AuthBrandHeader(showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kDebugMode && !fbState.isInitialized) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.accentDark),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Firebase local configuration pending (google-services.json). Operating in local development mode.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.accentDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.xs),
              Text(
                'Welcome back',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check in with your family and continue your personal wellness journey.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

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
                hint: 'Your password',
                controller: _passwordController,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: AppSpacing.xs),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showPasswordResetDialog,
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CarenButton(
                label: 'Sign In',
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New to caren? ', style: AppTypography.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Create an account',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.bug_report_outlined, size: 18),
                    label: const Text('Developer Diagnostics (Direct SDK Testing)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    onPressed: () => context.push('/diagnostics'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
