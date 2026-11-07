import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/assist_session.dart';
import '../domain/assist_observation.dart';

abstract class AssistRepository {
  Future<AssistSession?> getActiveSession();
  Future<AssistSession> startNewSession();
  Future<void> addObservation(String sessionId, AssistObservation observation);
  Future<void> logEmergencyServicesContacted(String sessionId);
  Future<AssistSession> completeSession(String sessionId, {String? summary});
}

class LocalAssistRepository implements AssistRepository {
  AssistSession? _activeSession;
  final List<AssistSession> _history = [];

  @override
  Future<AssistSession?> getActiveSession() async {
    return _activeSession;
  }

  @override
  Future<AssistSession> startNewSession() async {
    final now = DateTime.now();
    final newSession = AssistSession(
      id: 'ast_${now.millisecondsSinceEpoch}',
      startTime: now,
      observations: [
        AssistObservation(
          id: 'obs_init',
          timestamp: now,
          category: AssistObservationCategory.actionsTaken,
          description: 'Assist session initiated. Assessed basic scene safety.',
        ),
      ],
      calledEmergencyServices: false,
    );
    _activeSession = newSession;
    return newSession;
  }

  @override
  Future<void> addObservation(String sessionId, AssistObservation observation) async {
    if (_activeSession != null && _activeSession!.id == sessionId) {
      _activeSession = _activeSession!.copyWith(
        observations: [..._activeSession!.observations, observation],
      );
    }
  }

  @override
  Future<void> logEmergencyServicesContacted(String sessionId) async {
    if (_activeSession != null && _activeSession!.id == sessionId) {
      _activeSession = _activeSession!.copyWith(
        calledEmergencyServices: true,
        observations: [
          ..._activeSession!.observations,
          AssistObservation(
            id: 'obs_911_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            category: AssistObservationCategory.actionsTaken,
            description: 'Emergency services button activated / contact initiated.',
          ),
        ],
      );
    }
  }

  @override
  Future<AssistSession> completeSession(String sessionId, {String? summary}) async {
    final completed = _activeSession?.copyWith(
      endTime: DateTime.now(),
      handoffSummary: summary ?? 'Assistance session concluded. Summary ready for medical handoff.',
    ) ?? AssistSession(
      id: sessionId,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      observations: [],
      handoffSummary: summary,
    );

    _history.insert(0, completed);
    _activeSession = null;
    return completed;
  }
}

final assistRepositoryProvider = Provider<AssistRepository>((ref) {
  return LocalAssistRepository();
});

final activeAssistSessionProvider = FutureProvider<AssistSession?>((ref) async {
  final repo = ref.watch(assistRepositoryProvider);
  return repo.getActiveSession();
});

