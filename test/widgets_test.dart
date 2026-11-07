import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/core/widgets/caren_button.dart';
import 'package:caren/core/widgets/caren_card.dart';
import 'package:caren/core/widgets/status_badge.dart';
import 'package:caren/core/widgets/simulated_banner.dart';
import 'package:caren/core/widgets/state_views.dart';

void main() {
  group('CAREN Core UI Widgets Tests', () {
    testWidgets('CarenButton renders with correct label and triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarenButton(
              label: 'Start Check-In',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Check-In'), findsOneWidget);
      await tester.tap(find.text('Start Check-In'));
      expect(pressed, isTrue);
    });

    testWidgets('CarenButton displays loader when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarenButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('CarenCard displays child content and handles onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarenCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge renders label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Checked in',
              type: BadgeType.success,
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('Checked in'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('SimulatedBanner renders prominent disclaimer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimulatedBanner(),
          ),
        ),
      );

      expect(find.text('SIMULATED DATA (MOCK VITAL SIGNS)'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });

    testWidgets('CarenPermissionDeniedView displays camera rationale and grant button', (tester) async {
      bool granted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarenPermissionDeniedView(
              onGrantPermission: () => granted = true,
            ),
          ),
        ),
      );

      expect(find.text('Camera Access Needed for Measurement'), findsOneWidget);
      await tester.tap(find.text('Grant Camera Access'));
      expect(granted, isTrue);
    });
  });
}

