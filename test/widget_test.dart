import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/app/app.dart';

void main() {
  testWidgets('App launch and splash screen rendering test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CarenApp(),
      ),
    );

    // Verify splash elements (brand icon, wordmark, and tagline)
    expect(find.bySemanticsLabel('caren'), findsOneWidget);
    expect(find.text('Care, closer.'), findsOneWidget);

    // Let timer tick
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify onboarding screen appears
    expect(find.text('Care without surveillance'), findsOneWidget);
  });
}
