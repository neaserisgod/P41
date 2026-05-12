import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catalog_product.dart';
import '../models/global_catalog_product.dart';
import '../models/inventory_space.dart';
import '../models/product_pricing_rules.dart';
import '../models/session_context.dart';
import '../services/catalog_api_service.dart';
import '../services/local_store_service.dart';

class CatalogController extends ChangeNotifier {
  static const List<String> _defaultCategories = [
    'Almacen',
    'Bebidas',
    'Cigarrillos',
    'Golosinas',
    'Lacteos',
    'Congelados',
    'Limpieza',
    'Perfumeria',
    'Panificados',
    'Fiambres',
    'Verduleria',
    'Carniceria',
    'Mascotas',
    'Bazar',
    'Varios',
  ];

  CatalogController({
    required String accessToken,
    required SessionBranch initialBranch,
    required String scopeKey,
    CatalogApiService? apiService,
    LocalStoreService? localStoreService,
  })  : _accessToken = accessToken,
        _activeBranch = initialBranch,
        _scopeKey = scopeKey,
        _apiService = apiService ?? CatalogApiService(),
        _localStoreService = localStoreService ?? LocalStoreService() {
    unawaited(reload());
  }

  final CatalogApiService _apiService;
  final LocalStoreService _localStoreService;
  final List<CatalogProduct> _products = [];
  final List<InventorySpace> _manualLocations = [];
  final String _deviceId = 'p41-desktop';
  final Map<String, String> _supplierNamesById = {};
  String _accessToken;
  SessionBranch _activeBranch;
  String _scopeKey;
  bool _isLoading = false;
  String? _errorMessage;
  ProductPricingRules _pricingDefaults = ProductPricingRules.defaults;

  List<CatalogProduct> get products => List.unmodifiable(_products);
  List<CatalogProduct> get activeProducts =>
      _products.where((product) => product.isActive).toList();
  List<InventorySpace> get inventorySpaces => List.unmodifiable(_manualLocations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductPricingRules get pricingDefaults => _pricingDefaults;

  Future<List<GlobalCatalogProduct>> searchGlobalProducts(String query) {
    return _apiService.searchGlobalProducts(query);
  }

  Future<GlobalCatalogProduct?> lookupGlobalProduct(String barcode) {
    return _apiService.lookupGlobalProduct(barcode);
  }

  Future<void> updatePricingDefaults(ProductPricingRules rules) async {
    _pricingDefaults = rules;
    await _localStoreService.writeSection(_scopeKey, _pricingDefaultsSection, rules.toJson());
    notifyListeners();
  }

  List<String> get supplierNames =>
      _supplierNamesById.values.where((name) => name.trim().isNotEmpty).toSet().toList()..sort();

  List<String> get locationNames =>
      {
        ..._products.map((product) => product.locationName),
        ..._manualLocations.map((location) => location.name),
      }.where((name) => name.trim().isNotEmpty).toList()
        ..sort();

  List<String> get locationTypes =>
      {
        ..._products.map((product) => product.locationType),
        ..._manualLocations.map((location) => location.type),
      }.where((type) => type.trim().isNotEmpty).toList()
        ..sort();

  List<String> get categories =>
      {..._defaultCategories, ..._products.map((product) => product.category).where((item) => item.trim().isNotEmpty)}.toList()
        ..sort();

  List<InventorySpace> inventorySpacesForType(String type) {
    final normalizedType = type.trim().toLowerCase();
    return _manualLocations
        .where((location) => location.type.trim().toLowerCase() == normalizedType)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  InventorySpace? findInventorySpace({
    required String name,
    required String type,
  }) {
    final normalizedName = name.trim().toLowerCase();
    final normalizedType = type.trim().toLowerCase();
    if (normalizedName.isEmpty || normalizedType.isEmpty) {
      return null;
    }
    for (final space in _manualLocations) {
      if (space.name.trim().toLowerCase() == normalizedName &&
          space.type.trim().toLowerCase() == normalizedType) {
        return space;
      }
    }
    return null;
  }

  Future<void> upsertSupplierReference({
    required String supplierId,
    required String supplierName,
  }) async {
    if (supplierId.trim().isEmpty || supplierName.trim().isEmpty) {
      return;
    }
    _supplierNamesById[supplierId] = supplierName.trim();
    await _localStoreService.saveCatalogSupplierRefs(
      scopeKey: _scopeKey,
      suppliersById: _supplierNamesById,
    );
    notifyListeners();
  }

  Future<void> syncSupplierReferences(Map<String, String> references) async {
    var changed = false;
    for (final entry in references.entries) {
      final supplierId = entry.key.trim();
      final supplierName = entry.value.trim();
      if (supplierId.isEmpty || supplierName.isEmpty) {
        continue;
      }
      if (_supplierNamesById[supplierId] == supplierName) {
        continue;
      }
      _supplierNamesById[supplierId] = supplierName;
      changed = true;
    }
    if (!changed) {
      return;
    }
    await _localStoreService.saveCatalogSupplierRefs(
      scopeKey: _scopeKey,
      suppliersById: _supplierNamesById,
    );
    notifyListeners();
  }

  Future<void> createInventorySpace({
    required String name,
    required String type,
  }) async {
    await ensureInventorySpace(name: name, type: type);
  }

  Future<InventorySpace?> ensureInventorySpace({
    required String name,
    required String type,
  }) async {
    final normalizedName = name.trim();
    final normalizedType = type.trim().isEmpty ? 'Mueble' : type.trim();
    if (normalizedName.isEmpty) {
      return null;
    }
    final id = buildLocationId(
      locationName: normalizedName,
      locationType: normalizedType,
    );
    InventorySpace? existing;
    for (final location in _manualLocations) {
      if (location.id == id) {
        existing = location;
        break;
      }
    }
    if (existing != null) {
      return existing;
    }
    final space = InventorySpace(
      id: id,
      name: normalizedName,
      type: normalizedType,
    );
    _manualLocations.add(space);
    _manualLocations.sort((a, b) {
      final byType = a.type.toLowerCase().compareTo(b.type.toLowerCase());
      if (byType != 0) {
        return byType;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    await _saveLocalSnapshot();
    notifyListeners();
    return space;
  }

  Future<void> reload() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _restorePricingDefaults();
    if (await _localStoreService.isOfflineOnly()) {
      final restored = await _restoreLocalSnapshot();
      _errorMessage = restored ? null : 'Todavía no hay productos guardados.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final branchId = int.tryParse(_activeBranch.id);
      final payload = await _apiService.pullCatalog(
        token: _accessToken,
        deviceId: _deviceId,
        branchId: branchId,
      );

      _supplierNamesById
        ..clear()
        ..addEntries(
          payload.suppliers.map(
            (supplier) => MapEntry(
              supplier['id']?.toString() ?? '',
              supplier['name']?.toString() ?? '',
            ),
          ).where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
        );

      if (payload.products.isEmpty) {
        final restored = await _restoreLocalSnapshot();
        _errorMessage = restored ? null : 'Todavía no hay productos guardados.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _products
        ..clear()
        ..addAll(payload.products.map(_productFromApi));
      await _saveLocalSnapshot();
    } on CatalogApiException catch (error) {
      final restored = await _restoreLocalSnapshot();
      _errorMessage = restored ? null : error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSession({
    required String accessToken,
    required SessionBranch activeBranch,
    required String scopeKey,
  }) async {
    final tokenChanged = _accessToken != accessToken;
    final branchChanged = _activeBranch.id != activeBranch.id;
    final scopeChanged = _scopeKey != scopeKey;
    _accessToken = accessToken;
    _activeBranch = activeBranch;
    _scopeKey = scopeKey;
    if (tokenChanged || branchChanged || scopeChanged) {
      await reload();
    }
  }

  Future<void> createProduct({
    required String name,
    required String sku,
    required String barcode,
    required String imageUrl,
    required String category,
    required String supplierName,
    required String locationName,
    required String locationType,
    required double price,
    required double cost,
    required int stock,
    required int minStock,
    required ProductPricingRules pricingRules,
    DateTime? expirationDate,
    required bool isActive,
  }) async {
    final normalizedLocationName = locationName.trim().isEmpty ? _activeBranch.name : locationName.trim();
    final normalizedLocationType = locationType.trim().isEmpty ? 'Mueble' : locationType.trim();
    final resolvedSpace = await ensureInventorySpace(
      name: normalizedLocationName,
      type: normalizedLocationType,
    );
    if (await _localStoreService.isOfflineOnly()) {
      final supplierId = _stableSupplierId(supplierName);
      final localProduct = CatalogProduct(
        id: 'local-product-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        sku: sku.trim().isEmpty ? _skuFromName(name) : sku.trim(),
        barcode: barcode.trim(),
        category: category.trim().isEmpty ? 'General' : category.trim(),
        supplierId: supplierId,
        supplierName: supplierName,
        locationId: resolvedSpace?.id ?? _locationIdFromName(normalizedLocationName, normalizedLocationType),
        locationName: normalizedLocationName,
        locationType: normalizedLocationType,
        price: price,
        cost: cost,
        stock: stock,
        minStock: minStock,
        pricingRules: pricingRules,
        expirationDate: expirationDate,
        imageUrl: imageUrl.trim(),
        isActive: isActive,
      );
      if (supplierName.trim().isNotEmpty) {
        _supplierNamesById[supplierId] = supplierName.trim();
      }
      _products.add(localProduct);
      await _saveLocalSnapshot();
      _errorMessage = 'Producto guardado.';
      notifyListeners();
      return;
    }
    try {
      final supplierId = _supplierIdForName(supplierName);
      final response = await _apiService.createProduct(
        token: _accessToken,
        body: {
          'sku': sku.trim().isEmpty ? _skuFromName(name) : sku.trim(),
          'name': name,
          'category': category.trim().isEmpty ? 'General' : category.trim(),
          'price': price,
          'cost': cost,
          'stock': stock,
          'min_stock': minStock,
          'is_active': isActive,
          'supplier_id': supplierId,
          'branch_id': int.tryParse(_activeBranch.id),
          'description': _encodeProductMeta(
            locationName: normalizedLocationName,
            locationType: normalizedLocationType,
            expirationDate: expirationDate,
            barcode: barcode,
            imageUrl: imageUrl,
            pricingRules: pricingRules,
          ),
        },
      );
      _products.add(
        _productFromApi(response).copyWith(
          barcode: barcode.trim(),
          locationId: resolvedSpace?.id ?? _locationIdFromName(normalizedLocationName, normalizedLocationType),
          locationName: normalizedLocationName,
          locationType: normalizedLocationType,
          supplierName: supplierName,
          minStock: minStock,
          pricingRules: pricingRules,
          expirationDate: expirationDate,
          imageUrl: imageUrl.trim(),
        ),
      );
      await _saveLocalSnapshot();
      notifyListeners();
    } on CatalogApiException catch (error) {
      final supplierId = _stableSupplierId(supplierName);
      final localProduct = CatalogProduct(
        id: 'local-product-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        sku: sku.trim().isEmpty ? _skuFromName(name) : sku.trim(),
        barcode: barcode.trim(),
        category: category.trim().isEmpty ? 'General' : category.trim(),
        supplierId: supplierId,
        supplierName: supplierName,
        locationId: resolvedSpace?.id ?? _locationIdFromName(normalizedLocationName, normalizedLocationType),
        locationName: normalizedLocationName,
        locationType: normalizedLocationType,
        price: price,
        cost: cost,
        stock: stock,
        minStock: minStock,
        pricingRules: pricingRules,
        expirationDate: expirationDate,
        imageUrl: imageUrl.trim(),
        isActive: isActive,
      );
      if (supplierName.trim().isNotEmpty) {
        _supplierNamesById[supplierId] = supplierName.trim();
      }
      _products.add(localProduct);
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Producto guardado.'
          : error.message;
      notifyListeners();
    }
  }

  Future<void> updateProduct(CatalogProduct product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      return;
    }
    final normalizedSpace = await ensureInventorySpace(
      name: product.locationName,
      type: product.locationType,
    );
    final normalizedProduct = product.copyWith(
      supplierId: product.supplierName.trim().isEmpty
          ? ''
          : (_supplierIdForName(product.supplierName) ?? _stableSupplierId(product.supplierName)),
      locationId: normalizedSpace?.id ?? _locationIdFromName(product.locationName, product.locationType),
    );
    _products[index] = normalizedProduct;
    notifyListeners();
    if (await _localStoreService.isOfflineOnly()) {
      await _saveLocalSnapshot();
      _errorMessage = 'Producto actualizado.';
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.updateProduct(
        token: _accessToken,
        productId: product.id,
        body: {
          'sku': normalizedProduct.sku,
          'name': normalizedProduct.name,
          'category': normalizedProduct.category,
          'price': normalizedProduct.price,
          'cost': normalizedProduct.cost,
          'stock': normalizedProduct.stock,
          'min_stock': normalizedProduct.minStock,
          'is_active': normalizedProduct.isActive,
          'supplier_id': _supplierIdForName(normalizedProduct.supplierName),
          'description': _encodeProductMeta(
            locationName: normalizedProduct.locationName,
            locationType: normalizedProduct.locationType,
            expirationDate: normalizedProduct.expirationDate,
            barcode: normalizedProduct.barcode,
            imageUrl: normalizedProduct.imageUrl,
            pricingRules: normalizedProduct.pricingRules,
          ),
        },
      );
      _products[index] = _productFromApi(response).copyWith(
        barcode: normalizedProduct.barcode,
        locationId: normalizedProduct.locationId,
        locationName: normalizedProduct.locationName,
        locationType: normalizedProduct.locationType,
        supplierName: normalizedProduct.supplierName,
        minStock: normalizedProduct.minStock,
        pricingRules: normalizedProduct.pricingRules,
        expirationDate: normalizedProduct.expirationDate,
        imageUrl: normalizedProduct.imageUrl,
      );
      await _saveLocalSnapshot();
      notifyListeners();
    } on CatalogApiException catch (error) {
      _products[index] = normalizedProduct;
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Producto actualizado.'
          : error.message;
      notifyListeners();
    }
  }

  Future<void> applyTransactionStockReduction({
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      final sku = item['sku']?.toString() ?? '';
      final quantity = (item['quantity'] as num?)?.round() ?? 0;
      final index = _products.indexWhere((product) => product.sku == sku);
      if (index == -1 || quantity <= 0) {
        continue;
      }
      final current = _products[index];
      _products[index] = current.copyWith(stock: (current.stock - quantity).clamp(0, 999999));
    }
    await _saveLocalSnapshot();
    notifyListeners();
  }

  Future<void> restoreTransactionStock({
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      final sku = item['sku']?.toString() ?? '';
      final quantity = (item['quantity'] as num?)?.round() ?? 0;
      final index = _products.indexWhere((product) => product.sku == sku);
      if (index == -1 || quantity <= 0) {
        continue;
      }
      final current = _products[index];
      _products[index] = current.copyWith(stock: current.stock + quantity);
    }
    await _saveLocalSnapshot();
    notifyListeners();
  }

  Future<void> applyOrderStockIncrease({
    required List<Map<String, dynamic>> items,
  }) async {
    for (final item in items) {
      final sku = item['sku']?.toString() ?? '';
      final quantity = (item['quantity'] as num?)?.round() ?? 0;
      final index = _products.indexWhere((product) => product.sku == sku);
      if (index == -1 || quantity <= 0) {
        continue;
      }
      final current = _products[index];
      _products[index] = current.copyWith(stock: current.stock + quantity);
    }
    await _saveLocalSnapshot();
    notifyListeners();
  }

  CatalogProduct _productFromApi(Map<String, dynamic> json) {
    final supplierId = json['supplier_id']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final meta = _metaFromDescription(description);
    return CatalogProduct(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Producto',
      sku: json['sku']?.toString() ?? '',
      barcode: meta.barcode,
      category: (json['category']?.toString().trim().isNotEmpty ?? false)
          ? json['category'].toString()
          : 'General',
      supplierId: supplierId,
      supplierName: _supplierNamesById[supplierId] ?? 'Sin proveedor',
      locationId: _locationIdFromName(meta.locationName, meta.locationType),
      locationName: meta.locationName,
      locationType: meta.locationType,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      stock: ((json['stock'] as num?)?.round() ?? 0),
      minStock: ((json['min_stock'] as num?)?.round() ?? 0),
      pricingRules: meta.pricingRules,
      expirationDate: meta.expirationDate,
      imageUrl: meta.imageUrl,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  String? _supplierIdForName(String supplierName) {
    for (final entry in _supplierNamesById.entries) {
      if (entry.value.toLowerCase() == supplierName.trim().toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  String _stableSupplierId(String supplierName) {
    final existingId = _supplierIdForName(supplierName);
    if (existingId != null) {
      return existingId;
    }
    final normalized = supplierName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (normalized.isEmpty) {
      return 'local-supplier-${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'local-supplier-$normalized';
  }

  Future<void> _saveLocalSnapshot() async {
    await _localStoreService.saveCatalogSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
      products: _products.map(_productToJson).toList(),
      suppliersById: _supplierNamesById,
      inventorySpaces: _manualLocations.map(_inventorySpaceToJson).toList(),
    );
  }

  Future<bool> _restoreLocalSnapshot() async {
    final tableSnapshot = await _localStoreService.readCatalogSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
    );
    if (tableSnapshot != null) {
      final productsJson = tableSnapshot['products'];
      final suppliersJson = tableSnapshot['suppliers'];
      final locationsJson = tableSnapshot['inventory_spaces'];
      _supplierNamesById
        ..clear()
        ..addAll(
          suppliersJson is Map<String, dynamic>
              ? suppliersJson.map((key, value) => MapEntry(key, value.toString()))
              : const <String, String>{},
        );
      _manualLocations
        ..clear()
        ..addAll(
          (locationsJson is List<dynamic> ? locationsJson : const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_inventorySpaceFromJson),
        );
      _products
        ..clear()
        ..addAll(
          (productsJson is List<dynamic> ? productsJson : const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_productFromJson),
        );
      return true;
    }

    final productsJson = await _localStoreService.readSection(_scopeKey, _catalogSection);
    final suppliersJson = await _localStoreService.readSection(_scopeKey, _catalogSuppliersSection);
    final locationsJson = await _localStoreService.readSection(_scopeKey, _catalogLocationsSection);
    if (productsJson is! List<dynamic>) {
      return false;
    }
    _supplierNamesById
      ..clear()
      ..addAll(
        suppliersJson is Map<String, dynamic>
            ? suppliersJson.map((key, value) => MapEntry(key, value.toString()))
            : const <String, String>{},
      );
    _manualLocations
      ..clear()
      ..addAll(
        (locationsJson is List<dynamic> ? locationsJson : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_inventorySpaceFromJson),
      );
    _products
      ..clear()
      ..addAll(
        productsJson
            .whereType<Map<String, dynamic>>()
            .map(_productFromJson),
      );
    return true;
  }

  Future<void> _restorePricingDefaults() async {
    final stored = await _localStoreService.readSection(_scopeKey, _pricingDefaultsSection);
    if (stored is Map<String, dynamic>) {
      _pricingDefaults = ProductPricingRules.fromJson(stored);
      return;
    }
    _pricingDefaults = ProductPricingRules.defaults;
  }

  Map<String, dynamic> _productToJson(CatalogProduct product) {
    return {
      'id': product.id,
      'name': product.name,
      'sku': product.sku,
      'barcode': product.barcode,
      'category': product.category,
      'supplier_id': product.supplierId,
      'supplier_name': product.supplierName,
      'location_id': product.locationId,
      'location_name': product.locationName,
      'location_type': product.locationType,
      'image_url': product.imageUrl,
      'price': product.price,
      'cost': product.cost,
      'stock': product.stock,
      'min_stock': product.minStock,
      'pricing_rules': product.pricingRules.toJson(),
      'expiration_date': product.expirationDate?.toIso8601String(),
      'is_active': product.isActive,
    };
  }

  CatalogProduct _productFromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Producto',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? 'Sin proveedor',
      locationId: json['location_id']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? _activeBranch.name,
      locationType: json['location_type']?.toString() ?? 'Mueble',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.round() ?? 0,
      minStock: (json['min_stock'] as num?)?.round() ?? 0,
      pricingRules: json['pricing_rules'] is Map<String, dynamic>
          ? ProductPricingRules.fromJson(json['pricing_rules'] as Map<String, dynamic>)
          : _pricingDefaults,
      expirationDate: json['expiration_date'] == null ? null : DateTime.tryParse(json['expiration_date'].toString()),
      imageUrl: json['image_url']?.toString() ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> _inventorySpaceToJson(InventorySpace location) {
    return {
      'id': location.id,
      'name': location.name,
      'type': location.type,
    };
  }

  InventorySpace _inventorySpaceFromJson(Map<String, dynamic> json) {
    return InventorySpace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? _activeBranch.name,
      type: json['type']?.toString() ?? 'Mueble',
    );
  }

  bool _isConnectivityError(CatalogApiException error) {
    return error.statusCode == null &&
        (error.message.contains('No se pudo conectar') || error.message.contains('Tiempo de espera'));
  }

  String _locationIdFromName(String locationName, String locationType) {
    return buildLocationId(
      locationName: locationName,
      locationType: locationType,
    );
  }

  String buildLocationId({
    required String locationName,
    required String locationType,
  }) {
    final normalized = '${locationType.trim()} ${locationName.trim()}'.trim();
    if (normalized.isEmpty) {
      return _activeBranch.id;
    }
    return normalized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  String _encodeProductMeta({
    required String locationName,
    required String locationType,
    DateTime? expirationDate,
    String? barcode,
    String? imageUrl,
    ProductPricingRules? pricingRules,
  }) {
    final lines = <String>[
      'Lugar: ${locationName.trim()}',
      'Tipo: ${locationType.trim()}',
    ];
    if (barcode?.trim().isNotEmpty ?? false) {
      lines.add('Barcode: ${barcode!.trim()}');
    }
    if (imageUrl?.trim().isNotEmpty ?? false) {
      lines.add('Imagen: ${imageUrl!.trim()}');
    }
    final resolvedPricing = pricingRules ?? _pricingDefaults;
    lines.add('Markup: ${resolvedPricing.markupPercent}');
    lines.add('Bonificacion: ${resolvedPricing.bonusPercent}');
    lines.add('BonificacionActiva: ${resolvedPricing.bonusEnabled}');
    lines.add('Iva: ${resolvedPricing.vatPercent}');
    lines.add('IvaActivo: ${resolvedPricing.vatEnabled}');
    if (expirationDate != null) {
      lines.add('Vencimiento: ${expirationDate.toIso8601String().split('T').first}');
    }
    return lines.join('\n');
  }

  _ProductMeta _metaFromDescription(String description) {
    final lines = description.split('\n');
    String? locationName;
    String? locationType;
    String? barcode;
    String? imageUrl;
    double? markupPercent;
    double? bonusPercent;
    bool? bonusEnabled;
    double? vatPercent;
    bool? vatEnabled;
    DateTime? expirationDate;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('Lugar:')) {
        locationName = line.substring('Lugar:'.length).trim();
      } else if (line.startsWith('Tipo:')) {
        locationType = line.substring('Tipo:'.length).trim();
      } else if (line.startsWith('Barcode:')) {
        barcode = line.substring('Barcode:'.length).trim();
      } else if (line.startsWith('Imagen:')) {
        imageUrl = line.substring('Imagen:'.length).trim();
      } else if (line.startsWith('Markup:')) {
        markupPercent = double.tryParse(line.substring('Markup:'.length).trim());
      } else if (line.startsWith('Bonificacion:')) {
        bonusPercent = double.tryParse(line.substring('Bonificacion:'.length).trim());
      } else if (line.startsWith('BonificacionActiva:')) {
        bonusEnabled = line.substring('BonificacionActiva:'.length).trim().toLowerCase() == 'true';
      } else if (line.startsWith('Iva:')) {
        vatPercent = double.tryParse(line.substring('Iva:'.length).trim());
      } else if (line.startsWith('IvaActivo:')) {
        vatEnabled = line.substring('IvaActivo:'.length).trim().toLowerCase() == 'true';
      } else if (line.startsWith('Vencimiento:')) {
        expirationDate = DateTime.tryParse(line.substring('Vencimiento:'.length).trim());
      }
    }

    if ((locationName == null || locationType == null) && description.isNotEmpty) {
      final legacy = _legacyLocationLabelFromDescription(description);
      locationName ??= legacy.$1;
      locationType ??= legacy.$2;
    }

    return _ProductMeta(
      locationName: (locationName?.trim().isNotEmpty ?? false) ? locationName!.trim() : _activeBranch.name,
      locationType: (locationType?.trim().isNotEmpty ?? false) ? locationType!.trim() : 'Mueble',
      barcode: barcode?.trim() ?? '',
      imageUrl: imageUrl?.trim() ?? '',
      pricingRules: ProductPricingRules(
        markupPercent: markupPercent ?? _pricingDefaults.markupPercent,
        bonusPercent: bonusPercent ?? _pricingDefaults.bonusPercent,
        bonusEnabled: bonusEnabled ?? _pricingDefaults.bonusEnabled,
        vatPercent: vatPercent ?? _pricingDefaults.vatPercent,
        vatEnabled: vatEnabled ?? _pricingDefaults.vatEnabled,
      ),
      expirationDate: expirationDate,
    );
  }

  (String, String) _legacyLocationLabelFromDescription(String description) {
    const prefix = 'Ubicacion: ';
    if (description.startsWith(prefix) && description.endsWith(')')) {
      final raw = description.substring(prefix.length);
      final separator = raw.lastIndexOf(' (');
      if (separator != -1) {
        return (
          raw.substring(0, separator).trim(),
          raw.substring(separator + 2, raw.length - 1).trim(),
        );
      }
    }
    return (_activeBranch.name, 'Mueble');
  }

  String _skuFromName(String name) {
    final base = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    if (base.isEmpty) {
      return 'prod-$suffix';
    }
    return '$base-$suffix';
  }

  String get _catalogSection => 'catalog_${_activeBranch.id}';
  String get _catalogSuppliersSection => 'catalog_suppliers_${_activeBranch.id}';
  String get _catalogLocationsSection => 'catalog_locations_${_activeBranch.id}';
  String get _pricingDefaultsSection => 'pricing_defaults';
}

class _ProductMeta {
  const _ProductMeta({
    required this.locationName,
    required this.locationType,
    required this.barcode,
    required this.imageUrl,
    required this.pricingRules,
    required this.expirationDate,
  });

  final String locationName;
  final String locationType;
  final String barcode;
  final String imageUrl;
  final ProductPricingRules pricingRules;
  final DateTime? expirationDate;
}
