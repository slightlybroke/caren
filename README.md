<div align="center">

  <img src="assets/branding/icon.png" alt="caren emblem" width="96" height="96" style="border-radius: 20px;" />

  # caren
  ### Care, closer.

  **An open-source family wellbeing companion and personal sanctuary.**  
  *Voluntary check-ins, mindful routines, contactless optical vitals, and one-tap emergency assist.*

  <br/>

  [![License: MIT](https://img.shields.io/badge/License-MIT-174F47.svg?style=flat-square)](LICENSE)
  [![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B.svg?style=flat-square&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2.svg?style=flat-square&logo=dart)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-32675F.svg?style=flat-square)](https://github.com/slightlybroke/caren)
  [![Tests](https://img.shields.io/badge/Tests-116%20Passing-2E7D32.svg?style=flat-square)](test/)
  [![Code Style](https://img.shields.io/badge/Code%20Style-Flutter%20Lints-388E3C.svg?style=flat-square)](analysis_options.yaml)

  <br/>

  [**🌐 Try Live Web Demo**](https://try-caren.vercel.app) &nbsp;•&nbsp; 
  [**📱 Download Android APK (v1.0.0)**](https://github.com/slightlybroke/caren/releases/tag/android-demo-v1) &nbsp;•&nbsp; 
  [**📖 Architecture**](ARCHITECTURE.md) &nbsp;•&nbsp; 
  [**🤝 Contributing**](CONTRIBUTING.md) &nbsp;•&nbsp; 
  [**🔒 Security & Privacy**](SECURITY.md)

</div>

---

## 🌿 Overview

Millions of families live across different cities, provinces, and time zones. When supporting aging parents, partners, or loved ones living independently, everyday communication often turns into a delicate tension: asking *"Did you take your pills? How are your vitals today?"* can feel like intrusive surveillance, while staying silent brings quiet anxiety.

**caren** is designed to dissolve that tension. Built on the **Serene Hearth** design system, caren brings gentle daily care, private grounding routines, contactless wellness spot-checks, and emergency dispatch into one calm, non-stigmatizing experience.

### Core Principles
- **Sovereign Consent:** All check-ins and shared metrics are 100% voluntary and self-directed. Sharing permissions are granular and revocable at any moment. Zero passive or background tracking.
- **Private by Default:** The personal sanctuary (`Me`) is completely quarantined on-device—guided breathing and reflections are never shared with family circles.
- **Contactless Sensing:** Integrated with the **Presage SmartSpectra SDK (3.4.0)**, allowing users to estimate pulse and breathing pace using their smartphone's front-facing camera with real-time positioning feedback—no wearables required.
- **Immediate Help:** One-tap emergency calling with localized dispatch resolution (112 / 911 / 999) and a structured medical handover card for first responders.

---

## ✨ Features

```
┌────────────────────────────────────────────────────────────────────────┐
│                              caren                                     │
├─────────────────────┬─────────────────────┬────────────────────────────┤
│   👨‍👩‍👧 Family Circle   │   🧘 Me Sanctuary   │    🚨 Emergency Assist     │
├─────────────────────┼─────────────────────┼────────────────────────────┤
│ • Voluntary check-in│ • Guided breathing  │ • One-tap emergency call   │
│ • Energy & sleep    │ • 5 Senses Grounding│ • Localized dispatch (112) │
│ • Routine tracking  │ • Wall-clock timers │ • Symptom handover log     │
│ • Gentle reminders  │ • Personal history  │ • Clipboard summary card   │
│ • Granular privacy  │ • 100% quarantined │ • Confirmation safety gate │
└─────────────────────┴─────────────────────┴────────────────────────────┘
```

### 1. Family Circle (Voluntary Reassurance)
Stay connected across distances with voluntary, reassuring check-ins. Family members choose what and when to share.
- Daily check-in captures self-reported energy, sleep reflection, routine medication adherence, and optional notes.
- Status badges give family members peace of mind at a glance (`Checked In`, `Pending`).
- Gentle, respectful reminders with zero surveillance pressure.

### 2. Me Sanctuary (Personal Mindfulness)
A private, calming sanctuary designed for personal self-care and grounding.
- **Guided Paced Breathing:** Visually guided inhale/exhale cycles (4s inhale / 6s exhale) with optional voice coaching and mute controls. Supports quick durations (2m, 5m, 15m) or custom durations.
- **5 Senses Sensory Grounding:** Guided grounding steps to reduce situational stress and regain calm.
- **Personal Trend History:** Private resting pulse and breathing trends stored locally.

### 3. Contactless Vitals via Presage SmartSpectra
Powered by the **Presage SmartSpectra 3.4.0 SDK** on Android:
- Estimates pulse rate and respiration pace using remote photoplethysmography (rPPG).
- **Intelligent Preflight:** Camera auto-exposure and face positioning must achieve stable alignment for 2 continuous seconds before measurement begins.
- **Real-Time Visual PPG Waveform:** Visual feedback confirms blood volume pulse signal acquisition in real time.
- **Web Demo Experience:** On modern browsers, caren streams the user's front camera directly inside the phone frame, giving visitors an authentic, interactive preview of the positioning and spot-check workflow.

### 4. Emergency Assist & Handover
Practical safety support when immediate help is needed:
- **Instant Emergency Dialer:** Resolves national dispatch numbers automatically (e.g., `112` for Europe/India, `911` for US/Canada, `999` for UK) based on profile country.
- **Explicit Safety Confirmation:** Two-step confirmation ensures the dialer is never triggered unintentionally.
- **Medical Handover Card:** Records user-observed symptoms and timing into a structured summary that first responders can read or copy to clipboard immediately.

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.13.0`, tested on Flutter 3.47.5 stable)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.13.0`)
- Android Studio / VS Code with Flutter extension
- An Android device running Android 9+ (API 28+) for live native camera vitals, or any modern web browser for the web demo

### 1. Clone & Install
```sh
git clone https://github.com/slightlybroke/caren.git
cd caren
flutter pub get
```

### 2. Run on Web (Instant Exploration)
Run the responsive desktop presentation shell with the interactive phone frame:
```sh
flutter run -d chrome
```
*Click **"Explore the Live Demo"** on the landing page to instantly sign in as **John Doe** and explore the seeded Family Circle without creating an account.*

### 3. Run on Android
Connect your Android phone with USB debugging enabled:
```sh
flutter devices
flutter run -d <device-id>
```

#### Optional: Configuring Presage SmartSpectra for Live Android Readings
The demo APK and local builds include seamless fallback data. To enable live optical vital measurement via the official Presage SDK on physical hardware:
1. Register for an API key at the [Presage Developer Portal](https://physiology.presagetech.com).
2. Create or edit `android/local.properties`:
   ```properties
   SMARTSPECTRA_API_KEY=your_presage_api_key_here
   ```
3. Re-run `flutter run -d <device-id>`. The app will automatically initialize the native CameraX pipeline and SmartSpectra SDK.

#### Optional: Connecting Your Own Firebase Project
caren runs completely standalone using local in-memory repositories by default. To connect your own live Firebase backend:
1. Create a Firebase project with Email/Password authentication and Cloud Firestore.
2. Register the Android package name `com.caren.app.caren`.
3. Download `google-services.json` and place it in `android/app/google-services.json`.
4. Deploy the checked-in security rules:
   ```sh
   firebase deploy --only firestore:rules,firestore:indexes
   ```

---

## 🏗️ Architecture & Technology Stack

caren follows **Clean Architecture** with a feature-first folder organization:

```
lib/
├── app/                  # Application bootstrap, router (GoRouter), and themes
│   ├── app.dart
│   └── router/app_router.dart
├── core/                 # Shared design system, constants, and reusable widgets
│   ├── constants/        # AppColors, AppTypography, AppSpacing, AppBranding
│   ├── config/           # DemoConfig (seeded identities)
│   ├── theme/            # Serene Hearth ThemeData
│   └── widgets/          # WebResponsiveShell, CarenButton, CarenCard, WebCameraPreview
├── features/             # Domain & Presentation feature slices
│   ├── authentication/   # Auth controller, login, registration
│   ├── dashboard/        # MainScaffoldScreen (StatefulShellRoute with 3 tabs)
│   ├── family/           # FamilyDashboard, DailyCheckIn, MemberDetail, AddMemberWizard
│   ├── wellness/         # MeDashboard, GuidedBreathing, GuidedActivity, CameraPositioning
│   ├── emergency/        # EmergencyLanding, EmergencySession (handover)
│   └── profile/          # ProfileSettings, PrivacyPermissions
└── services/             # Platform integrations and infrastructure
    ├── emergency/        # EmergencyDialerService
    ├── firebase/         # FirebaseService bootstrap
    ├── speech/           # SpokenGuidanceService (TTS voice cues)
    └── vitals/           # VitalsProvider, NativeVitalsProvider, MockVitalsProvider
```

For an in-depth breakdown of state management, data pipelines, and platform channels, see [**ARCHITECTURE.md**](ARCHITECTURE.md).

---

## 🧪 Testing & Code Quality

caren maintains high quality standards with unit, widget, and authorization tests:

```sh
# 1. Run static analysis (0 warnings)
flutter analyze

# 2. Run unit & widget test suite (116 tests)
flutter test

# 3. Test Firestore Security Rules in local emulator
npm ci --prefix firestore-rules-tests
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```

---

## 🎨 Serene Hearth Design System

caren uses the **Serene Hearth** design system—an organic, warm minimalist design language:

| Token | Hex | Role | Contrast Ratio |
| :--- | :--- | :--- | :--- |
| **Deep Forest** | `#174F47` | Primary brand & active indicators | **8.5:1** on background (WCAG AAA) |
| **Warm Ivory** | `#FAF9F4` | App canvas & background surface | Baseline surface |
| **Soft Sage** | `#E8F2ED` | Secondary containers & subtle chips | Soft, tranquil accents |
| **Warm Peach** | `#F3D7C3` | Celebration & highlight accents | Human, comforting warmth |
| **Emergency Crimson** | `#C94A4A` | Immediate assist & danger states | High-urgency alert |
| **Charcoal Ink** | `#1B1C19` | Primary typography | **15.2:1** on background |

---

## 🔒 Security & Privacy Charter

- **No Passive Tracking:** caren never runs camera, microphone, or location sensors in the background.
- **On-Device Optical Analysis:** When taking a wellness check, frames are analyzed in memory on-device by SmartSpectra to extract blood volume pulse signals; raw video recordings are never saved to disk or transmitted to remote servers.
- **Consent Isolation:** Data recorded in the `Me` sanctuary stays quarantined in private local storage and cannot be read by other family members.
- **Non-Clinical Notice:** caren’s wellness spot-checks are designed for personal awareness and family reassurance. They do not constitute diagnostic medical advice.

For full disclosure and policy details, see [**SECURITY.md**](SECURITY.md).

---

## 🤝 Contributing

We welcome contributions from the open-source community! Whether fixing a bug, improving documentation, or refining animations, please read our [**CONTRIBUTING.md**](CONTRIBUTING.md) guide before opening a pull request.

Please review our [**Code of Conduct**](CODE_OF_CONDUCT.md) to keep our community welcoming and supportive.

---

## 📄 License

caren is open-source software licensed under the [**MIT License**](LICENSE).  
The Presage SmartSpectra SDK is copyrighted by [Presage Technologies](https://presagetech.com) and subject to its developer license terms.
