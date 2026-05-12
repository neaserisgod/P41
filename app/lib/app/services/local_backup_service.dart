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

  Directory get _backupDirectory {
    final home = Platform.environment['HOME'] ?? '.';
    return Directory('$home/.horsepos/backups');
  }

  Future<LocalBackupSummary> createBackup() async {
    final directory = _backupDirectory;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final now = DateTime.now();
    final file = File(
      '${directory.path}${Platform.pathSeparator}horsepos-backup-${now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}Z.sqlite',
    );

    await _localStoreService.exportDatabase(file.path);
    return LocalBackupSummary(path: file.path, createdAt: now);
  }

  Future<LocalBackupSummary?> latestBackup() async {
    final backups = await listBackups();
    if (backups.isEmpty) {
      return null;
    }
    return backups.first;
  }

  Future<List<LocalBackupSummary>> listBackups() async {
    final directory = _backupDirectory;
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
    final backup = await latestBackup();
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
}
