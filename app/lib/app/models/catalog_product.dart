import 'product_pricing_rules.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.supplierId,
    required this.supplierName,
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minStock,
    this.pricingRules = ProductPricingRules.defaults,
    this.expirationDate,
    this.imageUrl = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String supplierId;
  final String supplierName;
  final String locationId;
  final String locationName;
  final String locationType;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final ProductPricingRules pricingRules;
  final DateTime? expirationDate;
  final String imageUrl;
  final bool isActive;

  String get status {
    if (stock <= 0) {
      return 'Sin stock';
    }
    if (minStock > 0 && stock <= minStock) {
      return 'Stock bajo';
    }
    return 'Disponible';
  }

  CatalogProduct copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? supplierId,
    String? supplierName,
    String? locationId,
    String? locationName,
    String? locationType,
    double? price,
    double? cost,
    int? stock,
    int? minStock,
    ProductPricingRules? pricingRules,
    DateTime? expirationDate,
    bool clearExpirationDate = false,
    String? imageUrl,
    bool? isActive,
  }) {
    return CatalogProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      locationType: locationType ?? this.locationType,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      pricingRules: pricingRules ?? this.pricingRules,
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
