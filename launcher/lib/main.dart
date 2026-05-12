import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.horsepos.com',
);
const _updatesUrl = '$_apiBaseUrl/static/updates/version.json';
const _windowsExecutableName = 'horsepos.exe';
const _macosBundleName = 'HorsePos.app';
const _catalogBootstrapName = 'global_lookup.sqlite';
const _imagesBootstrapFolder = 'imagenes_productos';
const _resourcesVersionFile = 'resource_versions.json';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HorseLauncherApp(updateMode: args.contains('--update')));
}

class HorseLauncherApp extends StatelessWidget {
  const HorseLauncherApp({super.key, required this.updateMode});

  final bool updateMode;

  @override
  Widget build(BuildContext context) {
    const shell = Color(0xFFF6F4EF);
    const surface = Colors.white;
    const ink = Color(0xFF171717);
    const muted = Color(0xFF6B6B73);
    const gold = Color(0xFFC9972F);
    const border = Color(0xFFE6DEC9);
    const danger = Color(0xFFB42318);

    return MaterialApp(
      title: 'P41 Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: shell,
        colorScheme: const ColorScheme.light(
          primary: gold,
          secondary: gold,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: ink,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Questrial',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Questrial',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'GlacialIndifference',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'GlacialIndifference',
            fontSize: 13,
            height: 1.3,
            color: muted,
          ),
        ),
        dividerColor: border,
      ),
      home: LauncherScreen(
        controller: LauncherController(updateMode: updateMode)..bootstrap(),
      ),
    );
  }
}

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key, required this.controller});

  final LauncherController controller;

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  LauncherController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 28,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LauncherLogo(color: palette.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.headline,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      if (controller.isBusy)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: palette.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    controller.statusLine,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: controller.stage == LauncherStage.failed
                          ? palette.error
                          : const Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _VersionChip(
                        label: 'Instalada',
                        value: controller.installedAppVersion ?? 'Sin detectar',
                      ),
                      _VersionChip(
                        label: 'Disponible',
                        value:
                            controller.manifest?.appVersion ?? 'Sin publicar',
                      ),
                    ],
                  ),
                  if (controller.errorMessage case final error?) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: controller.progress,
                      backgroundColor: const Color(0xFFF1E7D2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (controller.stage == LauncherStage.failed)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: controller.isBusy
                                ? null
                                : controller.bootstrap,
                            child: const Text('Reintentar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: controller.closeLauncher,
                          child: const Text('Cerrar'),
                        ),
                      ],
                    )
                  else
                    Text(
                      controller.footerLine,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LauncherLogo extends StatelessWidget {
  const _LauncherLogo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'P',
              style: TextStyle(
                fontFamily: 'GlacialIndifference',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF171717),
              ),
            ),
            TextSpan(
              text: '41',
              style: TextStyle(
                fontFamily: 'GlacialIndifference',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

enum LauncherStage { idle, checking, applying, completed, failed }

enum PlatformMode { windows, macos, unsupported }

class LauncherController extends ChangeNotifier {
  LauncherController({required this.updateMode});

  final bool updateMode;

  PlatformMode get platformMode {
    if (Platform.isWindows) {
      return PlatformMode.windows;
    }
    if (Platform.isMacOS) {
      return PlatformMode.macos;
    }
    return PlatformMode.unsupported;
  }

  UpdateManifest? manifest;
  String? installedAppVersion;
  String? errorMessage;
  String statusLine = 'Preparando launcher...';
  LauncherStage stage = LauncherStage.idle;
  bool isBusy = false;
  double? progress;

  String get headline => switch (stage) {
    LauncherStage.failed => 'No pude abrir P41',
    LauncherStage.completed => 'P41 lista',
    _ => switch (_plannedAction) {
      LauncherAction.install => 'Instalando P41',
      LauncherAction.update => 'Actualizando P41',
      LauncherAction.none => 'Verificando P41',
    },
  };

  String get footerLine => switch (stage) {
    LauncherStage.completed => 'Se abre sola apenas termina.',
    LauncherStage.failed => 'Reintentá o cerrá el launcher.',
    _ => 'Busca updates, las aplica y abre la app sin pasos extra.',
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
      return true;
    }
    return _compareVersions(remote, local) > 0;
  }

  LauncherAction get _plannedAction {
    if (!hasInstalledApp) {
      return LauncherAction.install;
    }
    if (hasUpdateAvailable) {
      return LauncherAction.update;
    }
    return LauncherAction.none;
  }

  Future<void> bootstrap() async {
    if (isBusy) {
      return;
    }
    if (platformMode == PlatformMode.unsupported) {
      stage = LauncherStage.failed;
      statusLine = 'Este launcher hoy sólo funciona en Windows y macOS.';
      errorMessage = 'Plataforma no soportada.';
      notifyListeners();
      return;
    }

    isBusy = true;
    progress = null;
    stage = LauncherStage.checking;
    errorMessage = null;
    statusLine = 'Detectando instalación local...';
    notifyListeners();

    try {
      installedAppVersion = await _readInstalledAppVersion();
      statusLine = 'Buscando actualización publicada...';
      notifyListeners();
      manifest = await _fetchManifest();

      switch (_plannedAction) {
        case LauncherAction.none:
          await _ensureBootstrapResources();
          stage = LauncherStage.completed;
          statusLine = 'No hay actualización. Abriendo P41...';
          progress = 1;
          notifyListeners();
          await _launchInstalledApp();
          await _closeSoon();
        case LauncherAction.install:
          await _installOrUpdate(installingFresh: true);
        case LauncherAction.update:
          await _installOrUpdate(installingFresh: false);
      }
    } catch (error) {
      stage = LauncherStage.failed;
      statusLine = 'No se pudo completar la verificación.';
      errorMessage = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<UpdateManifest> _fetchManifest() async {
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
    final resolved = UpdateManifest.fromVersionJson(decoded, platformMode);
    if ((resolved.appUrl ?? '').isEmpty ||
        (resolved.appVersion ?? '').isEmpty) {
      throw Exception('Faltan datos de versión para esta plataforma.');
    }
    return resolved;
  }

  Future<void> _installOrUpdate({required bool installingFresh}) async {
    final appUrl = manifest?.appUrl;
    if (appUrl == null || appUrl.isEmpty) {
      throw Exception('No hay URL publicada para esta plataforma.');
    }

    stage = LauncherStage.applying;
    statusLine = installingFresh
        ? 'Descargando P41...'
        : 'Descargando actualización...';
    progress = null;
    notifyListeners();

    final uri = Uri.parse(appUrl);
    final response = await http.get(uri).timeout(const Duration(minutes: 5));
    if (response.statusCode != 200) {
      throw Exception('La descarga falló con HTTP ${response.statusCode}');
    }

    final extension = p.extension(uri.path).toLowerCase();
    if (extension != '.zip') {
      throw Exception(
        'El launcher espera un ZIP para instalar esta plataforma.',
      );
    }

    progress = 0.55;
    statusLine = 'Aplicando paquete...';
    notifyListeners();
    await _applyZipPayload(response.bodyBytes);
    progress = 0.78;
    statusLine = 'Preparando catálogo e imágenes...';
    notifyListeners();
    await _ensureBootstrapResources();
    installedAppVersion = await _readInstalledAppVersion();

    stage = LauncherStage.completed;
    statusLine = installingFresh
        ? 'P41 instalada. Abriendo...'
        : 'Update lista. Abriendo P41...';
    progress = 1;
    notifyListeners();
    await _launchInstalledApp();
    await _closeSoon();
  }

  Future<void> _applyZipPayload(List<int> bytes) async {
    switch (platformMode) {
      case PlatformMode.windows:
        await _applyWindowsZipPayload(bytes);
      case PlatformMode.macos:
        await _applyMacosZipPayload(bytes);
      case PlatformMode.unsupported:
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
      progress = 0.9;
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
        'p41_launcher_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ).create(recursive: true);
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, workDir.path);
      final appBundle = await _findAppBundle(workDir);
      if (appBundle == null) {
        throw Exception('No encontré el bundle de P41 dentro del ZIP.');
      }
      final target = File(
        p.join(await _macosApplicationsPath(), _macosBundleName),
      );
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await _copyDirectory(appBundle, Directory(target.path));
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
      final name = p.basename(entity.path);
      final destinationPath = p.join(target.path, name);
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
        case PlatformMode.windows:
          return await _readWindowsInstalledVersion();
        case PlatformMode.macos:
          return await _readMacosInstalledVersion();
        case PlatformMode.unsupported:
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
      case PlatformMode.windows:
        final executablePath = await _installedExecutablePath();
        if (executablePath == null) {
          throw Exception(
            'La app quedó instalada, pero no encontré el ejecutable.',
          );
        }
        await Process.start(
          executablePath,
          const [],
          mode: ProcessStartMode.detached,
        );
      case PlatformMode.macos:
        final appPath = p.join(
          await _macosApplicationsPath(),
          _macosBundleName,
        );
        if (!await Directory(appPath).exists()) {
          throw Exception(
            'La app quedó instalada, pero no encontré el bundle de P41.',
          );
        }
        await Process.start('/usr/bin/open', [
          appPath,
        ], mode: ProcessStartMode.detached);
      case PlatformMode.unsupported:
        throw Exception('Plataforma no soportada.');
    }
  }

  Future<String?> _installedExecutablePath() async {
    final appDir = await _ensureWindowsAppDir();
    final appPath = p.join(appDir.path, _windowsExecutableName);
    return await File(appPath).exists() ? appPath : null;
  }

  String? _installedLaunchTargetSync() {
    switch (platformMode) {
      case PlatformMode.windows:
        final localAppData = Platform.environment['LOCALAPPDATA'];
        if (localAppData == null || localAppData.isEmpty) {
          return null;
        }
        return p.join(localAppData, 'HorsePos', 'App', _windowsExecutableName);
      case PlatformMode.macos:
        final home = Platform.environment['HOME'];
        if (home == null || home.isEmpty) {
          return null;
        }
        return p.join(home, 'Applications', _macosBundleName);
      case PlatformMode.unsupported:
        return null;
    }
  }

  Future<Directory> _ensureWindowsAppDir() async {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      throw Exception('LOCALAPPDATA no está disponible.');
    }
    return Directory(p.join(localAppData, 'HorsePos', 'App'));
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
      throw Exception('No pude resolver la carpeta local de HorsePos.');
    }
    return Directory(p.join(home, '.horsepos', 'resources'));
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

enum LauncherAction { none, install, update }

class UpdateManifest {
  const UpdateManifest({
    required this.appVersion,
    required this.appUrl,
    required this.launcherVersion,
    required this.launcherUrl,
    required this.launcherInstallerUrl,
    required this.resources,
  });

  final String? appVersion;
  final String? appUrl;
  final String? launcherVersion;
  final String? launcherUrl;
  final String? launcherInstallerUrl;
  final BootstrapResourcesManifest? resources;

  factory UpdateManifest.fromVersionJson(
    Map<String, dynamic> json,
    PlatformMode platformMode,
  ) {
    final appNode = json['app'];
    final launcherNode = json['launcher'];
    final appMap = appNode is Map<String, dynamic> ? appNode : null;
    final launcherMap = launcherNode is Map<String, dynamic>
        ? launcherNode
        : null;
    final platformKey = switch (platformMode) {
      PlatformMode.windows => 'windows',
      PlatformMode.macos => 'macos',
      PlatformMode.unsupported => 'generic',
    };
    final appPlatformMap = appMap?[platformKey] is Map<String, dynamic>
        ? appMap![platformKey] as Map<String, dynamic>
        : null;
    final launcherPlatformMap =
        launcherMap?[platformKey] is Map<String, dynamic>
        ? launcherMap![platformKey] as Map<String, dynamic>
        : null;
    final resourcesMap = json['resources'] is Map<String, dynamic>
        ? json['resources'] as Map<String, dynamic>
        : null;

    return UpdateManifest(
      appVersion:
          appPlatformMap?['version']?.toString() ??
          appMap?['version']?.toString() ??
          json['version']?.toString(),
      appUrl:
          appPlatformMap?['url']?.toString() ??
          appMap?['url']?.toString() ??
          json['url']?.toString(),
      launcherVersion:
          launcherPlatformMap?['version']?.toString() ??
          launcherMap?['version']?.toString(),
      launcherUrl:
          launcherPlatformMap?['url']?.toString() ??
          launcherMap?['url']?.toString(),
      launcherInstallerUrl:
          launcherPlatformMap?['installer_url']?.toString() ??
          launcherMap?['installer_url']?.toString(),
      resources: BootstrapResourcesManifest.fromJson(resourcesMap),
    );
  }
}

class BootstrapResourcesManifest {
  const BootstrapResourcesManifest({
    required this.catalogVersion,
    required this.catalogUrl,
    required this.imagesVersion,
    required this.imagesUrl,
  });

  final String? catalogVersion;
  final String? catalogUrl;
  final String? imagesVersion;
  final String? imagesUrl;

  factory BootstrapResourcesManifest.fromJson(Map<String, dynamic>? json) {
    final catalog = json?['catalog'] is Map<String, dynamic>
        ? json!['catalog'] as Map<String, dynamic>
        : null;
    final images = json?['images'] is Map<String, dynamic>
        ? json!['images'] as Map<String, dynamic>
        : null;
    return BootstrapResourcesManifest(
      catalogVersion: catalog?['version']?.toString(),
      catalogUrl: catalog?['url']?.toString(),
      imagesVersion: images?['version']?.toString(),
      imagesUrl: images?['url']?.toString(),
    );
  }
}
