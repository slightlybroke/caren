import 'package:caren/core/widgets/web_responsive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebResponsiveShell Widget Tests', () {
    testWidgets(
      'Passes child through natively when running on non-web platforms',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: WebResponsiveShell(
                child: Scaffold(body: Text('Caren Native Child View')),
              ),
            ),
          ),
        );

        expect(find.text('Caren Native Child View'), findsOneWidget);
      },
    );
  });
}
