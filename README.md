# caren: Care, closer.

Personal and family wellness application built with Flutter, Riverpod, and GoRouter, with an architecture designed for contactless physiological signal observation via the Presage SmartSpectra SDK.

---

## 1. Product Vision & Architecture Overview

CAREN helps individuals stay gently connected to the wellness of family members living near or far, while preserving personal dignity, privacy, and calm.

### Core Experiences

1. **Family Circle (`/family`)**: Voluntary daily wellness check-ins.
   - Transparent, explicit, and revocable sharing permissions.
   - Clear distinction between self-reported feelings and optional camera-derived measurements.
   - Missed or delayed check-ins are treated with calm, human follow-up prompts—never as alarmist proof of illness or danger.
2. **Me Experience (`/me`)**: Private personal wellness sanctuary.
   - Guided breathing and relaxation sessions (2, 3, 5, and 10 minutes) with visual breathing pacing.
   - Optional pre-session and post-session pulse rate observations.
   - Strictly isolated and private by default—family members cannot view Me activities.
3. **Assist Experience (`/assist`)**: Safety-first situational documentation.
   - Timestamped timeline of observations and physical recovery comfort actions when someone nearby is unwell.
   - Always-visible emergency services (911) dispatch action.
   - Generates a structured handoff summary for healthcare professionals.
   - Non-diagnostic: does not diagnose, triage, or delay professional medical intervention.

---

## 2. Directory Structure

```text
lib/
  app/
    app.dart                 # Root MaterialApp.router with Riverpod integration
    router/
      app_router.dart        # Declarative GoRouter setup with StatefulShellRoute & subroutes
    theme/
      app_theme.dart         # Calm Deep Teal (#1D4E56), Soft Mint, and accessible typography
  core/
    constants/
      app_colors.dart        # Primary, secondary, surface, and simulated banner color tokens
      app_spacing.dart       # Minimum touch target 48dp, border radii, screen margins
      app_typography.dart    # High-contrast, clean typography accessible to older adults
    errors/
      failures.dart          # Typed failure classes with respectful, human-friendly messages
    utils/
      formatters.dart        # Localized timestamp and duration formatters
    widgets/
      caren_app_bar.dart     # Standardized app bar with profile avatar access
      caren_button.dart      # Accessible touch-target buttons (primary, secondary, outline, text, danger)
      caren_card.dart        # Flat bordered card component with optional tap handler
      caren_text_field.dart  # Form field with accessible contrast and label
      simulated_banner.dart  # Prominent amber badge tagging developer mock vitals
      state_views.dart       # Loading, empty, permission-denied, and retry views
      status_badge.dart      # Pill badges (success, info, warning, danger, neutral)
  features/
    onboarding/
      presentation/          # Splash & 3-step Onboarding introduction
    authentication/
      presentation/          # Clean Sign-in and Registration flows
    dashboard/
      presentation/          # Main CAREN dashboard & StatefulShell bottom bar
    family/
      domain/                # FamilyMember, DailyCheckIn, SharingPermission
      data/                  # LocalFamilyRepository & Riverpod providers
      presentation/          # FamilyDashboard, MemberList, MemberDetail, CheckIn, Report
    wellness/
      domain/                # BreathingSession, WellnessTrendPoint
      data/                  # LocalWellnessRepository & trend providers
      presentation/          # MeDashboard, GuidedBreathingScreen, PersonalHistory
    assist/
      domain/                # AssistSession, AssistObservation
      data/                  # LocalAssistRepository
      presentation/          # AssistLandingScreen, AssistSessionScreen
    profile/
      domain/                # UserProfile, PrivacySettings
      data/                  # LocalProfileRepository
      presentation/          # ProfileSettingsScreen, PrivacyPermissionsScreen
  services/
    vitals/
      vitals_models.dart     # MeasurementResult, VitalsStreamData, MeasurementConfig
      vitals_provider.dart   # Abstract VitalsProvider contract
      mock_vitals_provider.dart # Verified simulation provider for local dev and automated tests
      native_vitals_provider.dart # Platform Channel bridge for Android Kotlin SDK
    permissions/
      permission_service.dart
  main.dart

android/
  app/
    src/main/kotlin/com/caren/app/caren/
      MainActivity.kt
      smartspectra/
        SmartSpectraBridge.kt # MethodChannel & EventChannel bridge
test/
  vitals_provider_test.dart  # Unit tests for vitals lifecycle & simulation markings
  widgets_test.dart          # Core UI component & accessibility tests
  widget_test.dart           # App launch smoke test
```

---

## 3. Technology Stack & Dependencies

- **Framework:** Flutter 3.47+ / Dart 3.13+
- **State Management:** `flutter_riverpod: ^3.5.0`
- **Routing & Navigation:** `go_router: ^18.1.3`
- **Visualization:** `fl_chart: ^1.3.0`
- **Date/Time Utilities:** `intl: ^0.20.3`
- **Identifiers:** `uuid: ^4.6.0`
- **Native Android:** Kotlin, Android API 28+ (SmartSpectra requirement), CameraX

---

## 4. Presage SmartSpectra SDK Integration Strategy

The Presage SmartSpectra SDK (`com.presagetech:smartspectra`) turns smartphone cameras into real-time contactless vital sign sensors (heart rate / pulse rate, breathing rate, HRV):

- **Platform Architecture:** Flutter Platform Channels (`com.caren.app/smartspectra` and `com.caren.app/smartspectra_stream`). The UI does not depend directly on native classes.
- **Provider Abstraction (`VitalsProvider`):** All UI components consume the abstract `VitalsProvider` contract.
- **Mock Implementation (`MockVitalsProvider`):** Automatically active in this foundation build. Generates simulated pulse waveforms and metrics, explicitly returning `isSimulated: true`. All UI views render a prominent amber `SimulatedBanner` so simulated measurements are never mistaken for real health readings.
- **Native Android Bridge (`SmartSpectraBridge.kt`):** Created in `android/app/src/main/kotlin/.../smartspectra/SmartSpectraBridge.kt`, handling initialization, camera permissions, stream sink routing, and cleanup.

---

## 5. How to Run & Test

### Prerequisites
- Flutter SDK 3.24+ (Tested on 3.47.5)
- Android Studio / Android SDK API 28+
- JDK 17

### Steps
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run all automated tests
flutter test

# 4. Launch application on connected emulator or device
flutter run
```

---

## 6. Privacy & Safety Commitments

1. **Explicit Camera Permission:** Camera access is requested only when a user explicitly initiates a spot check. Camera frames are processed strictly in real-time memory and never stored or uploaded.
2. **Voluntary Participation:** Family check-in participation and sharing can be toggled or completely revoked at any moment.
3. **No Fabricated Medical Claims:** Readings are presented as personal wellness observations, not diagnostic determinations.
4. **Emergency Prioritization:** The Assist flow explicitly instructs users to contact emergency services first and never delay CPR or AED use.
