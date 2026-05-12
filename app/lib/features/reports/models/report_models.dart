enum ReportPeriod { day, week, month }

enum ReportsSection { summary, purchasesMargin, transactions, topProducts }

class SummarySnapshot {
  const SummarySnapshot({
    required this.stockValueAtCost,
    required this.income,
    required this.investment,
    required this.soldCost,
    required this.grossProfit,
    required this.grossProfitPercent,
    required this.salesCount,
    required this.averageTicket,
    required this.trendPoints,
    required this.topHighlights,
  });

  final double stockValueAtCost;
  final double income;
  final double investment;
  final double soldCost;
  final double grossProfit;
  final double grossProfitPercent;
  final int salesCount;
  final double averageTicket;
  final List<double> trendPoints;
  final List<TopProductReport> topHighlights;
}

class SupplierOrderReport {
  const SupplierOrderReport({
    required this.id,
    required this.label,
    required this.totalCost,
    required this.productCount,
    required this.marginGenerated,
  });

  final String id;
  final String label;
  final double totalCost;
  final int productCount;
  final double marginGenerated;
}

class SupplierSpendReport {
  const SupplierSpendReport({
    required this.id,
    required this.name,
    required this.totalSpent,
    required this.orderCount,
    required this.productCount,
    required this.stockValueAtCost,
    required this.unitsSold,
    required this.salesRevenue,
    required this.grossProfit,
    required this.grossProfitPercent,
    required this.orders,
    required this.products,
  });

  final String id;
  final String name;
  final double totalSpent;
  final int orderCount;
  final int productCount;
  final double stockValueAtCost;
  final int unitsSold;
  final double salesRevenue;
  final double grossProfit;
  final double grossProfitPercent;
  final List<SupplierOrderReport> orders;
  final List<SupplierProductReport> products;
}

class SupplierProductReport {
  const SupplierProductReport({
    required this.productId,
    required this.name,
    required this.category,
    required this.stock,
    required this.unitCost,
    required this.stockValueAtCost,
    required this.unitsSold,
    required this.salesRevenue,
    required this.grossProfit,
    required this.status,
  });

  final String productId;
  final String name;
  final String category;
  final int stock;
  final double unitCost;
  final double stockValueAtCost;
  final int unitsSold;
  final double salesRevenue;
  final double grossProfit;
  final String status;
}

class TransactionReport {
  const TransactionReport({
    required this.id,
    required this.timeLabel,
    required this.cashier,
    required this.paymentMethod,
    required this.total,
    required this.itemCount,
    this.voided = false,
    this.voidReason,
  });

  final String id;
  final String timeLabel;
  final String cashier;
  final String paymentMethod;
  final double total;
  final int itemCount;
  final bool voided;
  final String? voidReason;

  TransactionReport copyWith({
    String? id,
    String? timeLabel,
    String? cashier,
    String? paymentMethod,
    double? total,
    int? itemCount,
    bool? voided,
    String? voidReason,
  }) {
    return TransactionReport(
      id: id ?? this.id,
      timeLabel: timeLabel ?? this.timeLabel,
      cashier: cashier ?? this.cashier,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      voided: voided ?? this.voided,
      voidReason: voidReason ?? this.voidReason,
    );
  }
}

class TopProductReport {
  const TopProductReport({
    required this.id,
    required this.name,
    required this.unitsSold,
    required this.revenue,
    required this.margin,
    required this.share,
  });

  final String id;
  final String name;
  final int unitsSold;
  final double revenue;
  final double margin;
  final double share;
}
