class ProviderRecord {
  const ProviderRecord({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.category,
    required this.isActive,
    required this.orderDays,
    required this.deliveryDays,
  });

  final String id;
  final String name;
  final String contact;
  final String phone;
  final String email;
  final String category;
  final bool isActive;
  final List<int> orderDays;
  final List<int> deliveryDays;

  ProviderRecord copyWith({
    String? id,
    String? name,
    String? contact,
    String? phone,
    String? email,
    String? category,
    bool? isActive,
    List<int>? orderDays,
    List<int>? deliveryDays,
  }) {
    return ProviderRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      orderDays: orderDays ?? this.orderDays,
      deliveryDays: deliveryDays ?? this.deliveryDays,
    );
  }
}

class ProviderCatalogItem {
  const ProviderCatalogItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.pack,
    required this.lastPrice,
  });

  final String id;
  final String productId;
  final String name;
  final String pack;
  final double lastPrice;
}

class DraftOrderItem {
  const DraftOrderItem({
    required this.item,
    required this.quantity,
  });

  final ProviderCatalogItem item;
  final int quantity;

  double get total => item.lastPrice * quantity;

  DraftOrderItem copyWith({
    ProviderCatalogItem? item,
    int? quantity,
  }) {
    return DraftOrderItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ProviderOrder {
  const ProviderOrder({
    required this.id,
    required this.providerId,
    required this.dateLabel,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.items,
  });

  final String id;
  final String providerId;
  final String dateLabel;
  final DateTime? createdAt;
  final String status;
  final double total;
  final List<DraftOrderItem> items;

  bool get isReceived => status.trim().toLowerCase() == 'recibido';
  bool get isPending => status.trim().toLowerCase() == 'pendiente' || status.trim().toLowerCase() == 'borrador';

  ProviderOrder copyWith({
    String? id,
    String? providerId,
    String? dateLabel,
    DateTime? createdAt,
    String? status,
    double? total,
    List<DraftOrderItem>? items,
  }) {
    return ProviderOrder(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      dateLabel: dateLabel ?? this.dateLabel,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }
}
