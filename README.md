# caren: Care, closer.

Personal and family wellness application built with Flutter, Riverpod, and GoRouter, with native Android integration for contactless physiological signal observation via the Presage SmartSpectra SDK 3.4.0.

---

## 1. Product Vision & Architecture Overview

CAREN helps individuals stay gently connected to the wellness of family members living near or far, while preserving personal dignity, privacy, and calm.

### Core Experiences

1. **Family Circle (`/family`)**: Voluntary daily wellness check-ins.
   - Transparent, explicit, and revocable sharing permissions.
   - Clear distinction between self-reported feelings and optional camera-derived measurements.
   - Missed or delayed check-ins trigger calm, human follow-up prompts—never alarmist alerts.
2. **Me Experience (`/me`)**: Private personal wellness sanctuary.
   - Guided breathing and relaxation sessions (2, 3, 5, and 10 minutes) with animated breathing ring pacer.
   - Optional pre-session and post-session pulse rate observations.
   - Strictly isolated and private by default—family members cannot view Me activities.
3. **Assist Experience (`/assist`)**: Safety-first situational documentation.
   - Timestamped timeline of observations and recovery comfort actions when someone nearby is unwell.
   - Prominent, localized emergency dispatch action (defaults to India **112**; configurable in user profile). Never automatically initiates phone calls.
   - Generates structured medical handoff summaries for emergency dispatchers or physicians.
   - Non-diagnostic: does not diagnose, triage, or delay professional medical intervention.

---

## 2. Directory Structure

```text
lib/
  app/
    app.dart                 # Root MaterialApp.router with Riverpod integration
    router/
      app_router.dart        # Declarative GoRouter setup with StatefulShellRoute & 17 routes
    theme/
      app_theme.dart         # Material 3 light theme (Deep Teal #1D4E56, Soft Mint, Sage)
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
      vitals_measurement_widget.dart # Metric-aware live PPG waveform & camera overlay widget
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
      presentation/          # FamilyDashboard, MemberList, MemberDetail, Metric-Aware CheckIn, Report
    wellness/
      domain/                # BreathingSession, WellnessTrendPoint
      data/                  # LocalWellnessRepository & trend providers
      presentation/          # MeDashboard, GuidedBreathingScreen (15s spot check), PersonalHistory
    assist/
      domain/                # AssistSession, AssistObservation
      data/                  # LocalAssistRepository
      presentation/          # AssistLandingScreen (112 emergency action), AssistSessionScreen
    profile/
      domain/                # UserProfile (with country & emergencyNumber), PrivacySettings
      data/                  # LocalProfileRepository
      presentation/          # ProfileSettingsScreen (Country/Emergency modal), PrivacyPermissionsScreen
  services/
    vitals/
      vitals_models.dart     # MeasurementTarget, MeasurementStatus, MeasurementConfig, StreamData, Result
      vitals_provider.dart   # Abstract VitalsProvider contract & provider selector
      mock_vitals_provider.dart # Verified simulation provider with 12s/30s/60s confidence window enforcement
      native_vitals_provider.dart # Platform Channel bridge for Android Kotlin SDK
    permissions/
      permission_service.dart
  main.dart

android/
  app/
    build.gradle.kts         # Presage SmartSpectra 3.4.0 Maven Central dependency
    src/main/kotlin/com/caren/app/caren/
      MainActivity.kt        # Lifecycle hooks (onPause, onResume, onDestroy)
      smartspectra/
        SmartSpectraBridge.kt # Coroutine-backed MethodChannel & EventChannel Kotlin bridge
test/
  vitals_provider_test.dart  # Unit tests for vitals lifecycle, confidence windows & simulation flags
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
- **Native Android:** Kotlin, Android API 28+ (`minSdk = 28`), CameraX, Presage SmartSpectra 3.4.0

---

## 4. Presage SmartSpectra SDK Integration (v3.4.0)

The Presage SmartSpectra SDK (`com.presagetech:smartspectra:3.4.0`) transforms device camera video into contactless vital signs (pulse rate, breathing rate, HRV):

- **Platform Architecture:** Flutter Platform Channels (`com.caren.app/smartspectra` and `com.caren.app/smartspectra_stream`).
- **Native Kotlin Bridge:** Implemented in `SmartSpectraBridge.kt` using `SmartSpectraSdk.shared`.
  - Concurrency protection: rejects duplicate concurrent sessions with `SESSION_ALREADY_ACTIVE`.
  - Coroutine execution: calls `suspend fun sdk.start()` and `suspend fun sdk.stop()` within a structured `CoroutineScope`.
  - Android lifecycle: hooks `onPause()` and `onResume()` in `MainActivity.kt`.
- **Confidence Windows Enforced:**
  - **Pulse Rate:** 12 seconds
  - **Breathing Rate:** 30 seconds (requires steady posture and stable camera)
  - **HRV:** 60 seconds
  Metrics are strictly suppressed until their documented confidence window has elapsed. Premature session stoppage marks the result as incomplete with an explicit explanation.
- **Provider Switching:** Riverpod allows selecting either `MockVitalsProvider` or `NativeVitalsProvider`. Real integration errors are surfaced directly without silent fallback.

---

## 5. Emergency Services Localization

- Initial target market: **India**. Default emergency number: **112**.
- Profile Settings allows selecting country (India 112, US 911, UK 999, EU 112, Australia 000, etc.).
- Assist screens read the localized emergency number dynamically and open a confirmation dialer modal. CAREN never places calls automatically.

---

## 6. How to Run & Test

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (0 issues)
flutter analyze

# 3. Run automated tests (13 passing)
flutter test

# 4. Verify Android Kotlin compilation with SmartSpectra 3.4.0
cd android; ./gradlew compileDebugKotlin
```

---

## 7. Device Verification Status & Hardware Readiness

- **Build-Time Verification:** The native Android SDK artifact `com.presagetech:smartspectra:3.4.0` has been compiled and linked successfully with Gradle (`BUILD SUCCESSFUL in 1m 8s`).
- **Physical Device Status:** Genuine live camera capture has **not** yet been executed on physical hardware because active Presage Developer Portal credentials (API Key / `presage_services.xml`) for package `com.caren.app.caren` are pending provisioning.
- **Mock Mode Safety:** The app defaults to `MockVitalsProvider` with all simulated data visibly labeled via the amber `SimulatedBanner`.
