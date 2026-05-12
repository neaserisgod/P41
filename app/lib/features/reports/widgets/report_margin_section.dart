import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportMarginSection extends StatelessWidget {
  const ReportMarginSection({
    super.key,
    required this.reports,
    required this.selectedSupplierId,
    required this.onSelectSupplier,
  });

  final List<SupplierSpendReport> reports;
  final String selectedSupplierId;
  final ValueChanged<String> onSelectSupplier;

  @override
  Widget build(BuildContext context) {
    final selected = reports.firstWhere((report) => report.id == selectedSupplierId);

    return Row(
      children: [
        Expanded(
          flex: 34,
          child: _SupplierList(
            reports: reports,
            selectedSupplierId: selectedSupplierId,
            onSelectSupplier: onSelectSupplier,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 66,
          child: _SupplierDetail(report: selected),
        ),
      ],
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({
    required this.reports,
    required this.selectedSupplierId,
    required this.onSelectSupplier,
  });

  final List<SupplierSpendReport> reports;
  final String selectedSupplierId;
  final ValueChanged<String> onSelectSupplier;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: reports.length,
        separatorBuilder: (context, index) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final report = reports[index];
          final selected = report.id == selectedSupplierId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectSupplier(report.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? palette.accentSoft.withValues(alpha: 0.72) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.orderCount} recibidos • ${_money(report.totalSpent)} invertidos',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${report.productCount} productos • ${_money(report.stockValueAtCost)} en stock',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ganancia ${_money(report.grossProfit)} • ${report.grossProfitPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupplierDetail extends StatelessWidget {
  const _SupplierDetail({
    required this.report,
  });

  final SupplierSpendReport report;

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
            report.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(label: 'Invertido', value: _money(report.totalSpent)),
              _MetricChip(label: 'Stock a costo', value: _money(report.stockValueAtCost)),
              _MetricChip(label: 'Ventas', value: _money(report.salesRevenue)),
              _MetricChip(label: 'Ganancia', value: _money(report.grossProfit)),
              _MetricChip(label: 'Ganancia %', value: '${report.grossProfitPercent.toStringAsFixed(1)}%'),
              _MetricChip(label: 'Unidades vendidas', value: '${report.unitsSold}'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeaderCell(flex: 28, label: 'Producto'),
              _HeaderCell(flex: 14, label: 'Categoría'),
              _HeaderCell(flex: 8, label: 'Stock', alignEnd: true),
              _HeaderCell(flex: 14, label: 'Costo', alignEnd: true),
              _HeaderCell(flex: 16, label: 'Stock \$', alignEnd: true),
              _HeaderCell(flex: 8, label: 'Vend.', alignEnd: true),
              _HeaderCell(flex: 12, label: 'Ingresos', alignEnd: true),
              _HeaderCell(flex: 12, label: 'Ganancia', alignEnd: true),
              _HeaderCell(flex: 12, label: 'Estado', alignEnd: true),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: report.products.length,
              separatorBuilder: (context, index) => Divider(color: palette.border),
              itemBuilder: (context, index) {
                final product = report.products[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 28,
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textStrong,
                        ),
                      ),
                    ),
                    _ValueCell(flex: 14, value: product.category),
                    _ValueCell(flex: 8, value: '${product.stock}', alignEnd: true),
                    _ValueCell(flex: 14, value: _money(product.unitCost), alignEnd: true),
                    _ValueCell(flex: 16, value: _money(product.stockValueAtCost), alignEnd: true),
                    _ValueCell(flex: 8, value: '${product.unitsSold}', alignEnd: true),
                    _ValueCell(flex: 12, value: _money(product.salesRevenue), alignEnd: true),
                    _ValueCell(flex: 12, value: _money(product.grossProfit), alignEnd: true, success: true),
                    _ValueCell(flex: 12, value: product.status, alignEnd: true),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 164,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
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
    this.alignEnd = false,
    this.success = false,
  });

  final int flex;
  final String value;
  final bool alignEnd;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11.5,
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
