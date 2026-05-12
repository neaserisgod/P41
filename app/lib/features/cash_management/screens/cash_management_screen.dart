import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/session_context.dart';
import '../models/cash_shift.dart';
import '../state/cash_controller.dart';

class CashManagementScreen extends StatelessWidget {
  const CashManagementScreen({
    super.key,
    required this.cashController,
    required this.activeBranch,
    required this.activeUser,
    required this.showBranchName,
    required this.onCashAction,
  });

  final CashController cashController;
  final SessionBranch activeBranch;
  final SessionUser activeUser;
  final bool showBranchName;
  final VoidCallback onCashAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('cash-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: cashController,
        builder: (context, _) {
          final currentShift = cashController.shiftForBranch(activeBranch);
          final cigaretteShift = cashController.cigaretteShiftForBranch(
            activeBranch,
          );
          final history = cashController.historyForBranch(activeBranch.id);

          return LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 1180 || constraints.maxHeight < 760;
              return Padding(
                padding: EdgeInsets.all(stacked ? 16 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CashHeader(
                      branchName: activeBranch.name,
                      userName: activeUser.name,
                      showBranchName: showBranchName,
                      shift: currentShift,
                      separateCigarettes: cashController.separateCigarettes,
                      onSeparateCigarettesChanged:
                          cashController.updateSeparateCigarettes,
                      onCashAction: onCashAction,
                      compact: stacked,
                    ),
                    if (cashController.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        cashController.errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.danger,
                        ),
                      ),
                    ],
                    SizedBox(height: stacked ? 12 : 18),
                    Expanded(
                      child: stacked
                          ? Column(
                              children: [
                                SizedBox(
                                  height: cashController.separateCigarettes
                                      ? 280
                                      : 180,
                                  child: _CurrentCashPanel(
                                    generalShift: currentShift,
                                    cigaretteShift: cigaretteShift,
                                    separateCigarettes:
                                        cashController.separateCigarettes,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _CashHistoryPanel(history: history),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 38,
                                  child: _CurrentCashPanel(
                                    generalShift: currentShift,
                                    cigaretteShift: cigaretteShift,
                                    separateCigarettes:
                                        cashController.separateCigarettes,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 62,
                                  child: _CashHistoryPanel(history: history),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CashHeader extends StatelessWidget {
  const _CashHeader({
    required this.branchName,
    required this.userName,
    required this.showBranchName,
    required this.shift,
    required this.separateCigarettes,
    required this.onSeparateCigarettesChanged,
    required this.onCashAction,
    required this.compact,
  });

  final String branchName;
  final String userName;
  final bool showBranchName;
  final CashShift shift;
  final bool separateCigarettes;
  final ValueChanged<bool> onSeparateCigarettesChanged;
  final VoidCallback onCashAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Caja',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                showBranchName ? '$branchName • $userName' : userName,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: separateCigarettes,
                        onChanged: onSeparateCigarettesChanged,
                      ),
                      Text(
                        'Separar cigarrillos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textStrong,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: onCashAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: shift.isOpen
                          ? palette.warning
                          : palette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      shift.isOpen
                          ? Icons.lock_clock_rounded
                          : Icons.lock_open_rounded,
                    ),
                    label: Text(
                      shift.isOpen ? 'Cerrar caja' : 'Abrir caja',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: palette.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showBranchName ? '$branchName • $userName' : userName,
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: separateCigarettes,
                        onChanged: onSeparateCigarettesChanged,
                      ),
                      Text(
                        'Separar cigarrillos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textStrong,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: onCashAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: shift.isOpen
                          ? palette.warning
                          : palette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      shift.isOpen
                          ? Icons.lock_clock_rounded
                          : Icons.lock_open_rounded,
                    ),
                    label: Text(
                      shift.isOpen ? 'Cerrar caja' : 'Abrir caja',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}

class _CurrentCashPanel extends StatelessWidget {
  const _CurrentCashPanel({
    required this.generalShift,
    required this.cigaretteShift,
    required this.separateCigarettes,
  });

  final CashShift generalShift;
  final CashShift cigaretteShift;
  final bool separateCigarettes;

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
            'Estado actual',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 16),
          _RegisterSummaryCard(
            title: generalShift.registerName,
            shift: generalShift,
            showVirtuals: true,
          ),
          if (separateCigarettes) ...[
            const SizedBox(height: 14),
            _RegisterSummaryCard(
              title: cigaretteShift.registerName,
              shift: cigaretteShift,
              showVirtuals: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _RegisterSummaryCard extends StatelessWidget {
  const _RegisterSummaryCard({
    required this.title,
    required this.shift,
    required this.showVirtuals,
  });

  final String title;
  final CashShift shift;
  final bool showVirtuals;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Estado',
            value: shift.isOpen ? 'Abierta' : 'Cerrada',
          ),
          if (shift.openedBy != null)
            _InfoRow(label: 'Abierta por', value: shift.openedBy!),
          if (shift.openedAtLabel != null)
            _InfoRow(label: 'Hora apertura', value: shift.openedAtLabel!),
          if (shift.openingAmount != null)
            _InfoRow(
              label: 'Monto inicial',
              value: _money(shift.openingAmount!),
            ),
          _InfoRow(label: 'Efectivo', value: _money(shift.cashSalesTotal ?? 0)),
          if (showVirtuals)
            _InfoRow(
              label: 'Virtual',
              value: _money(shift.virtualSalesTotal ?? 0),
            ),
          if (shift.expectedAmount != null)
            _InfoRow(
              label: 'Esperado caja',
              value: _money(shift.expectedAmount!),
            ),
          if (shift.countedAmount != null)
            _InfoRow(label: 'Contado', value: _money(shift.countedAmount!)),
          if (shift.difference != null)
            _InfoRow(
              label: 'Diferencia',
              value: _money(shift.difference!),
              emphasize: true,
              positive: shift.difference! >= 0,
            ),
        ],
      ),
    );
  }
}

class _CashHistoryPanel extends StatelessWidget {
  const _CashHistoryPanel({required this.history});

  final List<CashShift> history;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movimientos recientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'Todavía no hay movimientos.',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: palette.border),
                    itemBuilder: (context, index) {
                      final shift = history[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shift.registerName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textStrong,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${shift.closedAtLabel ?? shift.openedAtLabel ?? 'Sin horario'} • ${shift.id}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              shift.countedAmount != null
                                  ? _money(shift.countedAmount!)
                                  : _money(shift.openingAmount ?? 0),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: palette.textStrong,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: shift.isOpen
                                  ? palette.warning.withValues(alpha: 0.12)
                                  : palette.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              shift.isOpen ? 'Abierta' : 'Cerrada',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: shift.isOpen
                                    ? palette.warning
                                    : palette.success,
                              ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.positive = true,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = emphasize
        ? (positive ? palette.success : palette.danger)
        : palette.textStrong;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  final abs = value.abs();
  final normalized = abs.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < normalized.length; i++) {
    final remaining = normalized.length - i;
    buffer.write(normalized[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  final prefix = value < 0 ? '- \$' : '\$';
  return '$prefix$buffer';
}
