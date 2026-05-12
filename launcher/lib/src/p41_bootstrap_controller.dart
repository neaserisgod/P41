import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'p41_update_manifest.dart';

const _updatesUrl = String.fromEnvironment(
  'P41_UPDATES_URL',
  defaultValue: 'https://api.horsepos.com/static/updates/p41/version.json',
);
const _fallbackCatalogUrl = String.fromEnvironment(
  'P41_CATALOG_URL',
  defaultValue:
      'https://api.horsepos.com/static/bootstrap/p41/global_lookup.sqlite',
);
const _fallbackImagesUrl = String.fromEnvironment(
  'P41_IMAGES_URL',
  defaultValue:
      'https://api.horsepos.com/static/bootstrap/p41/imagenes_productos.zip',
);
const _fallbackCatalogVersion = String.fromEnvironment(
  'P41_CATALOG_VERSION',
  defaultValue: 'bootstrap',
);
const _fallbackImagesVersion = String.fromEnvironment(
  'P41_IMAGES_VERSION',
  defaultValue: 'bootstrap',
);
const _windowsExecutableName = 'p41.exe';
const _macosBundleName = 'P41.app';
const _catalogBootstrapName = 'global_lookup.sqlite';
const _imagesBootstrapFolder = 'imagenes_productos';
const _resourcesVersionFile = 'resource_versions.json';

class P41BootstrapController extends ChangeNotifier {
  P41BootstrapController({required this.updateMode});

  final bool updateMode;

  P41UpdateManifest? manifest;
  String? installedAppVersion;
  String? errorMessage;
  String statusLine = 'Preparando entorno...';
  P41BootstrapStage stage = P41BootstrapStage.idle;
  double? progress;
  bool isBusy = false;

  P41PlatformMode get platformMode {
    if (Platform.isWindows) {
      return P41PlatformMode.windows;
    }
    if (Platform.isMacOS) {
      return P41PlatformMode.macos;
    }
    return P41PlatformMode.unsupported;
  }

  String get headline => switch (stage) {
    P41BootstrapStage.failed => 'No pude abrir P41',
    P41BootstrapStage.ready => 'P41 lista',
    _ => switch (_plannedAction) {
      P41LauncherAction.install => 'Instalando P41',
      P41LauncherAction.update => 'Actualizando P41',
      P41LauncherAction.none => 'Iniciando P41',
    },
  };

  String get footerLine => switch (stage) {
    P41BootstrapStage.failed => 'Podés reintentar o cerrar.',
    P41BootstrapStage.ready => 'Se abre sola apenas termina.',
    _ => 'Verifica la app, baja recursos globales y abre el sistema.',
  };

  bool get hasInstalledApp {
    final version = installedAppVersion;
    if (version != null && version.isNotEmpty) {
      return true;
    }
    final path = _installedLaunchTargetSync();
    if (path == null) {
      return false;
    }
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }

  bool get hasUpdateAvailable {
    final remote = manifest?.appVersion;
    final local = installedAppVersion;
    if (remote == null || remote.isEmpty) {
      return false;
    }
    if (local == null || local.isEmpty) {
      return false;
    }
    return _compareVersions(remote, local) > 0;
  }

  P41LauncherAction get _plannedAction {
    if (!hasInstalledApp) {
      return P41LauncherAction.install;
    }
    if (hasUpdateAvailable || updateMode) {
      return P41LauncherAction.update;
    }
    return P41LauncherAction.none;
  }

  Future<void> bootstrap() async {
    if (isBusy) {
      return;
    }
    if (platformMode == P41PlatformMode.unsupported) {
      stage = P41BootstrapStage.failed;
      statusLine = 'Este bootstrap hoy sólo funciona en Windows y macOS.';
      errorMessage = 'Plataforma no soportada.';
      notifyListeners();
      return;
    }

    isBusy = true;
    errorMessage = null;
    progress = null;
    stage = P41BootstrapStage.inspecting;
    statusLine = 'Detectando instalación local...';
    notifyListeners();

    try {
      installedAppVersion = await _readInstalledAppVersion();

      stage = P41BootstrapStage.checkingManifest;
      statusLine = 'Consultando versión publicada...';
      notifyListeners();
      try {
        manifest = await _fetchManifest();
      } catch (_) {
        manifest = _fallbackManifest();
      }

      switch (_plannedAction) {
        case P41LauncherAction.none:
          await _ensureBootstrapResources();
          stage = P41BootstrapStage.ready;
          statusLine = 'No hay actualización. Abriendo P41...';
          progress = 1;
          notifyListeners();
          await _launchInstalledApp();
          await _closeSoon();
        case P41LauncherAction.install:
          await _installOrUpdate(installingFresh: true);
        case P41LauncherAction.update:
          await _installOrUpdate(installingFresh: false);
      }
    } catch (error) {
      stage = P41BootstrapStage.failed;
      statusLine = 'No se pudo completar el arranque.';
      errorMessage = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<P41UpdateManifest> _fetchManifest() async {
    final response = await http
        .get(
          Uri.parse('$_updatesUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('version.json respondió HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('version.json no es válido.');
    }
    return P41UpdateManifest.fromVersionJson(decoded, platformMode);
  }

  P41UpdateManifest _fallbackManifest() {
    return const P41UpdateManifest(
      appVersion: null,
      appUrl: null,
      launcherVersion: null,
      launcherUrl: null,
      launcherInstallerUrl: null,
      resources: P41ResourceBundle(
        catalogVersion: _fallbackCatalogVersion,
        catalogUrl: _fallbackCatalogUrl,
        imagesVersion: _fallbackImagesVersion,
        imagesUrl: _fallbackImagesUrl,
      ),
    );
  }

  Future<void> _installOrUpdate({required bool installingFresh}) async {
    final appUrl = manifest?.appUrl;
    if (appUrl == null || appUrl.isEmpty) {
      throw Exception('No hay paquete publicado para esta plataforma.');
    }

    stage = P41BootstrapStage.syncingApp;
    statusLine = installingFresh
        ? 'Descargando P41 base...'
        : 'Descargando actualización de P41...';
    progress = null;
    notifyListeners();

    final uri = Uri.parse(appUrl);
    final response = await http.get(uri).timeout(const Duration(minutes: 5));
    if (response.statusCode != 200) {
      throw Exception('La descarga falló con HTTP ${response.statusCode}');
    }
    if (p.extension(uri.path).toLowerCase() != '.zip') {
      throw Exception('El bootstrap espera un ZIP para esta plataforma.');
    }

    progress = 0.5;
    statusLine = 'Instalando binarios...';
    notifyListeners();
    await _applyZipPayload(response.bodyBytes);

    stage = P41BootstrapStage.syncingResources;
    progress = 0.72;
    statusLine = 'Sincronizando catálogo e imágenes...';
    notifyListeners();
    await _ensureBootstrapResources();

    installedAppVersion = await _readInstalledAppVersion();
    stage = P41BootstrapStage.ready;
    progress = 1;
    statusLine = installingFresh
        ? 'P41 instalada. Abriendo...'
        : 'Actualización lista. Abriendo P41...';
    notifyListeners();
    await _launchInstalledApp();
    await _closeSoon();
  }

  Future<void> _applyZipPayload(List<int> bytes) async {
    switch (platformMode) {
      case P41PlatformMode.windows:
        await _applyWindowsZipPayload(bytes);
      case P41PlatformMode.macos:
        await _applyMacosZipPayload(bytes);
      case P41PlatformMode.unsupported:
        throw Exception('Plataforma no soportada.');
    }
  }

  Future<void> _ensureBootstrapResources() async {
    final resources = manifest?.resources;
    if (resources == null) {
      return;
    }

    await (await _resourcesRoot()).create(recursive: true);
    final installedVersions = await _readInstalledResourceVersions();

    if (resources.catalogUrl != null &&
        resources.catalogUrl!.isNotEmpty &&
        (installedVersions['catalog'] != resources.catalogVersion ||
            !await (await _catalogBootstrapFile()).exists())) {
      statusLine = 'Descargando catálogo global...';
      progress = 0.84;
      notifyListeners();
      await _downloadFile(resources.catalogUrl!, await _catalogBootstrapFile());
      installedVersions['catalog'] = resources.catalogVersion ?? '';
    }

    if (resources.imagesUrl != null &&
        resources.imagesUrl!.isNotEmpty &&
        (installedVersions['images'] != resources.imagesVersion ||
            !await (await _imagesBootstrapDirectory()).exists())) {
      statusLine = 'Descargando imágenes globales...';
      progress = 0.92;
      notifyListeners();
      final zipFile = File(
        p.join((await _resourcesRoot()).path, '$_imagesBootstrapFolder.zip'),
      );
      await _downloadFile(resources.imagesUrl!, zipFile);
      await _extractImagesBootstrap(zipFile);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      installedVersions['images'] = resources.imagesVersion ?? '';
    }

    await _writeInstalledResourceVersions(installedVersions);
  }

  Future<void> _downloadFile(String url, File target) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 8));
    if (response.statusCode != 200) {
      throw Exception(
        'La descarga de recursos falló con HTTP ${response.statusCode}',
      );
    }
    await target.parent.create(recursive: true);
    await target.writeAsBytes(response.bodyBytes, flush: true);
  }

  Future<void> _extractImagesBootstrap(File zipFile) async {
    final targetDir = await _imagesBootstrapDirectory();
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);
    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    extractArchiveToDisk(archive, targetDir.path);
    await _normalizeImagesBootstrapLayout(targetDir);
  }

  Future<void> _normalizeImagesBootstrapLayout(Directory targetDir) async {
    final nestedDir = Directory(
      p.join(targetDir.path, _imagesBootstrapFolder),
    );
    if (!await nestedDir.exists()) {
      return;
    }

    final rootHasImages = await targetDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .any((file) => file.path.toLowerCase().endsWith('.jpg'));
    if (rootHasImages) {
      return;
    }

    await for (final entity in nestedDir.list(followLinks: false)) {
      final destinationPath = p.join(targetDir.path, p.basename(entity.path));
      if (entity is File) {
        await entity.rename(destinationPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(destinationPath));
        await entity.delete(recursive: true);
      }
    }
    await nestedDir.delete(recursive: true);
  }

  Future<Map<String, String>> _readInstalledResourceVersions() async {
    final file = await _resourceVersionsFile();
    if (!await file.exists()) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return <String, String>{};
      }
      return decoded.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _writeInstalledResourceVersions(
    Map<String, String> versions,
  ) async {
    final file = await _resourceVersionsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(versions), flush: true);
  }

  Future<void> _applyWindowsZipPayload(List<int> bytes) async {
    final targetDir = await _ensureWindowsAppDir();
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);
    final archive = ZipDecoder().decodeBytes(bytes);
    extractArchiveToDisk(archive, targetDir.path);
  }

  Future<void> _applyMacosZipPayload(List<int> bytes) async {
    final workDir = await Directory(
      p.join(
        Directory.systemTemp.path,
        'p41_bootstrap_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ).create(recursive: true);
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, workDir.path);
      final appBundle = await _findAppBundle(workDir);
      if (appBundle == null) {
        throw Exception('No encontré el bundle de P41 dentro del ZIP.');
      }
      final target = Directory(
        p.join(await _macosApplicationsPath(), _macosBundleName),
      );
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await _copyDirectory(appBundle, target);
    } finally {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  Future<Directory?> _findAppBundle(Directory root) async {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        return entity;
      }
    }
    return null;
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final destinationPath = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destinationPath));
      } else if (entity is File) {
        await entity.copy(destinationPath);
      }
    }
  }

  Future<String?> _readInstalledAppVersion() async {
    try {
      switch (platformMode) {
        case P41PlatformMode.windows:
          return await _readWindowsInstalledVersion();
        case P41PlatformMode.macos:
          return await _readMacosInstalledVersion();
        case P41PlatformMode.unsupported:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readWindowsInstalledVersion() async {
    final appDir = await _ensureWindowsAppDir();
    final versionFile = File(p.join(appDir.path, 'version.json'));
    if (!await versionFile.exists()) {
      return null;
    }
    final decoded = jsonDecode(await versionFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final version = decoded['version']?.toString().trim();
    return version == null || version.isEmpty ? null : version;
  }

  Future<String?> _readMacosInstalledVersion() async {
    final plistFile = File(
      p.join(
        await _macosApplicationsPath(),
        _macosBundleName,
        'Contents',
        'Info.plist',
      ),
    );
    if (!await plistFile.exists()) {
      return null;
    }
    final raw = await plistFile.readAsString();
    final match = RegExp(
      r'<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>',
      multiLine: true,
    ).firstMatch(raw);
    return match?.group(1)?.trim();
  }

  Future<void> _launchInstalledApp() async {
    switch (platformMode) {
      case P41PlatformMode.windows:
        final executablePath = await _installedExecutablePath();
        if (executablePath == null) {
          throw Exception('La app quedó instalada, pero no encontré el ejecutable.');
        }
        await Process.start(
          executablePath,
          const [],
          mode: ProcessStartMode.detached,
        );
      case P41PlatformMode.macos:
        final appPath = p.join(await _macosApplicationsPath(), _macosBundleName);
        if (!await Directory(appPath).exists()) {
          throw Exception('La app quedó instalada, pero no encontré el bundle de P41.');
        }
        await Process.start(
          '/usr/bin/open',
          [appPath],
          mode: ProcessStartMode.detached,
        );
      case P41PlatformMode.unsupported:
        throw Exception('Plataforma no soportada.');
    }
  }

  Future<String?> _installedExecutablePath() async {
    final appDir = await _ensureWindowsAppDir();
    final direct = File(p.join(appDir.path, _windowsExecutableName));
    if (await direct.exists()) {
      return direct.path;
    }
    final fallback = File(p.join(appDir.path, 'horsepos.exe'));
    if (await fallback.exists()) {
      return fallback.path;
    }
    final legacy = File(p.join(appDir.path, 'horsepos_pro.exe'));
    if (await legacy.exists()) {
      return legacy.path;
    }
    return null;
  }

  String? _installedLaunchTargetSync() {
    switch (platformMode) {
      case P41PlatformMode.windows:
        final localAppData = Platform.environment['LOCALAPPDATA'];
        if (localAppData == null || localAppData.isEmpty) {
          return null;
        }
        return p.join(localAppData, 'P41', 'App', _windowsExecutableName);
      case P41PlatformMode.macos:
        final home = Platform.environment['HOME'];
        if (home == null || home.isEmpty) {
          return null;
        }
        return p.join(home, 'Applications', _macosBundleName);
      case P41PlatformMode.unsupported:
        return null;
    }
  }

  Future<Directory> _ensureWindowsAppDir() async {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      throw Exception('LOCALAPPDATA no está disponible.');
    }
    return Directory(p.join(localAppData, 'P41', 'App'));
  }

  Future<String> _macosApplicationsPath() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw Exception('HOME no está disponible.');
    }
    final path = p.join(home, 'Applications');
    await Directory(path).create(recursive: true);
    return path;
  }

  int _compareVersions(String left, String right) {
    final leftParts = _parseVersion(left);
    final rightParts = _parseVersion(right);
    for (var index = 0; index < 4; index++) {
      if (leftParts[index] > rightParts[index]) {
        return 1;
      }
      if (leftParts[index] < rightParts[index]) {
        return -1;
      }
    }
    return 0;
  }

  List<int> _parseVersion(String value) {
    final parts = value.trim().split('+');
    final semver = parts.first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    while (semver.length < 3) {
      semver.add(0);
    }
    semver.add(parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    return semver.take(4).toList();
  }

  Future<void> _closeSoon() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    closeLauncher();
  }

  void closeLauncher() {
    exit(0);
  }

  Future<Directory> _resourcesRoot() async {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) {
      throw Exception('No pude resolver la carpeta local de P41.');
    }
    return Directory(p.join(home, '.p41', 'resources'));
  }

  Future<File> _catalogBootstrapFile() async {
    return File(p.join((await _resourcesRoot()).path, _catalogBootstrapName));
  }

  Future<Directory> _imagesBootstrapDirectory() async {
    return Directory(
      p.join((await _resourcesRoot()).path, _imagesBootstrapFolder),
    );
  }

  Future<File> _resourceVersionsFile() async {
    return File(p.join((await _resourcesRoot()).path, _resourcesVersionFile));
  }
}
