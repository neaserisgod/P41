import '../../../app/models/catalog_product.dart';

class SaleCartItem {
  const SaleCartItem({
    required this.product,
    required this.quantity,
  });

  final CatalogProduct product;
  final int quantity;

  double get total => product.price * quantity;

  SaleCartItem copyWith({
    CatalogProduct? product,
    int? quantity,
  }) {
    return SaleCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class SaleProductBreakdown {
  const SaleProductBreakdown({
    required this.sku,
    required this.name,
    required this.category,
    required this.quantity,
    required this.revenue,
    required this.cost,
  });

  final String sku;
  final String name;
  final String category;
  final int quantity;
  final double revenue;
  final double cost;

  double get margin => revenue - (cost * quantity);
}

class SaleTransaction {
  const SaleTransaction({
    required this.id,
    required this.timeLabel,
    required this.occurredAt,
    required this.shiftId,
    required this.cashier,
    required this.branchId,
    required this.branchName,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.items,
    this.voidReason,
    this.voidedAt,
  });

  final String id;
  final String timeLabel;
  final DateTime? occurredAt;
  final String shiftId;
  final String cashier;
  final String branchId;
  final String branchName;
  final String paymentMethod;
  final String status;
  final double total;
  final int itemCount;
  final List<SaleProductBreakdown> items;
  final String? voidReason;
  final DateTime? voidedAt;

  bool get isVoided => status.trim().toLowerCase() == 'cancelled';

  SaleTransaction copyWith({
    String? id,
    String? timeLabel,
    DateTime? occurredAt,
    String? shiftId,
    String? cashier,
    String? branchId,
    String? branchName,
    String? paymentMethod,
    String? status,
    double? total,
    int? itemCount,
    List<SaleProductBreakdown>? items,
    String? voidReason,
    DateTime? voidedAt,
    bool clearVoidReason = false,
    bool clearVoidedAt = false,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      timeLabel: timeLabel ?? this.timeLabel,
      occurredAt: occurredAt ?? this.occurredAt,
      shiftId: shiftId ?? this.shiftId,
      cashier: cashier ?? this.cashier,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
      voidReason: clearVoidReason ? null : (voidReason ?? this.voidReason),
      voidedAt: clearVoidedAt ? null : (voidedAt ?? this.voidedAt),
    );
  }
}
