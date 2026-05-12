import 'package:flutter/material.dart';

import '../../../app/state/catalog_controller.dart';
import '../../cash_management/state/cash_controller.dart';
import '../../pos/models/sale_models.dart';
import '../../pos/state/sales_controller.dart';
import '../../providers/models/provider_record.dart';
import '../../providers/state/providers_controller.dart';
import '../models/report_models.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    required CatalogController catalogController,
    required ProvidersController providersController,
    required SalesController salesController,
    required CashController cashController,
  })  : _catalogController = catalogController,
        _providersController = providersController,
        _salesController = salesController,
        _cashController = cashController {
    _catalogController.addListener(_handleSourceChanged);
    _providersController.addListener(_handleSourceChanged);
    _salesController.addListener(_handleSourceChanged);
  }

  final CatalogController _catalogController;
  final ProvidersController _providersController;
  final SalesController _salesController;
  final CashController _cashController;
  ReportsSection _selectedSection = ReportsSection.summary;
  ReportPeriod _selectedPeriod = ReportPeriod.week;
  String? _selectedSupplierId;
  String? _selectedTransactionId;

  ReportsSection get selectedSection => _selectedSection;
  ReportPeriod get selectedPeriod => _selectedPeriod;

  SummarySnapshot get summary {
    final transactions = _activeTransactions;
    final receivedOrders = _receivedOrders;
    final income = transactions.fold<double>(0, (sum, tx) => sum + tx.total);
    final investment = receivedOrders.fold<double>(0, (sum, order) => sum + order.total);
    final soldCost = transactions.fold<double>(0, (sum, tx) {
      return sum + tx.items.fold<double>(0, (itemSum, item) => itemSum + (item.cost * item.quantity));
    });
    final grossProfit = transactions.fold<double>(0, (sum, tx) {
      return sum + tx.items.fold<double>(0, (itemSum, item) => itemSum + item.margin);
    });
    final grossProfitPercent = soldCost <= 0 ? 0.0 : (grossProfit / soldCost) * 100;
    final salesCount = transactions.length;
    final averageTicket = salesCount == 0 ? 0.0 : income / salesCount;
    final topProducts = _topProductsFor(transactions);
    final stockValueAtCost = _catalogController.products
        .where((product) => product.isActive)
        .fold<double>(0, (sum, product) => sum + (product.stock * product.cost));
    return SummarySnapshot(
      stockValueAtCost: stockValueAtCost,
      income: income,
      investment: investment,
      soldCost: soldCost,
      grossProfit: grossProfit,
      grossProfitPercent: grossProfitPercent,
      salesCount: salesCount,
      averageTicket: averageTicket,
      trendPoints: _trendPointsFor(transactions),
      topHighlights: topProducts.take(3).toList(),
    );
  }

  List<SupplierSpendReport> get supplierReports {
    final transactions = _activeTransactions;
    final receivedOrders = _receivedOrders;
    final salesBySku = _salesBySku(transactions);
    final ordersByProvider = <String, List<ProviderOrder>>{};
    for (final order in receivedOrders) {
      ordersByProvider.putIfAbsent(order.providerId, () => []).add(order);
    }

    final providers = _providersController.providers;
    final reports = providers.map((provider) {
      final providerProducts = _catalogController.products
          .where((product) => product.supplierId == provider.id)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final providerOrders = List<ProviderOrder>.from(
        ordersByProvider[provider.id] ?? const <ProviderOrder>[],
      )..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
      final totalSpent = providerOrders.fold<double>(0, (sum, order) => sum + order.total);
      final productReports = providerProducts.map((product) {
        final sales = salesBySku[product.sku] ?? const _ProductSalesStats();
        return SupplierProductReport(
          productId: product.id,
          name: product.name,
          category: product.category,
          stock: product.stock,
          unitCost: product.cost,
          stockValueAtCost: product.stock * product.cost,
          unitsSold: sales.unitsSold,
          salesRevenue: sales.revenue,
          grossProfit: sales.margin,
          status: product.status,
        );
      }).toList();
      final unitsSold = productReports.fold<int>(0, (sum, product) => sum + product.unitsSold);
      final salesRevenue = productReports.fold<double>(0, (sum, product) => sum + product.salesRevenue);
      final grossProfit = productReports.fold<double>(0, (sum, product) => sum + product.grossProfit);
      final soldCost = productReports.fold<double>(
        0,
        (sum, product) => sum + (product.unitCost * product.unitsSold),
      );
      return SupplierSpendReport(
        id: provider.id,
        name: provider.name,
        totalSpent: totalSpent,
        orderCount: providerOrders.length,
        productCount: providerProducts.length,
        stockValueAtCost: productReports.fold<double>(0, (sum, product) => sum + product.stockValueAtCost),
        unitsSold: unitsSold,
        salesRevenue: salesRevenue,
        grossProfit: grossProfit,
        grossProfitPercent: soldCost <= 0 ? 0.0 : (grossProfit / soldCost) * 100,
        orders: providerOrders
            .map(
              (order) => SupplierOrderReport(
                id: order.id,
                label: 'Pedido ${order.id}',
                totalCost: order.total,
                productCount: order.items.fold<int>(0, (sum, item) => sum + item.quantity),
                marginGenerated: 0,
              ),
            )
            .toList(),
        products: productReports,
      );
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    _selectedSupplierId = _resolveSelectedId(
      current: _selectedSupplierId,
      available: reports.map((report) => report.id),
    );
    return reports;
  }

  List<TransactionReport> get transactions {
    final reports = _filteredTransactions
        .map(
          (transaction) => TransactionReport(
            id: transaction.id,
            timeLabel: transaction.timeLabel,
            cashier: transaction.cashier,
            paymentMethod: transaction.paymentMethod,
            total: transaction.total,
            itemCount: transaction.itemCount,
            voided: transaction.isVoided,
            voidReason: transaction.voidReason,
          ),
        )
        .toList()
      ..sort((a, b) {
        final left = _salesController.transactions.where((item) => item.id == a.id).firstOrNull?.occurredAt;
        final right = _salesController.transactions.where((item) => item.id == b.id).firstOrNull?.occurredAt;
        return (right ?? DateTime(1970)).compareTo(left ?? DateTime(1970));
      });
    _selectedTransactionId = _resolveSelectedId(
      current: _selectedTransactionId,
      available: reports.map((report) => report.id),
    );
    return reports;
  }

  List<TopProductReport> get topProducts => _topProductsFor(_activeTransactions);

  SupplierSpendReport get selectedSupplier =>
      supplierReports.firstWhere((record) => record.id == _selectedSupplierId);

  TransactionReport get selectedTransaction =>
      transactions.firstWhere((record) => record.id == _selectedTransactionId);

  bool get hasSupplierReports => supplierReports.isNotEmpty;
  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasTopProducts => topProducts.isNotEmpty;

  @override
  void dispose() {
    _catalogController.removeListener(_handleSourceChanged);
    _providersController.removeListener(_handleSourceChanged);
    _salesController.removeListener(_handleSourceChanged);
    super.dispose();
  }

  void selectSection(ReportsSection section) {
    if (_selectedSection == section) {
      return;
    }
    _selectedSection = section;
    notifyListeners();
  }

  void selectPeriod(ReportPeriod period) {
    if (_selectedPeriod == period) {
      return;
    }
    _selectedPeriod = period;
    _selectedSupplierId = null;
    _selectedTransactionId = null;
    notifyListeners();
  }

  void selectSupplier(String supplierId) {
    if (_selectedSupplierId == supplierId) {
      return;
    }
    _selectedSupplierId = supplierId;
    notifyListeners();
  }

  void selectTransaction(String transactionId) {
    if (_selectedTransactionId == transactionId) {
      return;
    }
    _selectedTransactionId = transactionId;
    notifyListeners();
  }

  Future<void> voidSelectedTransaction() async {
    final selectedId = _selectedTransactionId;
    if (selectedId == null) {
      return;
    }
    final transaction = _salesController.transactions.where((item) => item.id == selectedId).firstOrNull;
    if (transaction == null || transaction.isVoided) {
      return;
    }
    final updated = await _salesController.voidTransaction(selectedId);
    if (updated == null) {
      return;
    }
    await _catalogController.restoreTransactionStock(
      items: updated.items
          .map(
            (item) => {
              'sku': item.sku,
              'quantity': item.quantity,
            },
          )
          .toList(),
    );
    await _cashController.reverseSale(
      branchId: updated.branchId,
      transaction: updated,
    );
  }

  List<SaleTransaction> get _filteredTransactions {
    final now = DateTime.now();
    final cutoff = _cutoffFor(now, _selectedPeriod);
    return _salesController.transactions.where((transaction) {
      final occurredAt = transaction.occurredAt;
      if (occurredAt == null) {
        return true;
      }
      return !occurredAt.isBefore(cutoff);
    }).toList();
  }

  List<SaleTransaction> get _activeTransactions =>
      _filteredTransactions.where((transaction) => !transaction.isVoided).toList();

  List<ProviderOrder> get _receivedOrders {
    final now = DateTime.now();
    final cutoff = _cutoffFor(now, _selectedPeriod);
    return _providersController.orders.where((order) {
      if (!order.isReceived) {
        return false;
      }
      final createdAt = order.createdAt;
      if (createdAt == null) {
        return true;
      }
      return !createdAt.isBefore(cutoff);
    }).toList();
  }

  List<TopProductReport> _topProductsFor(List<SaleTransaction> transactions) {
    final revenueBySku = <String, double>{};
    final unitsBySku = <String, int>{};
    final marginBySku = <String, double>{};
    final nameBySku = <String, String>{};
    final totalRevenue = transactions.fold<double>(0, (sum, tx) => sum + tx.total);

    for (final transaction in transactions) {
      for (final item in transaction.items) {
        final sku = item.sku.isEmpty ? item.name : item.sku;
        revenueBySku[sku] = (revenueBySku[sku] ?? 0) + item.revenue;
        unitsBySku[sku] = (unitsBySku[sku] ?? 0) + item.quantity;
        marginBySku[sku] = (marginBySku[sku] ?? 0) + item.margin;
        nameBySku[sku] = item.name;
      }
    }

    final products = revenueBySku.keys
        .map(
          (sku) => TopProductReport(
            id: sku,
            name: nameBySku[sku] ?? sku,
            unitsSold: unitsBySku[sku] ?? 0,
            revenue: revenueBySku[sku] ?? 0,
            margin: marginBySku[sku] ?? 0,
            share: totalRevenue <= 0 ? 0.0 : (((revenueBySku[sku] ?? 0) / totalRevenue) * 100).roundToDouble(),
          ),
        )
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return products.take(10).toList();
  }

  Map<String, _ProductSalesStats> _salesBySku(List<SaleTransaction> transactions) {
    final stats = <String, _ProductSalesStats>{};
    for (final transaction in transactions) {
      for (final item in transaction.items) {
        final current = stats[item.sku] ?? const _ProductSalesStats();
        stats[item.sku] = current.copyWith(
          unitsSold: current.unitsSold + item.quantity,
          revenue: current.revenue + item.revenue,
          margin: current.margin + item.margin,
        );
      }
    }
    return stats;
  }

  List<double> _trendPointsFor(List<SaleTransaction> transactions) {
    final now = DateTime.now();
    late final List<DateTime> markers;
    late final Duration step;
    switch (_selectedPeriod) {
      case ReportPeriod.day:
        step = const Duration(hours: 4);
        markers = List.generate(7, (index) => now.subtract(Duration(hours: (6 - index) * 4)));
      case ReportPeriod.week:
        step = const Duration(days: 1);
        markers = List.generate(7, (index) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index)));
      case ReportPeriod.month:
        step = const Duration(days: 5);
        markers = List.generate(6, (index) => DateTime(now.year, now.month, now.day).subtract(Duration(days: (5 - index) * 5)));
    }

    return markers.map((marker) {
      final end = marker.add(step);
      return transactions.fold<double>(0, (sum, transaction) {
        final occurredAt = transaction.occurredAt;
        if (occurredAt == null) {
          return sum;
        }
        if (occurredAt.isBefore(marker) || !occurredAt.isBefore(end)) {
          return sum;
        }
        return sum + transaction.total;
      });
    }).toList();
  }

  DateTime _cutoffFor(DateTime now, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.day:
        return now.subtract(const Duration(days: 1));
      case ReportPeriod.week:
        return now.subtract(const Duration(days: 7));
      case ReportPeriod.month:
        return now.subtract(const Duration(days: 30));
    }
  }

  String? _resolveSelectedId({
    required String? current,
    required Iterable<String> available,
  }) {
    for (final value in available) {
      if (value == current) {
        return current;
      }
    }
    return available.isEmpty ? null : available.first;
  }

  void _handleSourceChanged() {
    notifyListeners();
  }
}

class _ProductSalesStats {
  const _ProductSalesStats({
    this.unitsSold = 0,
    this.revenue = 0,
    this.margin = 0,
  });

  final int unitsSold;
  final double revenue;
  final double margin;

  _ProductSalesStats copyWith({
    int? unitsSold,
    double? revenue,
    double? margin,
  }) {
    return _ProductSalesStats(
      unitsSold: unitsSold ?? this.unitsSold,
      revenue: revenue ?? this.revenue,
      margin: margin ?? this.margin,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
