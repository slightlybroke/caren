import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDialerResult {
  final bool isSuccess;
  final String? errorMessage;
  final String emergencyNumber;

  const EmergencyDialerResult({
    required this.isSuccess,
    this.errorMessage,
    required this.emergencyNumber,
  });

  factory EmergencyDialerResult.success(String number) => EmergencyDialerResult(
        isSuccess: true,
        emergencyNumber: number,
      );

  factory EmergencyDialerResult.failure(String number, String message) =>
      EmergencyDialerResult(
        isSuccess: false,
        errorMessage: message,
        emergencyNumber: number,
      );
}

abstract class EmergencyDialerService {
  Future<EmergencyDialerResult> launchDialer(String emergencyNumber);
}

class UrlLauncherEmergencyDialerService implements EmergencyDialerService {
  @override
  Future<EmergencyDialerResult> launchDialer(String emergencyNumber) async {
    final cleaned = emergencyNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return EmergencyDialerResult.failure(
        emergencyNumber,
        'Invalid emergency number provided.',
      );
    }

    final uri = Uri(scheme: 'tel', path: cleaned);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        // Fallback direct launch attempt
        final directLaunched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (directLaunched) {
          return EmergencyDialerResult.success(cleaned);
        }
        return EmergencyDialerResult.failure(
          cleaned,
          'No phone dialer application was found on this device. Please dial $cleaned manually.',
        );
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return EmergencyDialerResult.success(cleaned);
      } else {
        return EmergencyDialerResult.failure(
          cleaned,
          'The device system dialer could not be opened. Please dial $cleaned manually.',
        );
      }
    } catch (e) {
      return EmergencyDialerResult.failure(
        cleaned,
        'Failed to open dialer: ${e.toString()}',
      );
    }
  }
}

class MockEmergencyDialerService implements EmergencyDialerService {
  bool shouldSucceed = true;
  String? lastDialedNumber;
  final List<String> launchedNumbers = [];

  @override
  Future<EmergencyDialerResult> launchDialer(String emergencyNumber) async {
    lastDialedNumber = emergencyNumber;
    launchedNumbers.add(emergencyNumber);
    if (shouldSucceed) {
      return EmergencyDialerResult.success(emergencyNumber);
    } else {
      return EmergencyDialerResult.failure(
        emergencyNumber,
        'Simulated dialer launch failure.',
      );
    }
  }
}

final emergencyDialerServiceProvider = Provider<EmergencyDialerService>((ref) {
  return UrlLauncherEmergencyDialerService();
});

