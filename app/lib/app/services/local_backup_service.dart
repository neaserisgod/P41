import 'dart:io';

import 'local_store_service.dart';

class LocalBackupSummary {
  const LocalBackupSummary({
    required this.path,
    required this.createdAt,
  });

  final String path;
  final DateTime createdAt;

  String get fileName => path.split(Platform.pathSeparator).last;
}

class LocalBackupService {
  LocalBackupService({
    LocalStoreService? localStoreService,
  }) : _localStoreService = localStoreService ?? LocalStoreService();

  final LocalStoreService _localStoreService;

  Directory _backupDirectoryFor(String scopeKey) {
    final home = Platform.environment['HOME'] ?? '.';
    return Directory(
      '$home/.p41/backups/${_scopeKeySlug(scopeKey)}',
    );
  }

  Future<LocalBackupSummary> createBackup({
    required String scopeKey,
    required String accountName,
  }) async {
    final directory = _backupDirectoryFor(scopeKey);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final now = DateTime.now();
    final accountSlug = _scopeKeySlug(accountName);
    final file = File(
      '${directory.path}${Platform.pathSeparator}${accountSlug.isEmpty ? 'p41' : accountSlug}-backup-${now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}Z.sqlite',
    );

    await _localStoreService.exportDatabase(file.path);
    return LocalBackupSummary(path: file.path, createdAt: now);
  }

  Future<LocalBackupSummary?> latestBackup({
    required String scopeKey,
  }) async {
    final backups = await listBackups(scopeKey: scopeKey);
    if (backups.isEmpty) {
      return null;
    }
    return backups.first;
  }

  Future<List<LocalBackupSummary>> listBackups({
    required String scopeKey,
  }) async {
    final directory = _backupDirectoryFor(scopeKey);
    if (!await directory.exists()) {
      return const [];
    }

    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.sqlite'))
        .cast<File>()
        .toList();

    final summaries = <LocalBackupSummary>[];
    for (final file in files) {
      summaries.add(
        LocalBackupSummary(
          path: file.path,
          createdAt: await file.lastModified(),
        ),
      );
    }
    summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries;
  }

  Future<bool> restoreLatestBackup() async {
    return false;
  }

  Future<bool> restoreLatestBackupFor({
    required String scopeKey,
  }) async {
    final backup = await latestBackup(scopeKey: scopeKey);
    if (backup == null) {
      return false;
    }
    return restoreBackup(backup.path);
  }

  Future<bool> restoreBackup(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }
    await _localStoreService.restoreDatabase(path);
    return true;
  }

  String _scopeKeySlug(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'default';
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }
}
