# CAREN: Care, closer.

**CAREN** is a personal and family wellness mobile application designed to help people stay gently connected to the wellbeing of the people they care about, while also making deliberate space for their own health and peace of mind.

---

## 1. Product Experiences

CAREN connects three core wellness experiences in a single, calm interface:

### Family Circle
A respectful, non-invasive daily check-in system for families living near or far.
- **Voluntary Daily Check-Ins:** Simple, configurable questions regarding feeling, sleep, and routine.
- **Camera-Based Vitals (Optional):** Optional physiological spot-checks powered by Presage SmartSpectra.
- **Transparent Sharing:** Members explicitly choose what information to share with family members. Permissions are granular and revocable at any time.
- **Human Connection:** Missed check-ins prompt gentle human follow-up rather than alarmist medical alerts.
- **Dignity First:** Designed for care, not surveillance.

### Me Sanctuary
A private, personal wellness experience kept strictly confidential.
- **Guided Breathing & Relaxation:** Configurable sessions (2, 3, 5, or 10 minutes) with an interactive breathing ring pacer.
- **Pre- and Post-Session Observation:** Optional pulse rate spot-checks before and after breathing sessions to observe physiological relaxation.
- **Zero Surveillance:** Personal history and trends remain private on device by default. Family members are never notified when someone uses the Me experience.

### Assist Flow
A safety-first, non-diagnostic workflow for documenting sudden situations when someone nearby appears unwell.
- **Incident Timeline:** Structured, timestamped logging of observations, symptoms, and comfort actions taken.
- **Prominent Emergency Action:** Quick access to the localized emergency services number (defaults to India **112**, dynamically localized per profile). Never dials automatically.
- **Medical Summary Generation:** Formats an exportable, chronological summary ready to hand over to dispatchers or healthcare professionals.
- **Safety Boundary:** Never delays emergency services, CPR, or dispatcher instructions. Non-diagnostic.

---

## 2. Technology Architecture

- **Mobile Framework:** [Flutter](https://flutter.dev/) (Dart 3.13+)
- **State Management:** [Flutter Riverpod](https://riverpod.dev/) (v3.5.0)
- **Routing & Navigation:** [GoRouter](https://pub.dev/packages/go_router) (v18.1.3)
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Native Android:** Kotlin, Android SDK API Level 28+ (`minSdk = 28`), CameraX
- **Vitals Inference Engine:** [Presage SmartSpectra Android SDK](https://smartspectra.presagetech.com/) (v3.4.0)
- **Security & Rules:** Cloud Firestore security rules enforcing mutual, verified family permissions and strict owner-only access for personal data.

---

## 3. Local Development Prerequisites

- **Flutter SDK:** 3.47.0 or higher
- **Dart SDK:** 3.13.0 or higher
- **Android Studio / Command Line Tools:** Android SDK Build-Tools, API Level 28 minimum, API Level 34 target
- **Java Development Kit (JDK):** JDK 17 or JDK 21 (configured for Gradle 9.3+)
- **Operating System:** Windows, macOS, or Linux

---

## 4. SmartSpectra Credential Configuration

CAREN integrates with the Presage SmartSpectra SDK to measure pulse rate, breathing rate, and heart rate variability (HRV) from camera video.

### Adding your API Key

1. Obtain a developer API key from the [Presage Developer Portal](https://physiology.presagetech.com).
2. Open or create `android/local.properties` in your local project root:
   ```properties
   flutter.sdk=...
   sdk.dir=...
   SMARTSPECTRA_API_KEY=your_presage_api_key_here
   ```
3. During Gradle compilation, `android/app/build.gradle.kts` securely loads `SMARTSPECTRA_API_KEY` and injects it into native Kotlin via `BuildConfig.SMARTSPECTRA_API_KEY`.
4. `android/local.properties` is strictly ignored by Git (`.gitignore`) to prevent accidental credential leakage.

> **Privacy Note:** In compliance with CAREN privacy principles, SDK diagnostic telemetry is explicitly disabled by default (`sdk.config.enableTelemetry = false`) during native bridge initialization.

---

## 5. Running and Testing the Application

### 1. Fetch Dependencies
```bash
flutter pub get
```

### 2. Run Static Analysis
```bash
flutter analyze
```

### 3. Run Automated Tests
```bash
flutter test
```
The test suite validates:
- Mock vitals simulation and confidence window enforcement (12s Pulse, 30s Breathing, 60s HRV).
- Native Platform Channel contracts and permission error handling.
- UI accessibility, touch targets (minimum 48dp), and localized emergency actions.

### 4. Build and Verify Android Native Pipeline
```bash
cd android
./gradlew compileDebugKotlin
```

### 5. Launch the Application
```bash
flutter run
```

---

## 6. Supported Platforms and Current Limitations

| Platform | Support Status | Capabilities |
|---|---|---|
| **Android (API 28+)** | Supported (Hardware Ready) | Full UI, CameraX PreviewView PlatformView, SmartSpectra 3.4.0 Kotlin bridge. |
| **iOS** | In Progress (Phase 2) | Full UI and Mock vitals simulation; Swift native SDK bridge planned. |
| **Desktop / Web** | Development Only | Full UI preview and development with simulated mock vitals. |

### Physiological Confidence Windows
SmartSpectra measurements adhere strictly to scientific signal confidence windows:
- **Pulse Rate:** 12 seconds minimum observation.
- **Breathing Rate:** 30 seconds minimum observation with steady posture.
- **Heart Rate Variability (HRV):** 60 seconds continuous observation.

Measurements stopped before the required confidence window are treated as incomplete and are never presented as validated clinical readings.
