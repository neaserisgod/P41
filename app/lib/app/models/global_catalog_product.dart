class GlobalCatalogProduct {
  const GlobalCatalogProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.suggestedPrice,
    required this.unit,
  });

  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String description;
  final String imageUrl;
  final double? suggestedPrice;
  final String unit;

  factory GlobalCatalogProduct.fromJson(Map<String, dynamic> json) {
    return GlobalCatalogProduct(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Producto',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      suggestedPrice: (json['suggested_price'] as num?)?.toDouble(),
      unit: json['unit']?.toString() ?? 'unit',
    );
  }
}
