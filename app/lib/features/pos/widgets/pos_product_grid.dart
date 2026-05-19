import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/catalog_product.dart';
import '../../../app/widgets/product_image.dart';

class PosProductGrid extends StatelessWidget {
  const PosProductGrid({
    super.key,
    required this.products,
    required this.onSelectProduct,
  });

  final List<CatalogProduct> products;
  final ValueChanged<CatalogProduct> onSelectProduct;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1460
            ? 7
            : constraints.maxWidth > 1260
            ? 6
            : constraints.maxWidth > 1040
            ? 5
            : constraints.maxWidth > 820
            ? 4
            : constraints.maxWidth > 620
            ? 3
            : 2;
        final aspectRatio = constraints.maxWidth > 1460
            ? 0.77
            : constraints.maxWidth > 1040
            ? 0.78
            : 0.82;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return RepaintBoundary(
              child: ProductCard(
                product: product,
                title: product.name,
                category: product.category,
                price: _money(product.price),
                status: product.status,
                onTap: () => onSelectProduct(product),
              ),
            );
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.title,
    required this.category,
    required this.price,
    required this.status,
    required this.onTap,
  });

  final CatalogProduct product;
  final String title;
  final String category;
  final String price;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color badgeColor;

    switch (status) {
      case 'Sin stock':
        badgeColor = palette.danger;
      case 'Stock bajo':
        badgeColor = palette.warning;
      default:
        badgeColor = palette.success;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: product.stock > 0 ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImagePanel(
                product: product,
                badgeColor: badgeColor,
                status: status,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w800,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                          height: 1.12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 8.6,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                          color: palette.textStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImagePanel extends StatelessWidget {
  const _ProductImagePanel({
    required this.product,
    required this.badgeColor,
    required this.status,
  });

  final CatalogProduct product;
  final Color badgeColor;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasImage = product.imageUrl.trim().isNotEmpty;
    final imageHeight = hasImage ? 132.0 : 116.0;

    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.surfaceMuted, Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, hasImage ? 6 : 10),
              child: hasImage
                  ? ProductImage(
                      source: product.imageUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.low,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return _ProductImageFallback(color: palette.warning);
                      },
                    )
                  : _ProductImageFallback(color: palette.warning),
            ),
          ),
          if (status != 'Disponible')
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.inventory_2_rounded, size: 20, color: color),
      ),
    );
  }
}

String _money(double value) {
  final normalized = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < normalized.length; i++) {
    final remaining = normalized.length - i;
    buffer.write(normalized[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '\$$buffer';
}
