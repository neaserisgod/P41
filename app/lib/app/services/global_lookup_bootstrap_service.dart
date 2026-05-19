import 'dart:io';

import 'package:archive/archive_io.dart';

import 'global_lookup_local_service.dart';

const _globalLookupApiBaseUrl = String.fromEnvironment(
  'P41_API_BASE_URL',
  defaultValue: 'http://31.97.166.250',
);
const _globalLookupCatalogUrl = String.fromEnvironment(
  'P41_CATALOG_URL',
  defaultValue: '$_globalLookupApiBaseUrl/static/bootstrap/p41/global_lookup.sqlite',
);
const _globalLookupImagesUrl = String.fromEnvironment(
  'P41_IMAGES_URL',
  defaultValue: '$_globalLookupApiBaseUrl/static/bootstrap/p41/imagenes_productos.zip',
);

class GlobalLookupBootstrapService {
  GlobalLookupBootstrapService({
    GlobalLookupLocalService? localService,
  }) : _localService = localService ?? const GlobalLookupLocalService();

  final GlobalLookupLocalService _localService;

  Future<bool> hasRequiredResources() {
    return _localService.hasRequiredResources();
  }

  Future<void> downloadRequiredResources({
    void Function(String message, double? progress)? onStatus,
  }) async {
    final resourcesDir = _localService.resourcesDirectory;
    await resourcesDir.create(recursive: true);

    onStatus?.call('Descargando catálogo global...', 0.1);
    await _downloadFile(
      _globalLookupCatalogUrl,
      _localService.catalogFile,
      onProgress: (progress) => onStatus?.call(
        'Descargando catálogo global...',
        progress == null ? null : progress * 0.45,
      ),
    );

    final imagesZip = File(
      '${resourcesDir.path}${Platform.pathSeparator}imagenes_productos.zip',
    );
    onStatus?.call('Descargando imágenes globales...', 0.55);
    await _downloadFile(
      _globalLookupImagesUrl,
      imagesZip,
      onProgress: (progress) => onStatus?.call(
        'Descargando imágenes globales...',
        progress == null ? null : 0.5 + (progress * 0.35),
      ),
    );

    onStatus?.call('Preparando imágenes globales...', 0.92);
    await _extractImagesBootstrap(imagesZip);
    if (await imagesZip.exists()) {
      await imagesZip.delete();
    }
    onStatus?.call('Catálogo global listo.', 1);
  }

  Future<void> _downloadFile(
    String url,
    File target, {
    void Function(double? progress)? onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(minutes: 8));
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('HTTP ${response.statusCode}');
      }
      await target.parent.create(recursive: true);
      final sink = target.openWrite();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress?.call(receivedBytes / totalBytes);
          } else {
            onProgress?.call(null);
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _extractImagesBootstrap(File zipFile) async {
    final targetDir = _localService.imagesDirectory;
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
      '${targetDir.path}${Platform.pathSeparator}imagenes_productos',
    );
    if (!await nestedDir.exists()) {
      return;
    }

    var rootHasImages = false;
    await for (final entity in targetDir.list(followLinks: false)) {
      if (entity is File && _isSupportedImage(entity.path)) {
        rootHasImages = true;
        break;
      }
    }
    if (rootHasImages) {
      return;
    }

    await for (final entity in nestedDir.list(followLinks: false)) {
      final destinationPath =
          '${targetDir.path}${Platform.pathSeparator}${_basename(entity.path)}';
      if (entity is File) {
        await entity.rename(destinationPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(destinationPath));
        await entity.delete(recursive: true);
      }
    }
    await nestedDir.delete(recursive: true);
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final destinationPath =
          '${target.path}${Platform.pathSeparator}${_basename(entity.path)}';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destinationPath));
      } else if (entity is File) {
        await entity.copy(destinationPath);
      }
    }
  }

  bool _isSupportedImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index == -1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }
}
