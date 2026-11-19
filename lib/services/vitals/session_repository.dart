import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_file_storage.dart';
import 'vitals_models.dart';

abstract class MeasurementSessionRepository {
  Future<void> saveSession(MeasurementSessionRecord session);
  Future<MeasurementSessionRecord?> getSession(String id);
  Future<MeasurementSessionRecord?> getLatestSession();
  Future<List<MeasurementSessionRecord>> getAllSessions();
  Future<void> clearAllSessions();
}

class LocalMeasurementSessionRepository
    implements MeasurementSessionRepository {
  final Map<String, MeasurementSessionRecord> _memoryCache = {};
  final _storage = SessionFileStorage();
  Future<void>? _initialization;

  LocalMeasurementSessionRepository();

  Future<void> _ensureInitialized() => _initialization ??= _loadSessions();

  Future<void> _loadSessions() async {
    try {
      final content = await _storage.read();
      if (content != null && content.trim().isNotEmpty) {
        final dynamic parsed = jsonDecode(content);
        if (parsed is List) {
          for (final item in parsed) {
            if (item is Map<String, dynamic>) {
              final session = MeasurementSessionRecord.fromJson(item);
              _memoryCache[session.id] = session;
            }
          }
        }
      }
    } catch (_) {
      // In-memory fallback if file system IO is unavailable
    }
  }

  Future<void> _persistToDisk() async {
    try {
      final list = _memoryCache.values.map((s) => s.toJson()).toList();
      await _storage.write(jsonEncode(list));
    } catch (_) {
      // Silent in-memory fallback
    }
  }

  @override
  Future<void> saveSession(MeasurementSessionRecord session) async {
    await _ensureInitialized();
    _memoryCache[session.id] = session;
    await _persistToDisk();
  }

  @override
  Future<MeasurementSessionRecord?> getSession(String id) async {
    await _ensureInitialized();
    return _memoryCache[id];
  }

  @override
  Future<MeasurementSessionRecord?> getLatestSession() async {
    await _ensureInitialized();
    if (_memoryCache.isEmpty) return null;
    final sorted = _memoryCache.values.toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return sorted.first;
  }

  @override
  Future<List<MeasurementSessionRecord>> getAllSessions() async {
    await _ensureInitialized();
    final sorted = _memoryCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<void> clearAllSessions() async {
    await _ensureInitialized();
    _memoryCache.clear();
    await _persistToDisk();
  }
}

final sessionRepositoryProvider = Provider<MeasurementSessionRepository>((ref) {
  return LocalMeasurementSessionRepository();
});
