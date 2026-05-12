class ProductPricingRules {
  const ProductPricingRules({
    required this.markupPercent,
    required this.bonusPercent,
    required this.bonusEnabled,
    required this.vatPercent,
    required this.vatEnabled,
  });

  static const ProductPricingRules defaults = ProductPricingRules(
    markupPercent: 70,
    bonusPercent: 0,
    bonusEnabled: false,
    vatPercent: 21,
    vatEnabled: false,
  );

  final double markupPercent;
  final double bonusPercent;
  final bool bonusEnabled;
  final double vatPercent;
  final bool vatEnabled;

  double get multiplier {
    final markup = markupPercent / 100;
    final bonus = bonusEnabled ? bonusPercent / 100 : 0;
    final vat = vatEnabled ? vatPercent / 100 : 0;
    return 1 + markup + bonus + vat;
  }

  double salePriceFromCost(double cost) => cost * multiplier;

  double costFromSalePrice(double salePrice) {
    if (multiplier <= 0) {
      return salePrice;
    }
    return salePrice / multiplier;
  }

  ProductPricingRules copyWith({
    double? markupPercent,
    double? bonusPercent,
    bool? bonusEnabled,
    double? vatPercent,
    bool? vatEnabled,
  }) {
    return ProductPricingRules(
      markupPercent: markupPercent ?? this.markupPercent,
      bonusPercent: bonusPercent ?? this.bonusPercent,
      bonusEnabled: bonusEnabled ?? this.bonusEnabled,
      vatPercent: vatPercent ?? this.vatPercent,
      vatEnabled: vatEnabled ?? this.vatEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'markup_percent': markupPercent,
      'bonus_percent': bonusPercent,
      'bonus_enabled': bonusEnabled,
      'vat_percent': vatPercent,
      'vat_enabled': vatEnabled,
    };
  }

  factory ProductPricingRules.fromJson(Map<String, dynamic> json) {
    return ProductPricingRules(
      markupPercent: _doubleValue(json['markup_percent'], fallback: defaults.markupPercent),
      bonusPercent: _doubleValue(json['bonus_percent'], fallback: defaults.bonusPercent),
      bonusEnabled: json['bonus_enabled'] as bool? ?? defaults.bonusEnabled,
      vatPercent: _doubleValue(json['vat_percent'], fallback: defaults.vatPercent),
      vatEnabled: json['vat_enabled'] as bool? ?? defaults.vatEnabled,
    );
  }

  static double _doubleValue(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
