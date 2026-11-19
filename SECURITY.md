# Security & Privacy Policy

The caren team takes privacy and software security seriously. Because caren handles sensitive family check-ins and camera-based wellness observations, we design every feature with sovereign privacy as a core requirement.

---

## Supported Versions

| Version | Supported |
| :--- | :--- |
| `1.0.x` | :white_check_mark: |
| `< 1.0.0` | :x: |

---

## Reporting a Vulnerability

If you discover a security vulnerability or privacy flaw in caren, please do not disclose it via a public GitHub issue.

Instead, please send a private disclosure email to the maintainers at `security@caren.app` (or contact the repository maintainer directly via GitHub Security Advisories).

Please include:
1. A description of the issue and its potential impact.
2. Step-by-step reproduction instructions or proof-of-concept code.
3. Any suggested remediations or mitigations.

We will acknowledge receipt of your report within 48 hours and work with you to patch and release a fix promptly.

---

## Privacy by Design Principles

1. **Zero Passive Surveillance:** caren does not operate cameras, microphones, or location services in the background. Optical sensors are only activated when the user actively opens the camera positioning screen.
2. **On-Device Frame Processing:** When performing a contactless spot-check, CameraX frames are processed directly in memory on the device via the Presage SmartSpectra SDK. Video streams and raw pixel buffers are never saved to disk or transmitted over the network.
3. **Consent Isolation:** All data in the `Me` dashboard (guided breathing logs, mindfulness reflections, resting pulse trends) is stored in private storage and is completely quarantined from family members.
4. **Transparent Cloud Rules:** When connected to Firebase, Cloud Firestore security rules strictly enforce that users can only read check-ins that have been explicitly marked with `isSharedWithFamily: true`.
