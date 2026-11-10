# caren: Care, closer.

<p align="center">
  <img src="assets/branding/wordmark_icon.png" alt="caren" width="280"/>
</p>

<p align="center">
  <em>A warm, private, and dignified family wellbeing companion.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter" alt="Flutter 3.24+"/>
  <img src="https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart" alt="Dart 3.5+"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"/>
  <img src="https://img.shields.io/badge/Design_System-Serene_Hearth-174F47" alt="Design System"/>
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS-blue" alt="Platforms"/>
  <img src="https://img.shields.io/badge/Tests-115_Passing-success" alt="Tests"/>
</p>

---

## 1. Product Philosophy & Brand Identity

**caren** is designed around a singular principle: care should bring families closer without invading privacy or creating medical anxiety. 

Unlike clinical monitoring dashboards or intrusive tracking tools, caren provides a gentle, reassuring hearth for personal and family health. It blends calm visual aesthetics with rigorous privacy boundaries.

### Visual & Emotional Foundation
- **The Serene Hearth Palette:** Grounded in Warm Ivory (`#FAF9F4`), Deep Forest (`#174F47`), Sage Mist (`#E8F2ED`), and Terracotta Warmth (`#F3D7C3`). High-contrast clinical whites and stark alert reds are avoided in daily wellness experiences.
- **Manrope Typography:** Clean, modern, warm geometric sans-serif bundled locally in 4 weights (Regular, Medium, SemiBold, Bold) ensuring consistent, offline-first legibility.
- **Subtle Organic Motifs:** Watermark brand emblems and rounded card geometries (`radiusLg: 20dp`, `radiusXl: 28dp`) evoke comfort and human connection rather than clinical coldness.

---

## 2. Core Pillars

caren connects three distinct spaces within a calm, distraction-free interface:

```
┌─────────────────────────────────────────────────────────────────┐
│                              caren                              │
├───────────────────┬─────────────────────────┬───────────────────┤
│   Family Circle   │       Me Sanctuary      │  Emergency Assist │
│  Shared Wellbeing │    Confidential Peace   │  Safety-First Log │
└───────────────────┴─────────────────────────┴───────────────────┘
```

### 1. Family Circle (Shared Care)
A voluntary daily rhythm for families living under one roof or across continents:
- **Daily Reflection & Rhythm:** Express how you feel, log sleep quality, and confirm your daily routine in seconds.
- **Granular Sharing Permissions:** Every sharing toggle (vitals, sleep, check-in history) defaults to **OFF**. Members decide what to share, with whom, and can revoke sharing at any time.
- **Non-Clinical Human Prompts:** Missed check-ins gently prompt a family member to call or send a loving message, avoiding algorithmic panic or alarmist medical notifications.
- **Three-Step Member Wizard:** Effortless family invitation flow with relationship archetypes (Parent, Partner, Child, Sibling, Friend), single-use secure invite codes, and 7-day expiration.

### 2. Me Sanctuary (Confidential Wellness)
A strictly personal, zero-surveillance wellbeing refuge:
- **Curated Relaxation Modules:** Four mindful pathways—*Breathe*, *Unwind*, *Focus*, and *Rest*.
- **Guided Breathwork Pacer:** Smooth animated breathing ring pacer with customizable durations (2m, 5m, 15m, or custom).
- **Sequential Spoken Guidance:** Soft voice cues delivered via a non-overlapping text-to-speech queue that halts instantly upon pausing, exiting, or switching tabs.
- **Pre- and Post-Session Reflection:** Observe changes in your physiological relaxation before and after mindfulness exercises.
- **Zero Surveillance Guarantee:** Me sessions, reflections, and breathing logs are stored exclusively in owner-only Firestore documents. They cannot be viewed by family members, admins, or shared circles.

### 3. Emergency Assist (Safety-First Response)
A calm, structured workflow for sudden health concerns:
- **Instant Localized SOS:** Automatically surfaces the official emergency dispatch number based on region (e.g., **112** for India/EU, **911** for US/Canada, **999** for UK).
- **Incident Timeline:** Structured, timestamped event logging (observations, symptoms, comfort actions taken) for clear medical handover.
- **Dispatcher Handover Summary:** Generates an immediate exportable text summary ready to be read aloud to dispatchers or handed to attending paramedics.
- **Strict Safety Gate:** Designed to never delay CPR, 911/112 calls, or professional medical assistance. Emergency numbers are never dialed silently without explicit confirmation.

---

## 3. Privacy-First Architecture & Data Boundaries

caren is built from the ground up with zero-trust privacy boundaries:

- **Default-OFF Sharing:** When creating an invitation or adding a family member, all data-sharing permissions default to `false`. No data leaves a user's private domain without deliberate opt-in.
- **Owner-Isolated Firestore Paths:** Personal reflections and wellness logs live under `/users/{userId}/sessions/*`, protected by Firestore rules enforcing `request.auth.uid == userId`.
- **Atomic Invitation Acceptance:** Family circle joins execute via Firestore transactions, validating single-use invite codes, 7-day expiration, and authenticated email matching simultaneously.
- **Idempotent Check-Ins:** Daily check-ins use deterministic keys (`chk_{userId}_{dateKey}`), preventing duplicate writes during network fluctuations or offline synchronization.
- **Complete Account Deletion:** Purges user profiles, privacy settings, and private sessions immediately. Family check-in histories are cleanly anonymized to preserve family records without retaining personal data.

---

## 4. Medical Disclaimer & Non-Diagnostic Boundary

> ### ⚠️ IMPORTANT NOTICE
> **caren is NOT a medical device, nor is it intended for clinical diagnosis, treatment, prevention, or monitoring of any medical condition or disease.**
>
> - Camera-based pulse and wellness observations are non-diagnostic physiological estimates intended purely for personal wellness awareness and relaxation pacing.
> - In any potential medical emergency, **immediately contact your local emergency services (112, 911, 999) or proceed to the nearest emergency healthcare facility**.
> - Never delay, disregard, or discontinue professional medical advice due to information presented in this application.

---

## 5. Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile Framework** | [Flutter](https://flutter.dev/) (v3.24+) / [Dart](https://dart.dev/) (v3.5+) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) (v3.5.0) |
| **Routing & Navigation** | [GoRouter](https://pub.dev/packages/go_router) (v18.1.3) |
| **Backend & Cloud** | [Google Firebase](https://firebase.google.com/) (Authentication & Cloud Firestore) |
| **Offline Persistence** | Cloud Firestore Local Cache with metadata tracking (`hasPendingWrites`) |
| **Physiological Inference** | [Presage SmartSpectra Android SDK](https://physiology.presagetech.com/) (v3.4.0) via `libsmartspectra.so` |
| **Camera & Hardware Bridge** | Android CameraX (`androidx.camera.core:1.3.1`), Kotlin PlatformView |
| **Speech & Audio** | [flutter_tts](https://pub.dev/packages/flutter_tts) with serialized queue controller |
| **Typography & Fonts** | Locally bundled [Manrope](https://fonts.google.com/specimen/Manrope) (Regular, Medium, SemiBold, Bold) |
| **Rules Testing** | `@firebase/rules-unit-testing` (v3.0.4) on Mocha (v11.0.1) & Firebase Emulator |

---

## 6. Project Structure

```
caren/
├── android/                          # Native Android host project
│   ├── app/
│   │   ├── build.gradle.kts          # App-level build config, SDK injection
│   │   └── src/main/kotlin/.../smartspectra/ # CameraX PlatformView & SmartSpectra bridge
│   └── local.properties              # Local SDK paths & SMARTSPECTRA_API_KEY (gitignored)
├── assets/
│   ├── branding/                     # Approved brand assets (icon.png, wordmark_icon.png)
│   └── fonts/Manrope/                # Bundled Manrope font files (Regular, Medium, SemiBold, Bold)
├── firestore-rules-tests/            # Security rules unit test suite on Firebase Emulator
│   ├── package.json                  # Node.js test dependencies
│   └── test/
│       └── security_rules.spec.js    # 15 authorization & zero-trust test cases
├── firestore.rules                   # Zero-trust Cloud Firestore security rules
├── firebase.json                     # Firebase deployment & emulator configuration
├── lib/
│   ├── app/                          # App root, GoRouter definitions, theme
│   ├── core/                         # Design system, constants, base widgets, utilities
│   │   ├── constants/                # AppColors, AppTypography, AppSpacing, AppBranding
│   │   └── widgets/                  # AuthBrandHeader, CarenPasswordField, CarenCountryPickerField
│   ├── features/
│   │   ├── authentication/           # Auth domain models, FirebaseAuthRepository, login/register UI
│   │   ├── family/                   # Family circles, Add Member Wizard, check-ins, consent permissions
│   │   ├── wellness/                 # Me sanctuary, guided breathing, camera positioning
│   │   ├── assist/                   # Emergency timeline, observation logging, summary export
│   │   ├── profile/                  # User profile, privacy settings, account deletion
│   │   └── diagnostics/              # Developer diagnostics, native hardware preview inspector
│   ├── services/                     # Vitals providers (native & mock), Firebase init, TTS queue
│   └── main.dart                     # Application bootstrap
└── test/                             # Flutter unit, widget, and end-to-end integration tests
```

---

## 7. Prerequisites & System Requirements

Before running caren, verify your environment meets the following specifications:

- **Flutter SDK:** Version 3.24.0 or higher (`flutter --version`)
- **Dart SDK:** Version 3.5.0 or higher
- **Android SDK:**
  - `minSdkVersion`: 28 (Android 9.0 Pie)
  - `targetSdkVersion`: 34 (Android 14)
  - `compileSdkVersion`: 34
- **Java Development Kit (JDK):** JDK 17 or JDK 21 (configured with `JAVA_HOME`)
- **Node.js & npm:** Node.js v18+ or v20+ (required for Firestore security rules testing)
- **Firebase CLI:** Installed globally via `npm install -g firebase-tools`
- **Physical Test Device (Recommended):** Android device running Android 9+ with front-facing camera

---

## 8. SmartSpectra SDK & Credential Configuration

caren integrates the Presage SmartSpectra Android SDK (v3.4.0) to estimate pulse rate, respiration, and heart rate variability from front camera video feeds.

### Setting Up Your API Key
1. Obtain an authorized API key from the [Presage Developer Portal](https://physiology.presagetech.com).
2. Add your key to `android/local.properties` in your repository root:
   ```properties
   flutter.sdk=C:\\path\\to\\flutter
   sdk.dir=C:\\path\\to\\Android\\sdk
   SMARTSPECTRA_API_KEY=your_actual_presage_api_key_here
   ```
3. During compilation, `android/app/build.gradle.kts` securely injects `SMARTSPECTRA_API_KEY` into Kotlin via `BuildConfig.SMARTSPECTRA_API_KEY`.
4. `android/local.properties` is strictly excluded in `.gitignore` to prevent secret exposure.

> **Privacy Note:** Telemetry is disabled by default (`sdk.config.enableTelemetry = false`) to honor caren's zero-surveillance design.

---

## 9. Firebase Setup & Mock Fallback Mode

### 1. Application Package Identifier
```
com.caren.app.caren
```

### 2. Firebase Console Configuration
1. Open the [Firebase Console](https://console.firebase.google.com/) and create a project.
2. Register an **Android app** with package name `com.caren.app.caren`.
3. Download `google-services.json` and place it in `android/app/google-services.json`.
4. Under **Authentication > Sign-in method**, enable **Email/Password**.
5. Under **Firestore Database**, create a database and deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 3. Graceful Mock Mode Fallback
If `google-services.json` is not present:
- The Gradle build detects its absence and builds cleanly.
- `FirebaseService.initialize()` catches missing credentials gracefully.
- caren activates in-memory mock repositories (`MockAuthRepository`, `LocalFamilyRepository`).
- All screens, Onboarding, Developer Diagnostics, Guided Breathing, and camera positioning remain fully testable without network or cloud credentials.

---

## 10. Installation & Dependencies

### 1. Flutter Dependencies
```bash
flutter pub get
```

### 2. Firestore Emulator Test Suite Dependencies
```bash
cd firestore-rules-tests
npm install
cd ..
```

---

## 11. Running the Application

### Launching in Debug Mode
Ensure a physical Android device or emulator is running:
```bash
# Check connected devices
flutter devices

# Run on selected device
flutter run -d <DEVICE_ID>
```

### Developer Diagnostics Mode
When running in debug mode, a diagnostics icon appears in the top brand header, providing:
- Real-time provider inspection (Mock vs. Native SmartSpectra).
- CameraX platform view lifecycle verification.
- Live native frame feedback (`OK`, `CAMERA_TUNING`, `NO_FACE_DETECTED`, `TOO_DARK`, `EXCESSIVE_MOTION`).
- Direct navigation across all application journeys.

---

## 12. Verification & Testing

### 1. Static Analysis
Run Flutter static analysis to verify code quality:
```bash
flutter analyze
```
*Current status: 0 issues found.*

### 2. Flutter Unit & Widget Test Suite
Run the automated test suite (115+ tests covering authentication, branding, country selector, breathing ring, camera positioning, and family flows):
```bash
flutter test
```
*Current status: All 115 tests passing.*

### 3. Firestore Security Rules Unit Tests
Execute the security test suite against a live Cloud Firestore emulator instance:
```bash
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```
*Current status: 15/15 authorization tests passing.*

---

## 13. Build Instructions

### 1. Compile Native Android Kotlin
```bash
cd android
./gradlew compileDebugKotlin
cd ..
```

### 2. Build Debug APK
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### 3. Build Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 14. Real Hardware Observations & Verification

caren was extensively validated on real Android hardware:

| Parameter | Specification / Observation |
|---|---|
| **Primary Test Hardware** | Samsung Galaxy M12 (`SM-M127G`, Android 13, API 33) |
| **Camera Sensor** | 8 MP Front Camera (`f/2.2`) |
| **Lighting Sensitivity** | In low-light environments (<150 lux), CameraX auto-exposure adjustments trigger `CAMERA_TUNING`. The app safely warns the user rather than fabricating readings. |
| **Stability Gate** | Vitals measurement start is disabled until face positioning and lighting achieve `OK` status for 2 continuous seconds. |
| **Thermal & CPU Profile** | Peak memory consumption remains under 165 MB during real-time CameraX preview streaming. |

---

## 15. Offline Capability & Data Sync

- **Full Offline Check-Ins:** Check-ins submitted without internet connectivity are cached in Firestore's local persistent storage.
- **Visual Sync Status:** The UI displays a warm, reassuring `Saved offline (Sync pending)` badge while offline.
- **Automatic Reconnection Sync:** Once connectivity is restored, writes synchronize transparently to Cloud Firestore with idempotent deduplication.

---

## 16. Security & Secret Management Policy

- **Zero Committed Secrets:** `android/local.properties`, `google-services.json`, keystores (`*.jks`, `*.keystore`), and debug logs are strictly ignored in `.gitignore`.
- **Single-Source Passwords:** Password confirmation fields validate solely in client memory; confirmation values are never transmitted to Firebase Authentication.
- **Client Sanitization:** Authentication error messages from Firebase are sanitized into friendly, non-revealing human phrases.

---

## 17. Release Verification Matrix

| Subsystem | Status | Verification Notes |
|---|---|---|
| **Brand Identity & Typography** | ✅ Verified | Manrope font bundled locally; wordmark and emblem rendered accurately without distortion. |
| **Authentication Polish** | ✅ Verified | Unified `AuthBrandHeader`, password show/hide toggle, real-time match validation, 52dp country selector. |
| **Onboarding Flow** | ✅ Verified | Editorial carousel, responsive card layout, non-clinical messaging. |
| **Family Circle & Wizard** | ✅ Verified | 3-step invitation wizard, default-OFF permissions, relationship archetypes. |
| **Me Sanctuary & Breathwork** | ✅ Verified | Visual ring pacing, serialized TTS queue, owner-only data isolation. |
| **Emergency Assist** | ✅ Verified | Localized emergency number resolution, structured handover export. |
| **Firestore Security Rules** | ✅ Verified | 15/15 tests passing on Cloud Firestore Emulator. |
| **Physical Hardware** | ✅ Verified | Tested on Samsung Galaxy M12 (`SM-M127G`). |

---

## 18. License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

```
Copyright (c) 2026 caren contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

<p align="center">
  <strong>caren</strong> — Care, closer.
</p>
