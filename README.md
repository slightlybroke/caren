# Caren

Caren is an open-source family wellbeing app. Check in with the people you care about, take a private breathing break, and optionally use an Android camera for a personal wellness spot-check.

[Try Caren in your browser](https://try-caren.vercel.app) · [MIT license](LICENSE)

The browser demo uses local sample accounts and data. Live camera-based pulse and breathing estimates use Presage SmartSpectra on Android.

## Run locally

Install Flutter and run `flutter doctor` to check your toolchain.

```sh
flutter pub get
flutter run -d chrome
```

For live SmartSpectra measurements, connect an Android 9+ device with a front-facing camera. Get an authorized key from the [Presage developer portal](https://physiology.presagetech.com) and add the following to your local `android/local.properties`:

```properties
SMARTSPECTRA_API_KEY=your_presage_key
```

Run `flutter devices`, then `flutter run -d <device-id>`. Open the optional wellness camera check, grant permission, and follow the positioning prompts. Keep simulated vitals off for live readings.

Without Firebase configuration, Caren uses local repositories. To connect your own Android Firebase project, register package `com.caren.app.caren`, put its `google-services.json` in `android/app/`, enable Email/Password sign-in, and deploy the checked-in Firestore rules and indexes to your project.

## Contributing

Open an issue for a bug or proposal. Pull requests should explain the user-facing change and how to verify it.

- `lib/features/` contains the Flutter product flows.
- `lib/services/vitals/` contains the measurement-provider and session-storage interfaces.
- `android/app/src/main/kotlin/` contains the SmartSpectra bridge.
- `test/` and `firestore-rules-tests/` contain application and authorization tests.

```sh
flutter analyze
flutter test
npm ci --prefix firestore-rules-tests
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```

## Camera and privacy

Caren asks for camera access when you open the measurement flow. SmartSpectra processes frames to estimate pulse and breathing. Android measurement session records are kept in app-local storage. SmartSpectra telemetry is off by default. For SDK processing and telemetry details, see the [Presage privacy documentation](https://smartspectra.presagetech.com/docs/telemetry-and-privacy). When Firebase is configured, account and family features use Firestore, and family sharing is opt-in.

Caren’s camera estimates are for personal wellness awareness. Seek professional medical help for medical decisions.

## License

Caren is released under the [MIT License](LICENSE). SmartSpectra is provided separately by Presage.
