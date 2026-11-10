import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/app/theme/app_theme.dart';
import 'package:caren/core/widgets/caren_button.dart';
import 'package:caren/core/widgets/caren_country_picker_field.dart';
import 'package:caren/core/widgets/caren_password_field.dart';
import 'package:caren/core/widgets/caren_text_field.dart';
import 'package:caren/features/authentication/presentation/registration_screen.dart';
import 'package:caren/features/authentication/presentation/widgets/auth_brand_header.dart';

void main() {
  group('Auth Brand Polish & Component Tests', () {
    testWidgets('AuthBrandHeader renders wordmark and subtle watermark motif', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: AuthBrandHeader(showBackButton: true),
            body: Center(child: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify wordmark image is present
      expect(find.bySemanticsLabel('caren'), findsOneWidget);

      // Verify watermark emblem image is present
      expect(find.bySemanticsLabel('caren emblem watermark'), findsOneWidget);

      // Verify back icon button is present
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('AuthBrandHeader can hide back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: AuthBrandHeader(showBackButton: false),
            body: Center(child: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.bySemanticsLabel('caren'), findsOneWidget);
    });

    testWidgets('CarenPasswordField toggles obscure state cleanly', (tester) async {
      final controller = TextEditingController(text: 'Secret123!');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CarenPasswordField(
                controller: controller,
                label: 'Password',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find EditableText
      EditableText editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
      // Toggle button shows visibility icon to indicate clicking will show password
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
      expect(controller.text, equals('Secret123!'));
    });

    testWidgets('CarenCountryPickerField renders 52dp box and opens bottom sheet selector', (tester) async {
      String selectedCountry = 'India';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CarenCountryPickerField(
                    selectedCountry: selectedCountry,
                    onCountrySelected: (code) => setState(() => selectedCountry = code),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check displayed country details for India
      expect(find.text('India'), findsOneWidget);
      expect(find.text('SOS 112'), findsOneWidget);

      // Verify container height constraint of 52dp on the interactive input container
      final RenderBox box = tester.renderObject(
        find.descendant(
          of: find.byType(CarenCountryPickerField),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(box.size.height, equals(52.0));

      // Tap to open bottom sheet
      await tester.tap(find.byType(AnimatedContainer));
      await tester.pumpAndSettle();

      expect(find.text('Select Country'), findsOneWidget);
      // In bottom sheet, list contains United States
      expect(find.text('United States'), findsOneWidget);

      // Select United States
      await tester.tap(find.text('United States'));
      await tester.pumpAndSettle();

      // Verify updated selection
      expect(selectedCountry, equals('United States'));
      expect(find.text('United States'), findsOneWidget);
      expect(find.text('SOS 911'), findsOneWidget);
    });

    testWidgets('RegistrationScreen validates password mismatch in real time and renders unified branding', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegistrationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and content heading
      expect(find.byType(AuthBrandHeader), findsOneWidget);
      expect(find.text('Create your caren account'), findsOneWidget);

      // Fill in name and email
      final textFields = find.byType(CarenTextField);
      await tester.enterText(textFields.at(0), 'Jane Doe');
      await tester.enterText(textFields.at(1), 'jane@example.com');
      await tester.pump();

      // Locate password fields
      final passwordFields = find.byType(CarenPasswordField);
      expect(passwordFields, findsNWidgets(2));

      // Enter password
      await tester.enterText(passwordFields.at(0), 'Secret123');
      await tester.pump();

      // Enter mismatched confirm password
      await tester.enterText(passwordFields.at(1), 'DifferentSecret');
      await tester.pump();

      // Error message should appear in real time under confirm password field
      expect(find.text('Passwords do not match.'), findsOneWidget);

      // Scroll and attempt submit
      final submitButton = find.widgetWithText(CarenButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Please ensure both passwords match.'), findsOneWidget);

      // Fix confirm password
      await tester.enterText(passwordFields.at(1), 'Secret123');
      await tester.pump();

      // Real-time error message should be gone
      expect(find.text('Passwords do not match.'), findsNothing);
    });
  });
}
