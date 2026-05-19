import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/widgets/desktop_viewport.dart';
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
    final initialAmount = widget.shift.isOpen ? '' : '0';
    _amountController = TextEditingController(text: initialAmount);
    final initialCigarettesAmount = widget.cigaretteShift.isOpen ? '' : '0';
    _cigarettesAmountController = TextEditingController(
      text: initialCigarettesAmount,
    );
    _amountController.addListener(_handleInputChanged);
    _cigarettesAmountController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_handleInputChanged);
    _cigarettesAmountController.removeListener(_handleInputChanged);
    _amountController.dispose();
    _cigarettesAmountController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isOpen = widget.shift.isOpen;
    final title = isOpen ? 'Cerrar caja' : 'Abrir caja';
    final buttonLabel = isOpen ? 'Cerrar' : 'Abrir';
    final helper = isOpen
        ? 'Primero mirá el esperado. Después cargá lo que contaste realmente en cada caja.'
        : 'Escribí con cuánto empezás.';
    final generalExpected =
        widget.shift.expectedAmount ?? widget.shift.openingAmount ?? 0;
    final cigarettesExpected =
        widget.cigaretteShift.expectedAmount ??
        widget.cigaretteShift.openingAmount ??
        0;
    final generalCounted = double.tryParse(_amountController.text.trim());
    final cigarettesCounted = double.tryParse(
      _cigarettesAmountController.text.trim(),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.viewport;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
              child: Container(
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
                    if (widget.separateCigarettes) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.accentSoft.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          isOpen
                              ? 'Esta sucursal opera con caja separada para cigarrillos. Revisá y cerrá cada caja por separado.'
                              : 'Esta sucursal opera con caja separada para cigarrillos. Tenés que abrir ambas cajas.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.textStrong,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: viewport.sectionGap),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: 'Usuario', value: widget.activeUserName),
                            const SizedBox(height: 6),
                            _InfoRow(label: 'Sucursal', value: widget.activeBranchName),
                            if (isOpen && widget.shift.openedAtLabel != null) ...[
                              const SizedBox(height: 6),
                              _InfoRow(label: 'Abierta desde', value: widget.shift.openedAtLabel!),
                            ],
                            if (isOpen) ...[
                              const SizedBox(height: 14),
                              _CashCloseSection(
                                title: widget.shift.registerName,
                                expectedAmount: generalExpected,
                                countedAmount: generalCounted,
                                inputController: _amountController,
                                inputLabel: 'Contado real en caja',
                                cashSalesTotal: widget.shift.cashSalesTotal ?? 0,
                                virtualSalesTotal:
                                    widget.shift.virtualSalesTotal ?? 0,
                              ),
                              if (widget.separateCigarettes) ...[
                                const SizedBox(height: 12),
                                _CashCloseSection(
                                  title: widget.cigaretteShift.registerName,
                                  expectedAmount: cigarettesExpected,
                                  countedAmount: cigarettesCounted,
                                  inputController:
                                      _cigarettesAmountController,
                                  inputLabel:
                                      'Contado real caja cigarrillos',
                                  cashSalesTotal:
                                      widget.cigaretteShift.cashSalesTotal ?? 0,
                                  virtualSalesTotal:
                                      widget.cigaretteShift.virtualSalesTotal ?? 0,
                                ),
                              ],
                            ] else ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Monto inicial',
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
                                    labelText: 'Monto inicial cigarrillos',
                                    filled: true,
                                    fillColor: palette.surfaceMuted,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: palette.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: palette.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: viewport.sectionGap),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 184,
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
                        SizedBox(
                          width: 184,
                          child: FilledButton(
                            onPressed: () {
                              final amount =
                                  double.tryParse(_amountController.text.trim()) ?? 0;
                              final cigarettesAmount = widget.separateCigarettes
                                  ? (double.tryParse(
                                          _cigarettesAmountController.text.trim()) ??
                                      0)
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
            ),
          );
        },
      ),
    );
  }
}

class _CashCloseSection extends StatelessWidget {
  const _CashCloseSection({
    required this.title,
    required this.expectedAmount,
    required this.countedAmount,
    required this.inputController,
    required this.inputLabel,
    required this.cashSalesTotal,
    required this.virtualSalesTotal,
  });

  final String title;
  final double expectedAmount;
  final double? countedAmount;
  final TextEditingController inputController;
  final String inputLabel;
  final double cashSalesTotal;
  final double virtualSalesTotal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final difference = countedAmount == null ? null : countedAmount! - expectedAmount;
    final hasDifference = difference != null && difference != 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.accentSoft.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esperado: ${_money(expectedAmount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                'Efectivo ${_money(cashSalesTotal)}',
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
              Text(
                'Virtual ${_money(virtualSalesTotal)}',
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: inputController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: inputLabel,
              hintText: 'Ingresá lo contado realmente',
              filled: true,
              fillColor: Colors.white,
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
          if (countedAmount != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Diferencia',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                Text(
                  _signedMoney(difference!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: hasDifference
                        ? (difference >= 0 ? palette.success : palette.danger)
                        : palette.textStrong,
                  ),
                ),
              ],
            ),
          ],
        ],
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

String _signedMoney(double value) {
  if (value == 0) {
    return _money(0);
  }
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_money(value.abs())}';
}
