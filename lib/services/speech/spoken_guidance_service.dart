import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Contract for spoken voice guidance during wellness, breathing, and relaxation sessions.
abstract class SpokenGuidanceService {
  bool get isMuted;
  bool get isSpeaking;
  void setMuted(bool muted);

  /// Speaks the given [text]. If [clearQueue] is true, any pending or in-flight speech
  /// is immediately cancelled before speaking. Otherwise, instructions are queued sequentially.
  Future<void> speak(String text, {bool clearQueue = false});

  /// Immediately stops speech and purges all queued instructions.
  Future<void> stop();

  /// Pauses current speech playback.
  Future<void> pause();

  /// Resumes speech playback.
  Future<void> resume();

  /// Releases resources.
  void dispose();
}

class _SpeechTask {
  final String text;
  final Completer<void> completer;

  _SpeechTask(this.text, this.completer);
}

/// Production implementation using [FlutterTts] with a serialized speech queue
/// to prevent overlapping or clipped instructions.
class FlutterTtsSpokenGuidanceService implements SpokenGuidanceService {
  final FlutterTts _tts;
  bool _isMuted = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  final List<_SpeechTask> _queue = [];
  bool _isProcessingQueue = false;
  int _sessionGeneration = 0;

  FlutterTtsSpokenGuidanceService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Gentle, calm wellness cadence
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Enable speech completion waiting on supported platforms
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((dynamic msg) {
        _isSpeaking = false;
      });

      _isInitialized = true;
    } catch (_) {
      // Platform TTS might not be fully available on headless or emulator environments
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stop();
    }
  }

  @override
  Future<void> speak(String text, {bool clearQueue = false}) async {
    if (_isMuted || text.trim().isEmpty) return;

    await _ensureInitialized();

    if (clearQueue) {
      await stop();
    }

    final task = _SpeechTask(text.trim(), Completer<void>());
    _queue.add(task);

    _processQueue();

    return task.completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _queue.isEmpty || _isMuted) return;

    _isProcessingQueue = true;
    final currentGen = _sessionGeneration;

    while (_queue.isNotEmpty && !_isMuted && _sessionGeneration == currentGen) {
      final currentTask = _queue.removeAt(0);

      try {
        _isSpeaking = true;
        await _tts.speak(currentTask.text);
      } catch (_) {
        // Continue queue execution without permanently blocking on individual error
      } finally {
        _isSpeaking = false;
        if (!currentTask.completer.isCompleted) {
          currentTask.completer.complete();
        }
      }
    }

    _isProcessingQueue = false;
  }

  @override
  Future<void> stop() async {
    _sessionGeneration++;
    // Purge pending queue and resolve all completers so no callers hang
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      if (!task.completer.isCompleted) {
        task.completer.complete();
      }
    }
    _isProcessingQueue = false;
    _isSpeaking = false;

    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (_) {
      await stop();
    }
  }

  @override
  Future<void> resume() async {
    if (_isMuted) return;
    _processQueue();
  }

  @override
  void dispose() {
    stop();
  }
}

/// Mock implementation for unit and widget tests with serialized queue simulation.
class MockSpokenGuidanceService implements SpokenGuidanceService {
  bool _isMuted = false;
  bool isStopped = false;
  bool _isSpeaking = false;
  final List<String> spokenUtterances = [];
  final List<String> queuedUtterances = [];
  final List<Completer<void>> _pendingCompleters = [];

  @override
  bool get isMuted => _isMuted;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stop();
    }
  }

  @override
  Future<void> speak(String text, {bool clearQueue = false}) async {
    if (_isMuted || text.trim().isEmpty) return;

    if (clearQueue) {
      await stop();
      isStopped = false;
    }

    isStopped = false;
    final completer = Completer<void>();
    _pendingCompleters.add(completer);
    queuedUtterances.add(text.trim());
    _isSpeaking = true;

    spokenUtterances.add(text.trim());
    _isSpeaking = false;
    if (!completer.isCompleted) {
      completer.complete();
    }
    return completer.future;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
    _isSpeaking = false;
    queuedUtterances.clear();
    for (final c in _pendingCompleters) {
      if (!c.isCompleted) {
        c.complete();
      }
    }
    _pendingCompleters.clear();
  }

  @override
  Future<void> pause() async {
    _isSpeaking = false;
  }

  @override
  Future<void> resume() async {}

  @override
  void dispose() {
    stop();
  }
}

final spokenGuidanceServiceProvider = Provider<SpokenGuidanceService>((ref) {
  final service = FlutterTtsSpokenGuidanceService();
  ref.onDispose(() => service.dispose());
  return service;
});
