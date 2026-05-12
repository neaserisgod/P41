import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportSummarySection extends StatelessWidget {
  const ReportSummarySection({
    super.key,
    required this.snapshot,
  });

  final SummarySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(label: 'Stock valorizado', value: _money(snapshot.stockValueAtCost)),
            _KpiCard(label: 'Ingresos', value: _money(snapshot.income)),
            _KpiCard(label: 'Invertido', value: _money(snapshot.investment)),
            _KpiCard(label: 'Costo vendido', value: _money(snapshot.soldCost)),
            _KpiCard(label: 'Ganancia bruta', value: _money(snapshot.grossProfit)),
            _KpiCard(label: 'Ganancia %', value: '${snapshot.grossProfitPercent.toStringAsFixed(1)}%'),
            _KpiCard(label: 'Ventas', value: '${snapshot.salesCount}'),
            _KpiCard(label: 'Ticket promedio', value: _money(snapshot.averageTicket)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 58,
                child: _TrendPanel(points: snapshot.trendPoints),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 42,
                child: _HighlightsPanel(products: snapshot.topHighlights),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 154,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({
    required this.points,
  });

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final maxPoint = points.isEmpty
        ? 1.0
        : points.reduce((a, b) => a > b ? a : b) <= 0
            ? 1.0
            : points.reduce((a, b) => a > b ? a : b);

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
            'Tendencia de ingresos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vista rápida del período',
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildBars(palette, maxPoint),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBars(AppPalette palette, double maxPoint) {
    final widgets = <Widget>[];

    for (var i = 0; i < points.length; i++) {
      widgets.add(
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 24,
                    height: (points[i] / maxPoint) * 180,
                    decoration: BoxDecoration(
                      color: i == points.length - 1 ? palette.warning : palette.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      );

      if (i != points.length - 1) {
        widgets.add(const SizedBox(width: 8));
      }
    }

    return widgets;
  }
}

class _HighlightsPanel extends StatelessWidget {
  const _HighlightsPanel({
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
            'Top rápido',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lo que más mueve el período',
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => Divider(color: palette.border),
              itemBuilder: (context, index) {
                final product = products[index];
                return Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.textStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.unitsSold} unidades • ${product.share}% participación',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(product.revenue),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.textStrong,
                      ),
                    ),
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
