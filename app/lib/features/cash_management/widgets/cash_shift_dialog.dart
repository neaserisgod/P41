import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/cash_shift.dart';

class CashShiftDialog extends StatefulWidget {
  const CashShiftDialog({
    super.key,
    required this.shift,
    required this.separateCigarettes,
    required this.cigaretteShift,
    required this.activeUserName,
    required this.activeBranchName,
    required this.onCancel,
    required this.onConfirmOpen,
    required this.onConfirmClose,
  });

  final CashShift shift;
  final bool separateCigarettes;
  final CashShift cigaretteShift;
  final String activeUserName;
  final String activeBranchName;
  final VoidCallback onCancel;
  final ValueChanged<CashRegisterAmounts> onConfirmOpen;
  final ValueChanged<CashRegisterAmounts> onConfirmClose;

  @override
  State<CashShiftDialog> createState() => _CashShiftDialogState();
}

class _CashShiftDialogState extends State<CashShiftDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _cigarettesAmountController;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.shift.isOpen
        ? (widget.shift.expectedAmount ?? widget.shift.openingAmount ?? 0)
        : 0;
    _amountController = TextEditingController(text: initialAmount.toStringAsFixed(0));
    final initialCigarettesAmount = widget.cigaretteShift.isOpen
        ? (widget.cigaretteShift.expectedAmount ?? widget.cigaretteShift.openingAmount ?? 0)
        : 0;
    _cigarettesAmountController = TextEditingController(text: initialCigarettesAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cigarettesAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOpen = widget.shift.isOpen;
    final title = isOpen ? 'Cerrar caja' : 'Abrir caja';
    final buttonLabel = isOpen ? 'Cerrar' : 'Abrir';
    final helper = isOpen
        ? 'Escribí cuánto hay en caja.'
        : 'Escribí con cuánto empezás.';

    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              style: TextStyle(
                fontSize: 13,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            _InfoRow(label: 'Usuario', value: widget.activeUserName),
            const SizedBox(height: 6),
            _InfoRow(label: 'Sucursal', value: widget.activeBranchName),
            const SizedBox(height: 6),
            _InfoRow(label: 'Caja', value: widget.shift.registerName),
            if (widget.separateCigarettes) ...[
              const SizedBox(height: 6),
              _InfoRow(label: 'Caja 2', value: widget.cigaretteShift.registerName),
            ],
            if (isOpen && widget.shift.openedAtLabel != null) ...[
              const SizedBox(height: 6),
              _InfoRow(label: 'Abierta desde', value: widget.shift.openedAtLabel!),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isOpen ? 'Monto contado' : 'Monto inicial',
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            if (widget.separateCigarettes) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cigarettesAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isOpen ? 'Monto contado cigarrillos' : 'Monto inicial cigarrillos',
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.border),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textStrong,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                      final cigarettesAmount = widget.separateCigarettes
                          ? (double.tryParse(_cigarettesAmountController.text.trim()) ?? 0)
                          : 0.0;
                      final payload = CashRegisterAmounts(
                        general: amount,
                        cigarettes: cigarettesAmount,
                      );
                      if (isOpen) {
                        widget.onConfirmClose(payload);
                      } else {
                        widget.onConfirmOpen(payload);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textStrong,
            ),
          ),
        ),
      ],
    );
  }
}
