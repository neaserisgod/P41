import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/models/catalog_product.dart';
import '../../../app/models/session_context.dart';
import '../../../app/services/local_store_service.dart';
import '../../cash_management/models/cash_shift.dart';
import '../models/sale_models.dart';

class SalesController extends ChangeNotifier {
  SalesController({
    required SessionBranch initialBranch,
    required String scopeKey,
    LocalStoreService? localStoreService,
  })  : _activeBranch = initialBranch,
        _scopeKey = scopeKey,
        _localStoreService = localStoreService ?? LocalStoreService() {
    unawaited(reload());
  }

  final LocalStoreService _localStoreService;
  final List<SaleCartItem> _cartItems = [];
  final List<SaleTransaction> _transactions = [];
  String _query = '';
  String _selectedCategory = 'Todos';
  SessionBranch _activeBranch;
  String _scopeKey;
  String? _errorMessage;
  bool _isCheckingOut = false;

  List<SaleCartItem> get cartItems => List.unmodifiable(_cartItems);
  List<SaleTransaction> get transactions => List.unmodifiable(_transactions.reversed);
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  bool get isCheckingOut => _isCheckingOut;

  int get cartUnits => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get discount => subtotal > 20000 ? 500 : 0;
  double get total => subtotal - discount;

  List<String> categoriesFor(List<CatalogProduct> products) {
    final categories = products.map((product) => product.category).toSet().toList()..sort();
    return ['Todos', ...categories];
  }

  List<CatalogProduct> visibleProducts(List<CatalogProduct> products) {
    final normalizedQuery = _query.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesQuery = normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.sku.toLowerCase().contains(normalizedQuery);
      return product.isActive && matchesCategory && matchesQuery;
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }
    _selectedCategory = category;
    notifyListeners();
  }

  void addProduct(CatalogProduct product) {
    if (product.stock <= 0) {
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _cartItems.add(SaleCartItem(product: product, quantity: 1));
    } else if (_cartItems[index].quantity < product.stock) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 1,
      );
    }
    notifyListeners();
  }

  void increaseItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }
    final item = _cartItems[index];
    if (item.quantity >= item.product.stock) {
      return;
    }
    _cartItems[index] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  void decreaseItem(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) {
      return;
    }
    final item = _cartItems[index];
    if (item.quantity == 1) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> reload() async {
    final restored = await _restoreLocalSnapshot();
    _errorMessage = restored ? null : 'Todavía no hay ventas guardadas.';
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
      clearCart();
      await reload();
    }
  }

  Future<SaleTransaction?> checkout({
    required String paymentMethod,
    required SessionUser cashier,
    required SessionBranch branch,
    required CashShift shift,
  }) async {
    if (_cartItems.isEmpty || _isCheckingOut) {
      return null;
    }
    _errorMessage = null;
    _isCheckingOut = true;
    notifyListeners();
    try {
      final transaction = _buildLocalTransaction(
        paymentMethod: paymentMethod,
        cashier: cashier,
        branch: branch,
        shift: shift,
      );
      _transactions.add(transaction);
      _cartItems.clear();
      await _saveLocalSnapshot();
      _errorMessage = 'Venta guardada.';
      notifyListeners();
      return transaction;
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  String _paymentLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'card':
      case 'tarjeta':
        return 'Tarjeta';
      case 'transfer':
      case 'transferencia':
        return 'Transferencia';
      case 'qr':
        return 'QR';
      default:
        return 'Efectivo';
    }
  }

  SaleTransaction _buildLocalTransaction({
    required String paymentMethod,
    required SessionUser cashier,
    required SessionBranch branch,
    required CashShift shift,
  }) {
    final now = DateTime.now();
    return SaleTransaction(
      id: 'local-sale-${now.millisecondsSinceEpoch}',
      timeLabel:
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      occurredAt: now,
      shiftId: shift.id,
      cashier: cashier.name,
      branchId: branch.id,
      branchName: branch.name,
      paymentMethod: _paymentLabel(paymentMethod),
      status: 'completed',
      total: total,
      itemCount: _cartItems.fold(0, (sum, item) => sum + item.quantity),
      items: _cartItems
          .map(
            (item) => SaleProductBreakdown(
              sku: item.product.sku,
              name: item.product.name,
              category: item.product.category,
              quantity: item.quantity,
              revenue: item.total,
              cost: item.product.cost,
            ),
          )
          .toList(),
    );
  }

  Future<SaleTransaction?> voidTransaction(
    String transactionId, {
    String reason = 'Anulada desde reportes',
  }) async {
    final index = _transactions.indexWhere((transaction) => transaction.id == transactionId);
    if (index == -1) {
      return null;
    }
    final current = _transactions[index];
    if (current.isVoided) {
      return current;
    }
    final updated = current.copyWith(
      status: 'cancelled',
      voidReason: reason,
      voidedAt: DateTime.now(),
    );
    _transactions[index] = updated;
    await _saveLocalSnapshot();
    notifyListeners();
    return updated;
  }

  Future<void> _saveLocalSnapshot() async {
    await _localStoreService.saveSalesSnapshot(
      scopeKey: _scopeKey,
      branchId: _activeBranch.id,
      transactions: _transactions.map(_transactionToJson).toList(),
    );
  }

  Future<bool> _restoreLocalSnapshot() async {
    final raw = await _localStoreService.readSalesSnapshot(
          scopeKey: _scopeKey,
          branchId: _activeBranch.id,
        ) ??
        await _localStoreService.readSection(_scopeKey, _salesTransactionsSection);
    if (raw is! List<dynamic>) {
      return false;
    }
    _transactions
      ..clear()
      ..addAll(raw.whereType<Map<String, dynamic>>().map(_transactionFromJson));
    return true;
  }

  Map<String, dynamic> _transactionToJson(SaleTransaction transaction) {
    return {
      'id': transaction.id,
      'time_label': transaction.timeLabel,
      'occurred_at': transaction.occurredAt?.toIso8601String(),
      'shift_id': transaction.shiftId,
      'cashier': transaction.cashier,
      'branch_id': transaction.branchId,
      'branch_name': transaction.branchName,
      'payment_method': transaction.paymentMethod,
      'status': transaction.status,
      'total': transaction.total,
      'item_count': transaction.itemCount,
      'void_reason': transaction.voidReason,
      'voided_at': transaction.voidedAt?.toIso8601String(),
      'items': transaction.items
          .map(
            (item) => {
              'sku': item.sku,
              'name': item.name,
              'category': item.category,
              'quantity': item.quantity,
              'revenue': item.revenue,
              'cost': item.cost,
            },
          )
          .toList(),
    };
  }

  SaleTransaction _transactionFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => SaleProductBreakdown(
            sku: item['sku']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Producto',
            category: item['category']?.toString() ?? '',
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
            revenue: (item['revenue'] as num?)?.toDouble() ?? 0,
            cost: (item['cost'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
    return SaleTransaction(
      id: json['id']?.toString() ?? '',
      timeLabel: json['time_label']?.toString() ?? 'Sin horario',
      occurredAt: json['occurred_at'] == null ? null : DateTime.tryParse(json['occurred_at'].toString()),
      shiftId: json['shift_id']?.toString() ?? '',
      cashier: json['cashier']?.toString() ?? 'Caja',
      branchId: json['branch_id']?.toString() ?? _activeBranch.id,
      branchName: json['branch_name']?.toString() ?? _activeBranch.name,
      paymentMethod: json['payment_method']?.toString() ?? 'Efectivo',
      status: json['status']?.toString() ?? 'completed',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? items.fold(0, (sum, item) => sum + item.quantity),
      items: items,
      voidReason: json['void_reason']?.toString(),
      voidedAt: json['voided_at'] == null ? null : DateTime.tryParse(json['voided_at'].toString()),
    );
  }
  String get _salesTransactionsSection => 'sales_transactions_${_activeBranch.id}';
}
