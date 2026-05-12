import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/cash_shift.dart';

class CashStatusCard extends StatelessWidget {
  const CashStatusCard({
    super.key,
    required this.shift,
    required this.onPrimaryAction,
  });

  final CashShift shift;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOpen = shift.isOpen;
    final accent = isOpen ? palette.success : palette.warning;
    final title = isOpen ? 'Caja abierta' : 'Caja cerrada';
    final subtitle = isOpen
        ? '${shift.openedBy ?? 'Sin usuario'} • ${shift.openedAtLabel ?? 'Sin horario'}'
        : 'Necesitas abrir caja para operar';
    final actionLabel = isOpen ? 'Cerrar caja' : 'Abrir caja';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                    fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOpen && shift.openingAmount != null) ...[
            const SizedBox(height: 8),
            Text('Inicio ${_money(shift.openingAmount!)}',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textMuted)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPrimaryAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textStrong,
                side: BorderSide(color: palette.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
