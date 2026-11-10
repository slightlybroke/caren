import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caren/app/theme/app_theme.dart';
import 'package:caren/features/family/data/family_repository.dart';
import 'package:caren/features/family/domain/family_invitation.dart';
import 'package:caren/features/family/presentation/add_member_wizard_screen.dart';

void main() {
  late LocalFamilyRepository localFamilyRepo;

  setUp(() {
    localFamilyRepo = LocalFamilyRepository();
  });

  Widget createWizardApp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return ProviderScope(
      overrides: [
        familyRepositoryProvider.overrideWithValue(localFamilyRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AddMemberWizardScreen(),
      ),
    );
  }

  group('Add Member Wizard Screen Tests', () {
    testWidgets('Renders Step 1 with loved one name input, relationship chips, and care role archetypes', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      expect(find.text('Who are you inviting?'), findsOneWidget);
      expect(find.text("Loved One's Name"), findsOneWidget);
      expect(find.text('Relationship'), findsOneWidget);
      expect(find.text('Living Arrangement'), findsOneWidget);
      expect(find.text('Care Role Profile'), findsOneWidget);
      expect(find.text('Elder / Primary Loved One'), findsOneWidget);
      expect(find.text('Family Companion'), findsOneWidget);
      expect(find.text('Physician or Dedicated Care Aide'), findsOneWidget);
      expect(find.text('Continue to Privacy Boundaries'), findsOneWidget);
    });

    testWidgets('Step 1 validation blocks advancing when full name is empty', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Click Continue without entering a name
      await tester.tap(find.text('Continue to Privacy Boundaries'));
      await tester.pumpAndSettle();

      expect(find.text("Please enter the loved one's name."), findsOneWidget);
      // Still on Step 1
      expect(find.text('Who are you inviting?'), findsOneWidget);
    });

    testWidgets('Steps 1 -> 2 progression navigates to Privacy Boundaries with default-OFF toggles', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'Martha Vance');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue to Privacy Boundaries'));
      await tester.pumpAndSettle();

      // Should now be on Step 2
      expect(find.text('Step 2 of 3: Privacy Boundaries'), findsOneWidget);
      expect(find.text('Configure Sovereign Boundaries'), findsOneWidget);
      expect(find.text('Autonomous Dignity First'), findsOneWidget);
      expect(find.text('Daily Check-in Completion'), findsOneWidget);
      expect(find.text('Self-Reported Feeling & Mood'), findsOneWidget);
      expect(find.text('Optional Camera Spot-Check Vitals'), findsOneWidget);
      expect(find.text('Personal Check-in Notes'), findsOneWidget);

      // Verify locked private Me sanctuary banner
      expect(find.text('Private Me Sanctuary'), findsOneWidget);
      expect(find.text('100% Private (Locked)'), findsOneWidget);
      expect(find.text('Emergency SOS Action'), findsOneWidget);
      expect(find.text('Continue to Invite Link'), findsOneWidget);
    });

    testWidgets('Steps 2 -> 3 progression navigates to Invite & Activation and renders activation cards', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Enter name on Step 1
      await tester.enterText(find.byType(TextField).first, 'Martha Vance');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Privacy Boundaries'));
      await tester.pumpAndSettle();

      // Advance from Step 2 to Step 3
      await tester.tap(find.text('Continue to Invite Link'));
      await tester.pumpAndSettle();

      // Should now be on Step 3
      expect(find.text('Step 3 of 3: Pair & Welcome'), findsOneWidget);
      expect(find.text('Welcome Martha Vance to the Hearth'), findsOneWidget);
      expect(find.text('Invitee Account Email'), findsOneWidget);
      expect(find.text('Voice & Text Passcode'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
      expect(find.text('Send Invitation via Email'), findsOneWidget);
      expect(find.text('Ready to Pair'), findsOneWidget);
    });

    testWidgets('Step 3 email validation requires valid email address', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Go to Step 3
      await tester.enterText(find.byType(TextField).first, 'Martha Vance');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Privacy Boundaries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Invite Link'));
      await tester.pumpAndSettle();

      // Attempt to send with empty email
      await tester.tap(find.text('Send Invitation via Email'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an email address for the invitee.'), findsOneWidget);

      // Attempt with invalid format
      await tester.enterText(find.byType(TextField).first, 'not-an-email');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Invitation via Email'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Step 3 successfully sends invitation and renders confirmation celebration card', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextField).first, 'Martha Vance');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Privacy Boundaries'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.text('Continue to Invite Link'));
      await tester.pumpAndSettle();

      // Step 3: Enter email
      await tester.enterText(find.byType(TextField).first, 'martha@example.com');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Send Invitation via Email'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify repository recorded the invitation with secure single-use passcode and default-OFF permissions
      final sentInvites = await localFamilyRepo.getSentInvitations();
      expect(sentInvites.length, equals(1));
      final invite = sentInvites.first;
      expect(invite.inviteeEmail, equals('martha@example.com'));
      expect(invite.relationship, equals('Parent / Elder'));
      expect(invite.status, equals(InvitationStatus.pending));
      expect(invite.isExpired, isFalse);

      // Verify all sharing permissions persisted as default-OFF
      expect(invite.sharingPermissions['shareCheckInStatus'], isFalse);
      expect(invite.sharingPermissions['shareSelfReportedMood'], isFalse);
      expect(invite.sharingPermissions['shareVitalsMeasurements'], isFalse);
      expect(invite.sharingPermissions['shareNotes'], isFalse);

      // Verify secure 6-digit passcode
      expect(invite.passcode, isNotNull);
      expect(invite.passcode!.length, equals(6));
      expect(int.tryParse(invite.passcode!), isNotNull);

      // Verify UI shows Invitation Dispatched celebration
      expect(find.text('Invitation Dispatched!'), findsOneWidget);
      expect(find.text('Return to Family Dashboard'), findsOneWidget);
    });

    testWidgets('Close button prompts discard dialog when form is modified', (tester) async {
      await tester.pumpWidget(createWizardApp(tester));
      await tester.pumpAndSettle();

      // Type in name
      await tester.enterText(find.byType(TextField).first, 'Martha Vance');
      await tester.pumpAndSettle();

      // Tap close button (X)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify discard dialog
      expect(find.text('Discard Invitation?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap Keep Editing
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Invitation?'), findsNothing);
      expect(find.text('Who are you inviting?'), findsOneWidget);
    });

    test('Invitation acceptance assigns member role and inherits sovereign default-OFF permissions', () async {
      await localFamilyRepo.sendInvitation(
        inviteeEmail: 'elder@example.com',
        relationship: 'Grandmother',
        sharingPermissions: {
          'shareCheckInStatus': false,
          'shareSelfReportedMood': false,
          'shareVitalsMeasurements': false,
          'shareNotes': false,
        },
        passcode: '654321',
      );

      final pending = await localFamilyRepo.getPendingInvitations();
      expect(pending.length, equals(1));
      final invId = pending.first.id;

      // Accept invitation
      await localFamilyRepo.acceptInvitation(invId);

      // Verify members list contains newly added member
      final members = await localFamilyRepo.getFamilyMembers();
      final newMember = members.firstWhere((m) => m.relationship == 'Grandmother');

      // Authorization role is STRICTLY 'member', relationship archetype does NOT elevate permissions
      expect(newMember.role.name, equals('member'));
      // All sharing permissions are default-OFF
      expect(newMember.sharingPermission.shareCheckInStatus, isFalse);
      expect(newMember.sharingPermission.shareSelfReportedMood, isFalse);
      expect(newMember.sharingPermission.shareVitalsMeasurements, isFalse);
      expect(newMember.sharingPermission.shareNotes, isFalse);
    });

    testWidgets('Wizard renders cleanly on narrow screen (320px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(localFamilyRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AddMemberWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Who are you inviting?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Wizard renders with large accessibility text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(localFamilyRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: AddMemberWizardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Who are you inviting?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
