# caren Architecture Guide

This document describes the architectural principles, data flow, component hierarchy, and platform integration bridges of **caren**.

---

## 1. High-Level Architecture Overview

caren is built with **Flutter 3.47** and **Dart 3.13**, adhering strictly to **Clean Architecture** patterns organized by feature slices. The codebase separates domain business logic from UI rendering, infrastructure, and native platform bindings.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                            │
│  StatefulShellRoute (GoRouter) • Serene Hearth Design System Tokens    │
│  WebResponsiveShell (Desktop 2-Panel) • Widgets • Screen Controllers   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Watches State / Triggers Events
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                           APPLICATION LAYER                            │
│   Riverpod Notifiers (AsyncNotifier, StateNotifier, StreamProvider)    │
│   DemoConfig • Navigation Guards • Semantic Preflight Validators       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Calls Use Cases & Repositories
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                             DOMAIN LAYER                               │
│  Entities & Value Objects (DailyCheckIn, FamilyMember, AssistSession)  │
│  Pure business rules • Validation semantics • Sovereign Consent Policies│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Implements Contracts
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                │
│   Repository Implementations (Local In-Memory ◄──► Cloud Firestore)    │
│   Decoupled Storage (Stub vs IO Session Storage) • Emergency Directory │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Platform Channels / Web APIs
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         INFRASTRUCTURE & PLATFORM                      │
│   Android: CameraX + Presage SmartSpectra 3.4.0 AAR (Method/EventChannel)│
│   Web: HTML5 navigator.mediaDevices getUserMedia + PlatformViewRegistry│
│   Audio: flutter_tts (Spoken Guidance) • Cloud Firestore & Firebase Auth│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with Serene Hearth theme
│   └── router/app_router.dart     # GoRouter configuration with StatefulShellRoute
├── core/
│   ├── constants/                 # Design tokens (AppColors, AppTypography, AppSpacing)
│   ├── config/                    # Seeded demo configuration (John Doe, Eleanor Doe)
│   ├── theme/                     # Serene Hearth ThemeData definition
│   └── widgets/                   # Reusable UI primitives (Buttons, Cards, Badges, Shell)
├── features/
│   ├── authentication/            # Sign in, registration, password reset, auth notifier
│   ├── dashboard/                 # Main navigation shell with 3 persistent branches
│   ├── family/                    # Voluntary check-in flow, family cards, 3-step wizard
│   ├── wellness/                  # Me sanctuary, guided breathing, grounding, camera check
│   ├── emergency/                 # Localized emergency assist, medical handover timeline
│   └── profile/                   # Identity settings, privacy & granular sharing controls
└── services/
    ├── emergency/                 # Dial launcher service & international directories
    ├── firebase/                  # Dual-mode Firebase / in-memory local fallback service
    ├── speech/                    # TTS spoken guidance service with queued dispatch
    └── vitals/                    # SmartSpectra native provider, mock provider, storage
```

---

## 3. Navigation & Presentation Shell

caren uses **GoRouter** with a **StatefulShellRoute.indexedStack** to preserve tab state across user navigation:

- **Branch 0 (`/family`):** Family dashboard, member details, reports, daily check-in, and member invitation wizard.
- **Branch 1 (`/me`):** Personal sanctuary, guided breathing, sensory grounding, and personal trend charts.
- **Branch 2 (`/emergency`):** Localized emergency assist and structured handover session.

### Responsive Presentation Shell (`WebResponsiveShell`)
On desktop and wide viewports (`width >= 960px`):
1. **Left Panel:** Editorial branding, auto-advancing feature carousel, and one-click demo login.
2. **Right Panel:** Realistic centered smartphone frame (iPhone Pro mockup with Dynamic Island and status bar simulation) containing the live, interactive Flutter application.
3. On mobile viewports (`width < 960px`), the app passes through natively for full-screen touch interaction.

---

## 4. Presage SmartSpectra 3.4.0 Integration

caren integrates **Presage SmartSpectra 3.4.0** natively on Android to deliver remote photoplethysmography (rPPG).

```
┌─────────────────────────────────┐
│     Front Camera (CameraX)      │
└────────────────┬────────────────┘
                 │ High-rate Frame Stream
                 ▼
┌─────────────────────────────────┐
│ Presage SmartSpectra 3.4.0 SDK  │ ──► Lighting & Positioning Semantic Analysis
└────────────────┬────────────────┘
                 │ EventChannel Stream
                 ▼
┌─────────────────────────────────┐
│   Flutter NativeVitalsProvider  │ ──► Real-Time Stability Gate & Live PPG Waveform
└────────────────┬────────────────┘
                 ▼
   Calculated Pulse & Breathing Rate
```

### The Stability Gate & Semantic Preflight
Rather than calculating vitals from unstable frames or inadequate lighting, caren enforces a strict preflight gate:
- **Lighting Analysis:** CameraX auto-exposure evaluates ambient illumination. If light drops below 150 lux, caren displays guidance (`CAMERA_TUNING` / `TOO_DARK`).
- **Face Centering:** Visual elliptical guides ensure optimal facial landmark tracking.
- **2-Second Continuous Stability:** Measurement acquisition is safely disabled until face positioning and lighting achieve `OK` status continuously for two full seconds.

### Signal Streaming & Feedback
During measurement:
- Real-time **Photoplethysmogram (PPG) waveforms** pulse across the viewfinder, giving immediate feedback that the sensor is reading blood volume pulse changes.
- Spoken voice guidance (via `flutter_tts`) coaches the user to hold still and breathe naturally.
- Resulting readings provide **Pulse Rate (BPM)**, **Respiration Rate (BPM)**, and a transparent sensor quality score.

---

## 5. Dual-Mode Backend Architecture

caren is designed to run seamlessly in two distinct modes without code changes:

### Mode A: Standalone In-Memory (Zero Config)
- Default out-of-the-box mode.
- Does not require Firebase or internet access.
- Uses `MockAuthRepository` and in-memory family/wellness repositories pre-seeded with the **Doe family** (`John Doe`, `Eleanor Doe`, `Arthur Doe`, `Sarah Doe`).
- Perfect for evaluating the product, automated testing, and CI pipelines.

### Mode B: Cloud Firestore (Production Connected)
- Activated automatically when `google-services.json` is provided.
- Authenticates users via Firebase Auth (Email/Password).
- Synchronizes family members, check-ins, and privacy rules through Cloud Firestore.
- Enforces strict security rules validated by an automated test suite (`firestore-rules-tests/`).

---

## 6. Privacy & Sovereign Consent Model

1. **Granular Family Sharing:** Family check-ins record energy, sleep, medication adherence, and optional camera spot-checks. Each check-in has a sovereign `isSharedWithFamily` toggle.
2. **Quarantined Me Sanctuary:** Data generated in the `Me` dashboard (guided breathing sessions, mindfulness reflections, personal resting pulse trends) is stored locally and completely inaccessible to other family members.
3. **No Passive Surveillance:** Camera sensors are only active while the user is looking at the camera positioning screen. Zero background recording, zero passive tracking.
