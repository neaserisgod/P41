import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/models/catalog_product.dart';
import '../../../app/services/local_store_service.dart';
import '../../../app/models/session_context.dart';
import '../../../app/services/providers_api_service.dart';
import '../../../app/state/catalog_controller.dart';
import '../../pos/models/sale_models.dart';
import '../models/provider_record.dart';

class ProvidersController extends ChangeNotifier {
  ProvidersController({
    required CatalogController catalogController,
    required String accessToken,
    required SessionBranch initialBranch,
    required String scopeKey,
    ProvidersApiService? apiService,
    LocalStoreService? localStoreService,
  })  : _catalogController = catalogController,
        _accessToken = accessToken,
        _activeBranch = initialBranch,
        _scopeKey = scopeKey,
        _apiService = apiService ?? ProvidersApiService(),
        _localStoreService = localStoreService ?? LocalStoreService() {
    _catalogController.addListener(_handleCatalogChanged);
    unawaited(reload());
  }

  final CatalogController _catalogController;
  final ProvidersApiService _apiService;
  final LocalStoreService _localStoreService;
  final List<ProviderOrder> _orders = [];
  final Map<String, List<DraftOrderItem>> _draftItemsByProvider = {};
  final String _deviceId = 'p41-desktop';
  String _accessToken;
  SessionBranch _activeBranch;
  String _scopeKey;
  List<ProviderRecord> _providers = const [];
  String _selectedProviderId = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<ProviderRecord> get providers => List.unmodifiable(_providers);
  ProviderRecord? get selectedProviderOrNull {
    if (_providers.isEmpty) {
      return null;
    }
    for (final provider in _providers) {
      if (provider.id == _selectedProviderId) {
        return provider;
      }
    }
    return _providers.first;
  }

  ProviderRecord get selectedProvider => selectedProviderOrNull!;
  List<ProviderCatalogItem> get selectedCatalog => catalogForProvider(_selectedProviderId);
  List<ProviderOrder> get selectedOrders =>
      _orders.where((order) => order.providerId == _selectedProviderId).toList().reversed.toList();
  List<DraftOrderItem> get draftItems => List.unmodifiable(_draftItemsFor(_selectedProviderId));
  int get draftUnits => draftItems.fold(0, (sum, item) => sum + item.quantity);
  double get draftTotal => draftItems.fold(0, (sum, item) => sum + item.total);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProviderOrder> get orders => List.unmodifiable(_orders);

  @override
  void dispose() {
    _catalogController.removeListener(_handleCatalogChanged);
    super.dispose();
  }

  Future<void> reload() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (await _localStoreService.isOfflineOnly()) {
      final restored = await _restoreLocalSnapshot();
      _errorMessage = restored ? null : 'Todavía no hay proveedores guardados.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final branchId = int.tryParse(_activeBranch.id);
      final supplierPayload = await _apiService.listSuppliers(
        token: _accessToken,
        branchId: branchId,
      );
      final orderPayload = await _apiService.listOrders(
        token: _accessToken,
        branchId: branchId,
      );
      _providers = supplierPayload.map(_providerFromApi).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _syncCatalogSupplierReferences();
      _orders
        ..clear()
        ..addAll(orderPayload.map(_orderFromApi));
      await _saveLocalSnapshot();
      if (_providers.isNotEmpty) {
        final exists = _providers.any((provider) => provider.id == _selectedProviderId);
        _selectedProviderId = exists ? _selectedProviderId : _providers.first.id;
      } else {
        _selectedProviderId = '';
      }
    } on ProvidersApiException catch (error) {
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

  void selectProvider(String providerId) {
    if (_selectedProviderId == providerId) {
      return;
    }
    _selectedProviderId = providerId;
    notifyListeners();
  }

  Future<void> createProvider({
    required String name,
    required String contact,
    required String phone,
    required String email,
    required String category,
    required List<int> orderDays,
    required List<int> deliveryDays,
    bool isActive = true,
  }) async {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final branchId = int.tryParse(_activeBranch.id);
    if (await _localStoreService.isOfflineOnly()) {
      final localProvider = ProviderRecord(
        id: 'local-supplier-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        contact: contact,
        phone: phone,
        email: email,
        category: category,
        isActive: isActive,
        orderDays: orderDays,
        deliveryDays: deliveryDays,
      );
      _providers = [..._providers, localProvider]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _catalogController.upsertSupplierReference(
        supplierId: localProvider.id,
        supplierName: localProvider.name,
      );
      _selectedProviderId = localProvider.id;
      await _saveLocalSnapshot();
      _errorMessage = 'Proveedor guardado.';
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.createSupplier(
        token: _accessToken,
        body: {
          'id': '$slug-${DateTime.now().millisecondsSinceEpoch}',
          'name': name,
          'contact_name': contact,
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'email': email.trim().isEmpty ? null : email.trim(),
          'notes': _notesFor(
            category: category,
            isActive: isActive,
            orderDays: orderDays,
          ),
          'delivery_days': _serializeDays(deliveryDays),
          'branch_id': branchId,
          'device_id': _deviceId,
        },
      );
      final provider = _providerFromApi(response);
      _providers = [..._providers, provider]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _catalogController.upsertSupplierReference(
        supplierId: provider.id,
        supplierName: provider.name,
      );
      _selectedProviderId = provider.id;
      await _saveLocalSnapshot();
      notifyListeners();
    } on ProvidersApiException catch (error) {
      final localProvider = ProviderRecord(
        id: 'local-supplier-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        contact: contact,
        phone: phone,
        email: email,
        category: category,
        isActive: isActive,
        orderDays: orderDays,
        deliveryDays: deliveryDays,
      );
      _providers = [..._providers, localProvider]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _catalogController.upsertSupplierReference(
        supplierId: localProvider.id,
        supplierName: localProvider.name,
      );
      _selectedProviderId = localProvider.id;
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Proveedor guardado.'
          : error.message;
      notifyListeners();
    }
  }

  Future<void> updateProvider(ProviderRecord provider) async {
    if (await _localStoreService.isOfflineOnly()) {
      _providers = _providers.map((item) => item.id == provider.id ? provider : item).toList();
      await _catalogController.upsertSupplierReference(
        supplierId: provider.id,
        supplierName: provider.name,
      );
      await _saveLocalSnapshot();
      _errorMessage = 'Proveedor actualizado.';
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.updateSupplier(
        token: _accessToken,
        supplierId: provider.id,
        body: {
          'id': provider.id,
          'name': provider.name,
          'contact_name': provider.contact,
          'phone': provider.phone.trim().isEmpty ? null : provider.phone.trim(),
          'email': provider.email.trim().isEmpty ? null : provider.email.trim(),
          'notes': _notesFor(
            category: provider.category,
            isActive: provider.isActive,
            orderDays: provider.orderDays,
          ),
          'delivery_days': _serializeDays(provider.deliveryDays),
          'branch_id': int.tryParse(_activeBranch.id),
          'device_id': _deviceId,
        },
      );
      final updated = _providerFromApi(response);
      _providers = _providers.map((item) => item.id == provider.id ? updated : item).toList();
      await _catalogController.upsertSupplierReference(
        supplierId: updated.id,
        supplierName: updated.name,
      );
      await _saveLocalSnapshot();
      notifyListeners();
    } on ProvidersApiException catch (error) {
      _providers = _providers.map((item) => item.id == provider.id ? provider : item).toList();
      await _catalogController.upsertSupplierReference(
        supplierId: provider.id,
        supplierName: provider.name,
      );
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Proveedor actualizado.'
          : error.message;
      notifyListeners();
    }
  }

  List<ProviderCatalogItem> catalogForProvider(String providerId) {
    final products = _catalogController.products.where((product) => product.supplierId == providerId).toList();
    return products
        .map(
          (product) => ProviderCatalogItem(
            id: '$providerId-${product.id}',
            productId: product.id,
            name: product.name,
            pack: 'Unidad',
            lastPrice: product.cost,
          ),
        )
        .toList();
  }

  void addToDraft(ProviderCatalogItem item) {
    final providerId = _selectedProviderId;
    if (providerId.isEmpty) {
      return;
    }
    final draft = _draftItemsFor(providerId);
    final index = draft.indexWhere((entry) => entry.item.id == item.id);
    if (index == -1) {
      draft.add(DraftOrderItem(item: item, quantity: 1));
    } else {
      draft[index] = draft[index].copyWith(quantity: draft[index].quantity + 1);
    }
    _persistDrafts();
    notifyListeners();
  }

  void increaseDraftItem(String itemId) {
    final draft = _draftItemsFor(_selectedProviderId);
    final index = draft.indexWhere((entry) => entry.item.id == itemId);
    if (index == -1) {
      return;
    }
    draft[index] = draft[index].copyWith(quantity: draft[index].quantity + 1);
    _persistDrafts();
    notifyListeners();
  }

  void decreaseDraftItem(String itemId) {
    final draft = _draftItemsFor(_selectedProviderId);
    final index = draft.indexWhere((entry) => entry.item.id == itemId);
    if (index == -1) {
      return;
    }
    final current = draft[index];
    if (current.quantity <= 1) {
      draft.removeAt(index);
    } else {
      draft[index] = current.copyWith(quantity: current.quantity - 1);
    }
    _persistDrafts();
    notifyListeners();
  }

  Future<void> createOrder() async {
    final provider = selectedProviderOrNull;
    final draft = _draftItemsFor(_selectedProviderId);
    if (provider == null || draft.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final localOrderId = 'order-${provider.id}-${now.millisecondsSinceEpoch}';
    if (await _localStoreService.isOfflineOnly()) {
      final localOrder = ProviderOrder(
        id: localOrderId,
        providerId: provider.id,
        dateLabel: _dateLabel(now.toIso8601String()),
        createdAt: now,
        status: 'Pendiente',
        total: draftTotal,
        items: List<DraftOrderItem>.from(draft),
      );
      _upsertOrder(localOrder);
      draft.clear();
      await _saveLocalSnapshot();
      _errorMessage = 'Pedido emitido.';
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.createOrder(
        token: _accessToken,
        body: {
          'local_id': localOrderId,
          'device_id': _deviceId,
          'supplier_id': provider.id,
          'supplier_name': provider.name,
          'total_amount': draftTotal,
          'status': 'pending',
          'branch_id': int.tryParse(_activeBranch.id),
          'items': draft.map(_orderItemPayload).toList(),
        },
      );
      _upsertOrder(_orderFromApi(response));
      draft.clear();
      await _saveLocalSnapshot();
      _errorMessage = 'Pedido emitido.';
      notifyListeners();
    } on ProvidersApiException catch (error) {
      final localOrder = ProviderOrder(
        id: localOrderId,
        providerId: provider.id,
        dateLabel: _dateLabel(now.toIso8601String()),
        createdAt: now,
        status: 'Pendiente',
        total: draftTotal,
        items: List<DraftOrderItem>.from(draft),
      );
      _upsertOrder(localOrder);
      draft.clear();
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Pedido emitido.'
          : error.message;
      notifyListeners();
    }
  }

  Future<void> absorbSaleItems(List<SaleProductBreakdown> items) async {
    var changed = false;
    for (final item in items) {
      CatalogProduct? product;
      for (final entry in _catalogController.products) {
        if (entry.sku == item.sku) {
          product = entry;
          break;
        }
      }
      if (product == null) {
        continue;
      }
      final supplierId = product.supplierId.trim();
      if (supplierId.isEmpty) {
        continue;
      }
      final providerItem = ProviderCatalogItem(
        id: '$supplierId-${product.id}',
        productId: product.id,
        name: product.name,
        pack: 'Unidad',
        lastPrice: product.cost,
      );
      final draft = _draftItemsFor(supplierId);
      final index = draft.indexWhere((entry) => entry.item.id == providerItem.id);
      if (index == -1) {
        draft.add(DraftOrderItem(item: providerItem, quantity: item.quantity));
      } else {
        draft[index] = draft[index].copyWith(quantity: draft[index].quantity + item.quantity);
      }
      changed = true;
    }
    if (!changed) {
      return;
    }
    await _saveLocalSnapshot();
    notifyListeners();
  }

  String draftMessageForSelectedProvider() {
    final provider = selectedProviderOrNull;
    final draft = _draftItemsFor(_selectedProviderId);
    if (provider == null || draft.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    buffer.writeln('Pedido para ${provider.name}');
    if (provider.contact.isNotEmpty) {
      buffer.writeln('Contacto: ${provider.contact}');
    }
    buffer.writeln('');
    for (final item in draft) {
      buffer.writeln('- ${item.item.name}: ${item.quantity}');
    }
    buffer.writeln('');
    buffer.writeln('Total estimado: ${_money(draft.fold(0.0, (sum, item) => sum + item.total))}');
    return buffer.toString().trim();
  }

  Future<void> receiveOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1 || _orders[index].isReceived) {
      return;
    }
    if (await _localStoreService.isOfflineOnly()) {
      _orders[index] = _orders[index].copyWith(status: 'Recibido');
      await _catalogController.applyOrderStockIncrease(
        items: _orders[index].items
            .map((item) => {
                  'sku': _skuForProductId(item.item.productId),
                  'quantity': item.quantity,
                })
            .toList(),
      );
      await _saveLocalSnapshot();
      _errorMessage = 'Recepción guardada.';
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.updateOrderStatus(
        token: _accessToken,
        orderId: orderId,
        status: 'received',
      );
      _orders[index] = _orderFromApi(response);
      await _catalogController.applyOrderStockIncrease(
        items: _orders[index].items
            .map((item) => {
                  'sku': _skuForProductId(item.item.productId),
                  'quantity': item.quantity,
                })
            .toList(),
      );
      await _catalogController.reload();
      await _saveLocalSnapshot();
      notifyListeners();
    } on ProvidersApiException catch (error) {
      _orders[index] = _orders[index].copyWith(status: 'Recibido');
      await _catalogController.applyOrderStockIncrease(
        items: _orders[index].items
            .map((item) => {
                  'sku': _skuForProductId(item.item.productId),
                  'quantity': item.quantity,
                })
            .toList(),
      );
      await _saveLocalSnapshot();
      _errorMessage = _isConnectivityError(error)
          ? 'Recepción guardada.'
          : error.message;
      notifyListeners();
    }
  }

  int productCountFor(String providerId) {
    return _catalogController.products.where((product) => product.supplierId == providerId).length;
  }

  double balanceFor(String providerId) {
    return _orders
        .where((order) => order.providerId == providerId && order.isReceived)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  String lastDeliveryFor(String providerId) {
    for (final order in _orders.reversed) {
      if (order.providerId == providerId && order.status == 'Recibido') {
        return order.dateLabel;
      }
    }
    return 'Sin entregas';
  }

  void _handleCatalogChanged() {
    notifyListeners();
  }

  Future<void> _syncCatalogSupplierReferences() async {
    await _catalogController.syncSupplierReferences({
      for (final provider in _providers) provider.id: provider.name,
    });
  }

  Future<void> _saveLocalSnapshot() async {
    await _localStoreService.saveProvidersSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
      providers: _providers.map(_providerToJson).toList(),
      orders: _orders.map(_orderToJson).toList(),
      draftsByProvider: _draftItemsByProvider.map(
        (providerId, items) => MapEntry(
          providerId,
          items.map(_draftItemToJson).toList(),
        ),
      ),
    );
  }

  Future<bool> _restoreLocalSnapshot() async {
    final tableSnapshot = await _localStoreService.readProvidersSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
    );
    if (tableSnapshot != null) {
      final providersJson = tableSnapshot['providers'];
      final ordersJson = tableSnapshot['orders'];
      final draftsJson = tableSnapshot['drafts'];
      _providers = (providersJson is List<dynamic> ? providersJson : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_providerFromJson)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _syncCatalogSupplierReferences();
      _orders
        ..clear()
        ..addAll(
          (ordersJson is List<dynamic> ? ordersJson : const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_orderFromJson),
        );
      _draftItemsByProvider
        ..clear()
        ..addAll(
          draftsJson is Map<String, dynamic>
              ? draftsJson.map(
                  (key, value) => MapEntry(
                    key,
                    (value as List<dynamic>? ?? const [])
                        .whereType<Map<String, dynamic>>()
                        .map(_draftItemFromJson)
                        .toList(),
                  ),
                )
              : const <String, List<DraftOrderItem>>{},
        );
      if (_providers.isNotEmpty) {
        final exists = _providers.any((provider) => provider.id == _selectedProviderId);
        _selectedProviderId = exists ? _selectedProviderId : _providers.first.id;
      }
      return true;
    }

    final providersJson = await _localStoreService.readSection(_scopeKey, _providersSection);
    final ordersJson = await _localStoreService.readSection(_scopeKey, _providerOrdersSection);
    final draftsJson = await _localStoreService.readSection(_scopeKey, _providerDraftsSection);
    if (providersJson is! List<dynamic>) {
      return false;
    }
    _providers = providersJson.whereType<Map<String, dynamic>>().map(_providerFromJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _syncCatalogSupplierReferences();
    _orders
      ..clear()
      ..addAll(
        ordersJson is List<dynamic>
            ? ordersJson.whereType<Map<String, dynamic>>().map(_orderFromJson)
            : const <ProviderOrder>[],
      );
    _draftItemsByProvider
      ..clear()
      ..addAll(
        draftsJson is Map<String, dynamic>
            ? draftsJson.map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>? ?? const [])
                      .whereType<Map<String, dynamic>>()
                      .map(_draftItemFromJson)
                      .toList(),
                ),
              )
            : const <String, List<DraftOrderItem>>{},
      );
    if (_providers.isNotEmpty) {
      final exists = _providers.any((provider) => provider.id == _selectedProviderId);
      _selectedProviderId = exists ? _selectedProviderId : _providers.first.id;
    }
    return true;
  }

  Map<String, dynamic> _providerToJson(ProviderRecord provider) {
    return {
      'id': provider.id,
      'name': provider.name,
      'contact': provider.contact,
      'phone': provider.phone,
      'email': provider.email,
      'category': provider.category,
      'is_active': provider.isActive,
      'order_days': provider.orderDays,
      'delivery_days': provider.deliveryDays,
    };
  }

  ProviderRecord _providerFromJson(Map<String, dynamic> json) {
    return ProviderRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Proveedor',
      contact: json['contact']?.toString() ?? 'Contacto a definir',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      isActive: (json['is_active'] as bool?) ?? true,
      orderDays: (json['order_days'] as List<dynamic>? ?? const []).whereType<num>().map((e) => e.toInt()).toList(),
      deliveryDays: (json['delivery_days'] as List<dynamic>? ?? const []).whereType<num>().map((e) => e.toInt()).toList(),
    );
  }

  Map<String, dynamic> _orderToJson(ProviderOrder order) {
    return {
      'id': order.id,
      'provider_id': order.providerId,
      'date_label': order.dateLabel,
      'created_at': order.createdAt?.toIso8601String(),
      'status': order.status,
      'total': order.total,
      'items': order.items
          .map(
            (item) => {
              'product_id': item.item.productId,
              'name': item.item.name,
              'price': item.item.lastPrice,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };
  }

  ProviderOrder _orderFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => DraftOrderItem(
            item: ProviderCatalogItem(
              id: '${json['provider_id']}-${item['product_id']}',
              productId: item['product_id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Producto',
              pack: 'Unidad',
              lastPrice: (item['price'] as num?)?.toDouble() ?? 0,
            ),
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    return ProviderOrder(
      id: json['id']?.toString() ?? '',
      providerId: json['provider_id']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? 'Sin fecha',
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'Pendiente',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> _draftItemToJson(DraftOrderItem item) {
    return {
      'item_id': item.item.id,
      'product_id': item.item.productId,
      'name': item.item.name,
      'pack': item.item.pack,
      'price': item.item.lastPrice,
      'quantity': item.quantity,
    };
  }

  DraftOrderItem _draftItemFromJson(Map<String, dynamic> json) {
    return DraftOrderItem(
      item: ProviderCatalogItem(
        id: json['item_id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Producto',
        pack: json['pack']?.toString() ?? 'Unidad',
        lastPrice: (json['price'] as num?)?.toDouble() ?? 0,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  bool _isConnectivityError(ProvidersApiException error) {
    return error.statusCode == null &&
        (error.message.contains('No se pudo conectar') || error.message.contains('Tiempo de espera'));
  }

  ProviderRecord _providerFromApi(Map<String, dynamic> json) {
    final notes = json['notes']?.toString() ?? '';
    return ProviderRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Proveedor',
      contact: json['contact_name']?.toString() ?? 'Contacto a definir',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      category: _categoryFromNotes(notes),
      isActive: _isActiveFromNotes(notes),
      orderDays: _orderDaysFromNotes(notes),
      deliveryDays: _deserializeDays(json['delivery_days']?.toString()),
    );
  }

  ProviderOrder _orderFromApi(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => DraftOrderItem(
            item: ProviderCatalogItem(
              id: '${json['supplier_id']}-${item['product_sku']}',
              productId: _productIdForSku(item['product_sku']?.toString() ?? ''),
              name: item['product_name']?.toString() ?? 'Producto',
              pack: 'Unidad',
              lastPrice: (item['price'] as num?)?.toDouble() ?? 0,
            ),
            quantity: ((item['quantity'] as num?)?.round() ?? 0),
          ),
        )
        .toList();
    return ProviderOrder(
      id: json['id'].toString(),
      providerId: json['supplier_id']?.toString() ?? '',
      dateLabel: _dateLabel(json['created_at']?.toString()),
      createdAt: _parseDate(json['created_at']?.toString()),
      status: _statusLabel(json['status']?.toString() ?? 'pending'),
      total: (json['total_amount'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> _orderItemPayload(DraftOrderItem item) {
    final sku = _skuForProductId(item.item.productId);
    return {
      'product_sku': sku,
      'product_name': item.item.name,
      'quantity': item.quantity,
      'price': item.item.lastPrice,
      'total': item.total,
    };
  }

  String _skuForProductId(String productId) {
    for (final product in _catalogController.products) {
      if (product.id == productId) {
        return product.sku;
      }
    }
    return productId;
  }

  String _productIdForSku(String sku) {
    for (final product in _catalogController.products) {
      if (product.sku == sku) {
        return product.id;
      }
    }
    return sku;
  }

  String _notesFor({
    required String category,
    required bool isActive,
    required List<int> orderDays,
  }) {
    return [
      'Categoria: $category',
      'Estado: ${isActive ? 'activo' : 'inactivo'}',
      'DiasPedido: ${_serializeDays(orderDays)}',
    ].join('\n');
  }

  String _categoryFromNotes(String notes) {
    for (final line in notes.split('\n')) {
      if (line.toLowerCase().startsWith('categoria:')) {
        return line.split(':').skip(1).join(':').trim();
      }
    }
    return 'General';
  }

  bool _isActiveFromNotes(String notes) {
    for (final line in notes.split('\n')) {
      if (line.toLowerCase().startsWith('estado:')) {
        return !line.toLowerCase().contains('inactivo');
      }
    }
    return true;
  }

  List<int> _orderDaysFromNotes(String notes) {
    for (final line in notes.split('\n')) {
      if (line.toLowerCase().startsWith('diaspedido:')) {
        return _deserializeDays(line.split(':').skip(1).join(':').trim());
      }
    }
    return const [];
  }

  String _serializeDays(List<int> days) {
    if (days.isEmpty) {
      return '';
    }
    final normalized = [...days]..sort();
    return normalized.join(',');
  }

  List<int> _deserializeDays(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    return raw
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((value) => value >= 1 && value <= 7)
        .toSet()
        .toList()
      ..sort();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'received':
        return 'Recibido';
      case 'pending':
        return 'Pendiente';
      case 'paid':
        return 'Pagado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status.toLowerCase() == 'borrador' ? 'Borrador' : 'Pendiente';
    }
  }

  String _dateLabel(String? value) {
    final date = _parseDate(value);
    if (date == null) {
      return 'Sin fecha';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String? value) {
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  String get _providersSection => 'providers_${_activeBranch.id}';
  String get _providerOrdersSection => 'provider_orders_${_activeBranch.id}';
  String get _providerDraftsSection => 'provider_drafts_${_activeBranch.id}';

  List<DraftOrderItem> _draftItemsFor(String providerId) {
    return _draftItemsByProvider.putIfAbsent(providerId, () => <DraftOrderItem>[]);
  }

  void _persistDrafts() {
    unawaited(_saveLocalSnapshot());
  }

  void _upsertOrder(ProviderOrder order) {
    final index = _orders.indexWhere((entry) => entry.id == order.id);
    if (index == -1) {
      _orders.add(order);
    } else {
      _orders[index] = order;
    }
  }

  String _money(double value) => '\$${value.toStringAsFixed(0)}';
}
