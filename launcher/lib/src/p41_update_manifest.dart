class P41UpdateManifest {
  const P41UpdateManifest({
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
  final P41ResourceBundle? resources;

  factory P41UpdateManifest.fromBackendManifest(
    Map<String, dynamic> json,
    P41PlatformMode platformMode,
  ) {
    final appNode = json['app'];
    final launcherNode = json['launcher'];
    final appMap = appNode is Map<String, dynamic> ? appNode : null;
    final launcherMap = launcherNode is Map<String, dynamic>
        ? launcherNode
        : null;
    final platformKey = switch (platformMode) {
      P41PlatformMode.windows => 'windows',
      P41PlatformMode.macos => 'macos',
      P41PlatformMode.unsupported => 'generic',
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

    return P41UpdateManifest(
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
      resources: P41ResourceBundle.fromJson(resourcesMap),
    );
  }

  factory P41UpdateManifest.fromVersionJson(
    Map<String, dynamic> json,
    P41PlatformMode platformMode,
  ) => P41UpdateManifest.fromBackendManifest(json, platformMode);
}

class P41ResourceBundle {
  const P41ResourceBundle({
    required this.catalogVersion,
    required this.catalogUrl,
    required this.imagesVersion,
    required this.imagesUrl,
  });

  final String? catalogVersion;
  final String? catalogUrl;
  final String? imagesVersion;
  final String? imagesUrl;

  factory P41ResourceBundle.fromJson(Map<String, dynamic>? json) {
    final catalog = json?['catalog'] is Map<String, dynamic>
        ? json!['catalog'] as Map<String, dynamic>
        : null;
    final images = json?['images'] is Map<String, dynamic>
        ? json!['images'] as Map<String, dynamic>
        : null;
    return P41ResourceBundle(
      catalogVersion: catalog?['version']?.toString(),
      catalogUrl: catalog?['url']?.toString(),
      imagesVersion: images?['version']?.toString(),
      imagesUrl: images?['url']?.toString(),
    );
  }
}

enum P41PlatformMode { windows, macos, unsupported }

enum P41LauncherAction { none, install, update }

enum P41BootstrapStage {
  idle,
  inspecting,
  checkingManifest,
  syncingApp,
  syncingResources,
  ready,
  failed,
}
