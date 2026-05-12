import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportsSectionList extends StatelessWidget {
  const ReportsSectionList({
    super.key,
    required this.selectedSection,
    required this.onSelect,
  });

  final ReportsSection selectedSection;
  final ValueChanged<ReportsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = <({ReportsSection section, String title, IconData icon})>[
      (
        section: ReportsSection.summary,
        title: 'Resumen',
        icon: Icons.dashboard_rounded,
      ),
      (
        section: ReportsSection.purchasesMargin,
        title: 'Proveedores',
        icon: Icons.request_quote_rounded,
      ),
      (
        section: ReportsSection.transactions,
        title: 'Ventas',
        icon: Icons.receipt_long_rounded,
      ),
      (
        section: ReportsSection.topProducts,
        title: 'Top productos',
        icon: Icons.local_fire_department_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.section == selectedSection;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(item.section),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? palette.accentSoft.withValues(alpha: 0.72) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 17,
                      color: selected ? palette.accent : palette.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: palette.textStrong,
                            ),
                          ),
                        ],
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
