import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/breathing_session.dart';
import '../domain/personal_trend.dart';
import '../../../services/vitals/vitals_models.dart';

abstract class WellnessRepository {
  Future<List<BreathingSession>> getRecentSessions();
  Future<List<WellnessTrendPoint>> getPersonalTrends();
  Future<void> saveBreathingSession(BreathingSession session);
}

class LocalWellnessRepository implements WellnessRepository {
  final List<BreathingSession> _sessions = [
    BreathingSession(
      id: 'sess_1',
      startTime: DateTime.now().subtract(const Duration(hours: 5)),
      durationMinutes: 5,
      cadence: BreathingCadence.gentlePaced,
      preSessionVitals: MeasurementResult(
        pulseRateBpm: 76,
        breathingRateBpm: 17,
        qualityScore: 0.92,
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 6)),
        isSimulated: true, // Clearly simulated
        isSuccessful: true,
      ),
      postSessionVitals: MeasurementResult(
        pulseRateBpm: 69,
        breathingRateBpm: 12,
        qualityScore: 0.94,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isSimulated: true,
        isSuccessful: true,
      ),
      personalReflection: 'Felt much more settled after finishing morning errands.',
      isCompleted: true,
    ),
    BreathingSession(
      id: 'sess_2',
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      durationMinutes: 3,
      cadence: BreathingCadence.boxBreathing,
      preSessionVitals: null,
      postSessionVitals: null,
      personalReflection: 'Mid-afternoon pause.',
      isCompleted: true,
    ),
  ];

  @override
  Future<List<BreathingSession>> getRecentSessions() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_sessions);
  }

  @override
  Future<List<WellnessTrendPoint>> getPersonalTrends() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return [
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 6)),
        restingPulse: 74,
        breathingRate: 16,
        calmnessScore: 4,
      ),
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 5)),
        restingPulse: 72,
        breathingRate: 15,
        calmnessScore: 4,
      ),
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 4)),
        restingPulse: 75,
        breathingRate: 16,
        calmnessScore: 3,
      ),
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 3)),
        restingPulse: 70,
        breathingRate: 14,
        calmnessScore: 5,
      ),
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 2)),
        restingPulse: 71,
        breathingRate: 14,
        calmnessScore: 4,
      ),
      WellnessTrendPoint(
        date: now.subtract(const Duration(days: 1)),
        restingPulse: 69,
        breathingRate: 13,
        calmnessScore: 5,
      ),
      WellnessTrendPoint(
        date: now,
        restingPulse: 70,
        breathingRate: 14,
        calmnessScore: 5,
      ),
    ];
  }

  @override
  Future<void> saveBreathingSession(BreathingSession session) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _sessions.insert(0, session);
  }
}

final wellnessRepositoryProvider = Provider<WellnessRepository>((ref) {
  return LocalWellnessRepository();
});

final recentBreathingSessionsProvider = FutureProvider<List<BreathingSession>>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getRecentSessions();
});

final personalTrendsProvider = FutureProvider<List<WellnessTrendPoint>>((ref) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getPersonalTrends();
});

