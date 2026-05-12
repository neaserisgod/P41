import 'dart:convert';
import 'dart:io';

import 'local_store_service.dart';

class PersistedSession {
  const PersistedSession({
    required this.email,
    this.branchId,
    this.userId,
  });

  final String email;
  final String? branchId;
  final String? userId;

  PersistedSession copyWith({
    String? email,
    String? branchId,
    String? userId,
    bool clearBranchId = false,
    bool clearUserId = false,
  }) {
    return PersistedSession(
      email: email ?? this.email,
      branchId: clearBranchId ? null : (branchId ?? this.branchId),
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }
}

class SessionPersistenceService {
  SessionPersistenceService({
    LocalStoreService? localStoreService,
  }) : _localStoreService = localStoreService ?? LocalStoreService();

  final LocalStoreService _localStoreService;

  File get _legacyFile {
    final home = Platform.environment['HOME'] ?? '.';
    return File('$home/.p41/session_v2.json');
  }

  Future<PersistedSession?> load() async {
    final value = await _localStoreService.loadPersistedSession();
    if (value is Map<String, dynamic>) {
      final session = _fromJson(value);
      if (session != null) {
        return session;
      }
    }
    return _migrateLegacyFileIfPresent();
  }

  Future<void> save(PersistedSession session) {
    return _localStoreService.savePersistedSession({
      'email': session.email,
      'branch_id': session.branchId,
      'user_id': session.userId,
    });
  }

  Future<void> clear() {
    return _localStoreService.clearPersistedSession();
  }

  PersistedSession? _fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      return null;
    }
    return PersistedSession(
      email: email,
      branchId: json['branch_id']?.toString(),
      userId: json['user_id']?.toString(),
    );
  }

  Future<PersistedSession?> _migrateLegacyFileIfPresent() async {
    try {
      if (!await _legacyFile.exists()) {
        return null;
      }
      final raw = await _legacyFile.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final session = _fromJson(json);
      if (session == null) {
        return null;
      }
      await save(session);
      return session;
    } catch (_) {
      return null;
    }
  }
}
