import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../models/global_catalog_product.dart';

class GlobalLookupLocalService {
  const GlobalLookupLocalService();

  Future<bool> hasCatalog() async {
    return catalogFile.exists();
  }

  Future<bool> hasImages() async {
    if (!await imagesDirectory.exists()) {
      return false;
    }
    await for (final entity in imagesDirectory.list(followLinks: false)) {
      if (entity is File && _isSupportedImage(entity.path)) {
        return true;
      }
    }
    final nestedDirectory = Directory(
      '${imagesDirectory.path}${Platform.pathSeparator}imagenes_productos',
    );
    if (!await nestedDirectory.exists()) {
      return false;
    }
    await for (final entity in nestedDirectory.list(followLinks: false)) {
      if (entity is File && _isSupportedImage(entity.path)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> hasRequiredResources() async {
    return await hasCatalog() && await hasImages();
  }

  Future<GlobalCatalogProduct?> lookup(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty || !await hasCatalog()) {
      return null;
    }

    Database? db;
    try {
      db = sqlite3.open(catalogFile.path, mode: OpenMode.readOnly);
      final rows = db.select(
        '''
        SELECT barcode, name, brand, category, description, suggested_price, unit
        FROM global_products
        WHERE barcode = ?
        LIMIT 1
        ''',
        [normalized],
      );
      if (rows.isEmpty) {
        return null;
      }
      return _mapRow(rows.first);
    } catch (_) {
      return null;
    } finally {
      db?.dispose();
    }
  }

  Future<List<GlobalCatalogProduct>> search(
    String query, {
    int limit = 24,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 3 || !await hasCatalog()) {
      return const [];
    }

    final lower = normalized.toLowerCase();
    final barcodePrefix = '$normalized%';
    final fuzzy = '%$lower%';

    Database? db;
    try {
      db = sqlite3.open(catalogFile.path, mode: OpenMode.readOnly);
      final rows = db.select(
        '''
        SELECT
          barcode,
          name,
          brand,
          category,
          description,
          suggested_price,
          unit,
          CASE
            WHEN barcode = ? THEN 0
            WHEN barcode LIKE ? THEN 1
            WHEN lower(name) = ? THEN 2
            WHEN lower(name) LIKE ? THEN 3
            WHEN lower(brand) LIKE ? THEN 4
            ELSE 5
          END AS rank_value
        FROM global_products
        WHERE barcode LIKE ?
          OR lower(name) LIKE ?
          OR lower(brand) LIKE ?
        ORDER BY rank_value ASC, name COLLATE NOCASE ASC
        LIMIT ?
        ''',
        [
          normalized,
          barcodePrefix,
          lower,
          fuzzy,
          fuzzy,
          barcodePrefix,
          fuzzy,
          fuzzy,
          limit,
        ],
      );
      return rows.map(_mapRow).toList(growable: false);
    } catch (_) {
      return const [];
    } finally {
      db?.dispose();
    }
  }

  GlobalCatalogProduct _mapRow(Row row) {
    final barcode = row['barcode']?.toString() ?? '';
    return GlobalCatalogProduct(
      barcode: barcode,
      name: row['name']?.toString() ?? 'Producto',
      brand: row['brand']?.toString() ?? '',
      category: row['category']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      imageUrl: _resolveLocalImage(barcode),
      suggestedPrice: (row['suggested_price'] as num?)?.toDouble(),
      unit: row['unit']?.toString() ?? 'unit',
    );
  }

  String _resolveLocalImage(String barcode) {
    if (barcode.isEmpty) {
      return '';
    }
    final candidates = <File>[
      File('${imagesDirectory.path}${Platform.pathSeparator}$barcode.jpg'),
      File('${imagesDirectory.path}${Platform.pathSeparator}$barcode.jpeg'),
      File('${imagesDirectory.path}${Platform.pathSeparator}$barcode.png'),
      File(
        '${imagesDirectory.path}${Platform.pathSeparator}imagenes_productos${Platform.pathSeparator}$barcode.jpg',
      ),
      File(
        '${imagesDirectory.path}${Platform.pathSeparator}imagenes_productos${Platform.pathSeparator}$barcode.jpeg',
      ),
      File(
        '${imagesDirectory.path}${Platform.pathSeparator}imagenes_productos${Platform.pathSeparator}$barcode.png',
      ),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.path;
      }
    }
    return '';
  }

  bool _isSupportedImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  File get catalogFile => File(
    '${resourcesDirectory.path}${Platform.pathSeparator}global_lookup.sqlite',
  );

  Directory get imagesDirectory => Directory(
    '${resourcesDirectory.path}${Platform.pathSeparator}imagenes_productos',
  );

  Directory get resourcesDirectory => Directory(
    '${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.'}${Platform.pathSeparator}.p41${Platform.pathSeparator}resources',
  );
}
