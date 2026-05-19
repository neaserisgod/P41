import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/models/catalog_product.dart';
import '../../../app/services/local_store_service.dart';
import '../../../app/models/session_context.dart';
import '../../../app/state/catalog_controller.dart';
import '../../pos/models/sale_models.dart';
import '../models/provider_record.dart';

class ProvidersController extends ChangeNotifier {
  ProvidersController({
    required CatalogController catalogController,
    required SessionBranch initialBranch,
    required String scopeKey,
    LocalStoreService? localStoreService,
  })  : _catalogController = catalogController,
        _activeBranch = initialBranch,
        _scopeKey = scopeKey,
        _localStoreService = localStoreService ?? LocalStoreService() {
    _catalogController.addListener(_handleCatalogChanged);
    unawaited(reload());
  }

  final CatalogController _catalogController;
  final LocalStoreService _localStoreService;
  final List<ProviderOrder> _orders = [];
  final Map<String, List<DraftOrderItem>> _draftItemsByProvider = {};
  final Map<String, List<DraftOrderItem>> _suggestedItemsByProvider = {};
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
  List<DraftOrderItem> get suggestedItems =>
      List.unmodifiable(_suggestedItemsFor(_selectedProviderId));
  int get draftUnits => draftItems.fold(0, (sum, item) => sum + item.quantity);
  double get draftTotal => draftItems.fold(0, (sum, item) => sum + item.total);
  int get suggestedUnits => suggestedItems.fold(0, (sum, item) => sum + item.quantity);
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
    final restored = await _restoreLocalSnapshot();
    _errorMessage = restored ? null : 'Todavía no hay proveedores guardados.';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSession({
    required SessionBranch activeBranch,
    required String scopeKey,
  }) async {
    final branchChanged = _activeBranch.id != activeBranch.id;
    final scopeChanged = _scopeKey != scopeKey;
    _activeBranch = activeBranch;
    _scopeKey = scopeKey;
    if (branchChanged || scopeChanged) {
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
  }

  Future<void> updateProvider(ProviderRecord provider) async {
    _providers = _providers.map((item) => item.id == provider.id ? provider : item).toList();
    await _catalogController.upsertSupplierReference(
      supplierId: provider.id,
      supplierName: provider.name,
    );
    await _saveLocalSnapshot();
    _errorMessage = 'Proveedor actualizado.';
    notifyListeners();
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

  Future<void> absorbSuggestedItems() async {
    final providerId = _selectedProviderId;
    if (providerId.isEmpty) {
      return;
    }
    final suggestions = _suggestedItemsFor(providerId);
    if (suggestions.isEmpty) {
      return;
    }
    final draft = _draftItemsFor(providerId);
    for (final suggestion in suggestions) {
      final index = draft.indexWhere((entry) => entry.item.id == suggestion.item.id);
      if (index == -1) {
        draft.add(suggestion);
      } else {
        draft[index] = draft[index].copyWith(
          quantity: draft[index].quantity + suggestion.quantity,
        );
      }
    }
    suggestions.clear();
    await _saveLocalSnapshot();
    _errorMessage = 'Sugerencias pasadas al pedido.';
    notifyListeners();
  }

  Future<void> clearSuggestedItems() async {
    final suggestions = _suggestedItemsFor(_selectedProviderId);
    if (suggestions.isEmpty) {
      return;
    }
    suggestions.clear();
    await _saveLocalSnapshot();
    _errorMessage = 'Sugerencias descartadas.';
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
      final suggestions = _suggestedItemsFor(supplierId);
      final index = suggestions.indexWhere((entry) => entry.item.id == providerItem.id);
      if (index == -1) {
        suggestions.add(DraftOrderItem(item: providerItem, quantity: item.quantity));
      } else {
        suggestions[index] = suggestions[index].copyWith(
          quantity: suggestions[index].quantity + item.quantity,
        );
      }
      changed = true;
    }
    if (!changed) {
      return;
    }
    await _saveLocalSnapshot();
    _errorMessage = 'Venta absorbida como sugerencia de reposición.';
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
    await _localStoreService.writeSection(
      _scopeKey,
      _providerSuggestionsSection,
      _suggestedItemsByProvider.map(
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
      await _restoreSuggestedItems();
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
    await _restoreSuggestedItems();
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

  String _skuForProductId(String productId) {
    for (final product in _catalogController.products) {
      if (product.id == productId) {
        return product.sku;
      }
    }
    return productId;
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
  String get _providerSuggestionsSection => 'provider_suggestions_${_activeBranch.id}';

  List<DraftOrderItem> _draftItemsFor(String providerId) {
    return _draftItemsByProvider.putIfAbsent(providerId, () => <DraftOrderItem>[]);
  }

  List<DraftOrderItem> _suggestedItemsFor(String providerId) {
    return _suggestedItemsByProvider.putIfAbsent(providerId, () => <DraftOrderItem>[]);
  }

  Future<void> _restoreSuggestedItems() async {
    final suggestionsJson = await _localStoreService.readSection(
      _scopeKey,
      _providerSuggestionsSection,
    );
    _suggestedItemsByProvider
      ..clear()
      ..addAll(
        suggestionsJson is Map<String, dynamic>
            ? suggestionsJson.map(
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
