import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../cash_management/models/cash_shift.dart';

class PosHeader extends StatelessWidget {
  const PosHeader({
    super.key,
    required this.shift,
    required this.activeUserName,
  });

  final CashShift shift;
  final String activeUserName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        shift.isOpen
            ? '${shift.registerName} • $activeUserName'
            : '${shift.registerName} • Caja cerrada',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: palette.textMuted,
        ),
      ),
    );
  }
}
