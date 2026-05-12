import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportTopProductsSection extends StatelessWidget {
  const ReportTopProductsSection({
    super.key,
    required this.products,
  });

  final List<TopProductReport> products;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unidades, ingresos y margen',
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderCell(flex: 34, label: 'Producto'),
              _HeaderCell(flex: 14, label: 'Unidades', alignEnd: true),
              _HeaderCell(flex: 18, label: 'Ingresos', alignEnd: true),
              _HeaderCell(flex: 18, label: 'Margen', alignEnd: true),
              _HeaderCell(flex: 16, label: 'Participación', alignEnd: true),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => Divider(color: palette.border),
              itemBuilder: (context, index) {
                final product = products[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 34,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: palette.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              color: palette.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.textStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ValueCell(flex: 14, value: '${product.unitsSold}'),
                    _ValueCell(flex: 18, value: _money(product.revenue)),
                    _ValueCell(flex: 18, value: _money(product.margin), success: true),
                    _ValueCell(flex: 16, value: '${product.share}%'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.flex,
    required this.label,
    this.alignEnd = false,
  });

  final int flex;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.flex,
    required this.value,
    this.success = false,
  });

  final int flex;
  final String value;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: success ? palette.success : palette.textStrong,
        ),
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
