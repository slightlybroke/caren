# Contributing to caren

Thank you for your interest in contributing to **caren**! We welcome bug fixes, documentation improvements, UI enhancements, and feature contributions from the community.

---

## Code of Conduct

By participating in this project, you agree to uphold our [Code of Conduct](CODE_OF_CONDUCT.md). Please treat all contributors and community members with empathy, kindness, and respect.

---

## Getting Started

### 1. Fork & Clone
```sh
git clone https://github.com/<your-username>/caren.git
cd caren
```

### 2. Install Dependencies
```sh
flutter pub get
```

### 3. Verify Environment
Run `flutter doctor` to ensure your Flutter environment and toolchain are healthy.
- Flutter `>= 3.13.0` (tested on Flutter 3.47.5 stable)
- Dart `>= 3.13.0`

### 4. Run the App Locally
```sh
# Run Web presentation shell:
flutter run -d chrome

# Run on an Android device:
flutter run -d <device-id>
```

---

## Architectural Guidelines

When submitting code, please maintain our architectural consistency:

1. **Feature-First Organization:** Place business flows in `lib/features/<feature-name>/` with `presentation/`, `domain/`, and `data/` sub-directories where appropriate.
2. **Serene Hearth Theme Tokens:** Avoid hardcoded colors or text styles. Always use `AppColors`, `AppTypography`, and `AppSpacing` from `lib/core/constants/`.
3. **Sovereign Consent & Privacy:** Always honor the user's explicit consent. Data in the `Me` sanctuary must never be shared across family circles. Camera sensors must only be invoked when the user is explicitly on the camera positioning screen.
4. **State Management:** Use **Riverpod**. Avoid global mutable singletons.
5. **Decoupled Platform APIs:** Use conditional imports or platform checks (`kIsWeb`, `defaultTargetPlatform`) so that web and native Android builds compile cleanly without platform-specific crashes.

---

## Testing & Quality Checklist

Before submitting a Pull Request, ensure that all checks pass:

```sh
# 1. Static Analysis (must have 0 errors and 0 warnings)
flutter analyze

# 2. Automated Test Suite (all 116 tests must pass)
flutter test

# 3. Web Release Build Verification
flutter build web --release

# 4. Optional: Firestore Rules Verification (if modifying firestore.rules)
npm ci --prefix firestore-rules-tests
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```

---

## Submitting a Pull Request

1. Create a feature branch from `main`:
   ```sh
   git checkout -b feature/my-enhancement
   ```
2. Commit your changes with clear, descriptive commit messages:
   ```sh
   git commit -m "feat(wellness): add sensory grounding pulse indicator"
   ```
3. Push to your fork:
   ```sh
   git push origin feature/my-enhancement
   ```
4. Open a Pull Request against `main`. Describe:
   - What the change accomplishes.
   - Why it is needed.
   - How you verified and tested it.
