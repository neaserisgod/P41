import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    super.key,
    required this.activeBranchName,
    required this.period,
    required this.onSelectPeriod,
  });

  final String activeBranchName;
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onSelectPeriod;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reportes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeBranchName.isEmpty ? 'Resumen del negocio.' : 'Resumen de $activeBranchName',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final option in ReportPeriod.values)
              _PeriodChip(
                label: _periodLabel(option),
                selected: option == period,
                onTap: () => onSelectPeriod(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : palette.textStrong,
          ),
        ),
      ),
    );
  }
}

String _periodLabel(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.day:
      return 'Día';
    case ReportPeriod.week:
      return 'Semana';
    case ReportPeriod.month:
      return 'Mes';
  }
}
