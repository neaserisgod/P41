import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/inventory_location.dart';

class ProviderProductsGrid extends StatelessWidget {
  const ProviderProductsGrid({
    super.key,
    required this.provider,
  });

  final InventoryProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: provider.products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = provider.products[index];
        return _ProductRow(product: product);
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final InventoryProduct product;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = switch (product.status) {
      'Sin stock' => palette.danger,
      'Stock bajo' => palette.warning,
      _ => palette.success,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.textStrong,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${product.stock} u.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.accent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              product.price,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textStrong,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.status,
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
