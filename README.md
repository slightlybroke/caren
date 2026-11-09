# caren: Care, closer.

**caren** is a personal and family wellbeing mobile application designed to help people stay gently connected to the wellbeing of their loved ones, while making deliberate, confidential space for their own health and peace of mind.

---

## 1. Product Overview & Core Experiences

caren connects three core experiences within a calm, non-invasive interface:

### Family Circle
A voluntary daily check-in system for families living together or apart.
- **Voluntary Daily Check-Ins:** Brief check-ins covering feelings, sleep, and routine.
- **Optional Camera-Based Vitals:** Non-diagnostic physiological spot-checks powered by Presage SmartSpectra.
- **Explicit Consent & Granular Sharing:** Members choose exactly what information to share with family members. Permissions are granular and revocable at any time.
- **Offline Reliability:** Check-ins submitted while disconnected are cached locally with an automatic `Saved offline (Sync pending)` indicator, and synchronize seamlessly with idempotent deduplication when reconnected.
- **Human Connection:** Missed check-ins prompt gentle human reach-out rather than alarmist automated medical notifications.

### Me Sanctuary
A private personal wellness space kept strictly confidential.
- **Guided Relaxation Activities:** Four curated categories—Breathe, Unwind, Focus, and Rest.
- **Guided Breathing Ring Pacer:** Configurable durations (2 to 60 minutes) with animated visual ring pacing.
- **Sequential Voice Guidance:** Spoken instructions serialized via a non-overlapping TTS queue that cleanly halts on pause, route disposal, or cancellation.
- **Pre- and Post-Session Observation:** Optional pulse rate spot-checks to observe physiological relaxation.
- **Zero Surveillance Guarantee:** Personal history, breathwork sessions, and physiological trends are stored strictly in private, owner-only documents. Family members are never alerted to a user's Me activities.

### Assist Flow (Emergency)
A safety-first, non-diagnostic workflow for unexpected situations.
- **Incident Timeline:** Structured, timestamped logging of observations, symptoms, and comfort actions.
- **Localized Emergency Number:** Prominent quick-access to the local emergency service (e.g., **112** for India, dynamically resolved). Never dials automatically without user confirmation.
- **Exportable Medical Handover:** Generates a structured chronological summary ready for emergency dispatchers or attending healthcare personnel.
- **Safety Boundary:** Explicitly designed to never delay emergency services, CPR, or official dispatcher instructions.

---

## 2. Technology Stack

- **Mobile Framework:** [Flutter](https://flutter.dev/) (Dart 3.5+ / Flutter 3.24+)
- **State Management:** [Flutter Riverpod](https://riverpod.dev/) (v3.5.0)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (v18.1.3)
- **Backend & Cloud:** Google Firebase (Firebase Authentication, Cloud Firestore)
- **Local Cache & Offline:** Cloud Firestore offline persistence with metadata tracking (`hasPendingWrites`)
- **Native Android Engine:** Kotlin, Android CameraX (`androidx.camera.core:1.3.1`), PlatformView
- **Physiological Inference Engine:** [Presage SmartSpectra Android SDK](https://smartspectra.presagetech.com/) (v3.4.0) via `libsmartspectra.so`
- **Speech Synthesis:** [flutter_tts](https://pub.dev/packages/flutter_tts) with serialized queue controller
- **Rules Testing Engine:** `@firebase/rules-unit-testing` (v3.0.4) on Mocha (v11.0.1) and Firebase Emulator Suite

---

## 3. Architecture & Project Structure

The project follows a feature-driven, layered clean architecture:

```
caren/
├── android/                          # Native Android host project
│   ├── app/
│   │   ├── build.gradle.kts          # App-level build config, SDK injection
│   │   └── src/main/kotlin/.../smartspectra/ # CameraX PlatformView & SmartSpectra bridge
│   └── local.properties              # Local SDK paths and SMARTSPECTRA_API_KEY (gitignored)
├── firestore-rules-tests/            # Security rules unit tests on Firebase Emulator
│   ├── package.json                  # Node.js test dependencies
│   └── test/
│       └── security_rules.spec.js    # 15 authorization & attack test cases
├── firestore.rules                   # Zero-trust Cloud Firestore security rules
├── firebase.json                     # Firebase deployment & emulator configuration
├── lib/
│   ├── app/                          # App root, GoRouter definitions, theme
│   ├── core/                         # Design system, constants, base widgets, utilities
│   │   ├── constants/                # AppColors, AppTypography, AppSpacing
│   │   └── widgets/                  # CarenAppBar, StatusBadge, VitalsMeasurementWidget
│   ├── features/
│   │   ├── authentication/           # Auth domain models, FirebaseAuthRepository, login/register UI
│   │   ├── family/                   # Family circles, invitations, check-ins, consent permissions
│   │   ├── wellness/                 # Me sanctuary, guided breathing, camera positioning
│   │   ├── assist/                   # Emergency timeline, observation logging, summary export
│   │   ├── profile/                  # User profile, privacy settings, account deletion
│   │   └── diagnostics/              # Developer diagnostics, native hardware preview inspector
│   ├── services/                     # Vitals providers (native & mock), Firebase init, TTS queue
│   └── main.dart                     # Application bootstrap
└── test/                             # Flutter widget, domain, and flow unit test suites
```

---

## 4. Prerequisites

Before setting up the project, ensure your workstation has:

- **Flutter SDK:** Version 3.24.0 or higher (`flutter --version`)
- **Dart SDK:** Version 3.5.0 or higher
- **Android SDK:**
  - `minSdkVersion`: 28 (Android 9.0 Pie)
  - `targetSdkVersion`: 34 (Android 14)
  - `compileSdkVersion`: 34
- **Java Development Kit (JDK):** JDK 17 or JDK 21 (configured with `JAVA_HOME`)
- **Node.js & npm:** Node.js v18+ or v20+ (required for Firestore rules unit testing)
- **Firebase CLI:** Installed globally via `npm install -g firebase-tools`
- **Physical Device (Recommended for Vitals):** Android phone with API 28+ and a front-facing camera

---

## 5. SmartSpectra SDK & Credential Setup

caren uses Presage SmartSpectra v3.4.0 to measure pulse rate, breathing rate, and heart rate variability (HRV) from front-facing camera video.

### Adding your API Key
1. Obtain an API key from the [Presage Developer Portal](https://physiology.presagetech.com).
2. Open or create `android/local.properties` in your repository root:
   ```properties
   flutter.sdk=C:\\path\\to\\flutter
   sdk.dir=C:\\path\\to\\Android\\sdk
   SMARTSPECTRA_API_KEY=your_actual_presage_api_key_here
   ```
3. During compilation, `android/app/build.gradle.kts` securely reads `SMARTSPECTRA_API_KEY` from `local.properties` and exposes it to Kotlin via `BuildConfig.SMARTSPECTRA_API_KEY`.
4. `android/local.properties` is strictly excluded in `.gitignore` to prevent credential exposure.

> **Privacy Note:** Native bridge initialization disables telemetry by default (`sdk.config.enableTelemetry = false`) to adhere to caren's zero-surveillance principles.

---

## 6. Firebase Configuration & Fallback Mode

caren uses Firebase Authentication for user accounts and Cloud Firestore for family coordination.

### 1. Application Package Name
```
com.caren.app.caren
```

### 2. Firebase Console Setup
1. Open the [Firebase Console](https://console.firebase.google.com/) and create a project.
2. Add an **Android app** with package name `com.caren.app.caren`.
3. Download `google-services.json` and place it in:
   ```
   android/app/google-services.json
   ```
4. In **Authentication > Sign-in method**, enable **Email/Password**.
5. In **Firestore Database**, create a database (production mode).
6. Deploy the security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 3. Graceful Fallback (Mock Mode)
If `google-services.json` is not present:
- The Gradle build detects its absence and compiles without failing.
- `FirebaseService.initialize()` catches missing configuration cleanly.
- caren automatically falls back to in-memory mock repositories (`MockAuthRepository`, `LocalFamilyRepository`).
- All UI screens, the Developer Diagnostics tab, guided breathing, and native camera positioning remain testable without cloud credentials.

---

## 7. Installation & Dependency Commands

### 1. Flutter Dependencies
```bash
flutter pub get
```

### 2. Firestore Emulator Test Dependencies
```bash
cd firestore-rules-tests
npm install
cd ..
```

---

## 8. Running the Application

### Launch in Debug Mode
Ensure a physical Android device or emulator is running:
```bash
# List available devices
flutter devices

# Run on selected device
flutter run -d <DEVICE_ID>
```

### Inspecting Developer Diagnostics
Navigate to **Settings / Diagnostics** in the app to:
- Inspect active provider mode (Mock vs. Native SmartSpectra).
- Verify CameraX platform view lifecycle.
- Observe real-time native validation codes (`OK`, `CAMERA_TUNING`, `NO_FACE_DETECTED`, `TOO_DARK`, `EXCESSIVE_MOTION`).

---

## 9. Testing & Security Verification

### 1. Static Analysis
Run Flutter static analysis to ensure zero warnings and errors:
```bash
flutter analyze
```

### 2. Flutter Unit & Widget Tests
Run the complete test suite (93 tests covering auth, navigation, breathing, relaxation, camera positioning, and family flows):
```bash
flutter test
```

### 3. Firebase Emulator Suite Rules Tests
Execute the automated security test suite against a real Cloud Firestore emulator instance:
```bash
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```
This suite verifies:
- Non-members cannot read family circles or member check-ins.
- Members cannot elevate their roles or alter other members' consent settings.
- Invitations require verified email matching, pending status, and 7-day validity.
- Expired, revoked, or already-claimed invitations cannot be used.
- Private Me sanctuary sessions (`/users/{userId}/sessions/*`) are strictly owner-only.

---

## 10. Build Instructions

### 1. Compile Native Android Kotlin Code
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

> **Note on Release Signing:** The repository currently falls back to debug signing keys in `build.gradle.kts` until production release keystores are provisioned in your CI/CD deployment pipeline.

---

## 11. Security, Privacy & Secret Management

- **Zero Secrets in Repository:** `local.properties`, `google-services.json`, keystores (`*.jks`, `*.keystore`), and log files are strictly excluded via `.gitignore`.
- **Atomic Transactions:** Invitation acceptance uses `_firestore.runTransaction` to eliminate race conditions between simultaneous acceptances and admin revocations.
- **Idempotent Check-Ins:** Check-in document IDs use deterministic keys (`chk_${userId}_${dateKey}`) and `SetOptions(merge: true)` to ensure network retries never produce duplicate entries.
- **Data Lifecycle & Anonymization:** Deleting an account (`deleteAccount()`) purges the user profile, privacy settings, and private Me sessions. Daily check-in records in family circles are anonymized to maintain historical family continuity without orphaned references.

---

## 12. Known Limitations & Verification Status

| Feature / Subsystem | Verification Status | Notes / Limitations |
|---|---|---|
| **Android Hardware (Samsung Galaxy M12)** | Verified on Device | CameraX front camera preview and native bridge validated. Under low-light conditions, auto-exposure timeout halts measurement as a safety fail-safe. |
| **Firestore Security Rules** | Verified on Emulator | 15/15 tests passing on Cloud Firestore Emulator v13.34.0. |
| **Offline Check-In Queue** | Implemented & Tested | Firestore local cache stores writes; pending status indicated via `hasPendingWrites`. |
| **iOS Native Bridge** | Phase 2 (Planned) | Flutter UI and Mock vitals fully supported on iOS; native Swift SmartSpectra bridge planned for future phase. |
| **Medical Disclaimer** | Fundamental Boundary | caren is a personal and family wellbeing companion, **not** an FDA-cleared diagnostic device or medical monitor. It does not diagnose, treat, or prevent medical conditions. |

---

## 13. License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

