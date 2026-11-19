/// Configuration for caren demo access on web and desktop.
///
/// Values can be supplied at build time using Flutter's `--dart-define` flags:
/// `--dart-define=DEMO_EMAIL=...`
/// `--dart-define=DEMO_PASSWORD=...`
/// Or default to a built-in demo account so reviewers and web visitors can
/// experience the full application immediately with zero friction.
class DemoConfig {
  static const String demoEmail = String.fromEnvironment(
    'DEMO_EMAIL',
    defaultValue: 'demo@example.com',
  );

  static const String demoPassword = String.fromEnvironment(
    'DEMO_PASSWORD',
    defaultValue: 'local-demo-only',
  );

  static const String demoDisplayName = String.fromEnvironment(
    'DEMO_NAME',
    defaultValue: 'Caren Demo',
  );

  /// Always true since we provide a safe fallback demo account
  static bool get isConfigured =>
      demoEmail.trim().isNotEmpty && demoPassword.trim().isNotEmpty;
}
