import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/report_models.dart';

class ReportTransactionsSection extends StatelessWidget {
  const ReportTransactionsSection({
    super.key,
    required this.transactions,
    required this.selectedTransactionId,
    required this.onSelectTransaction,
    required this.onVoidSelected,
  });

  final List<TransactionReport> transactions;
  final String selectedTransactionId;
  final ValueChanged<String> onSelectTransaction;
  final VoidCallback onVoidSelected;

  @override
  Widget build(BuildContext context) {
    final selected = transactions.firstWhere((transaction) => transaction.id == selectedTransactionId);

    return Row(
      children: [
        Expanded(
          flex: 58,
          child: _TransactionList(
            transactions: transactions,
            selectedTransactionId: selectedTransactionId,
            onSelectTransaction: onSelectTransaction,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 42,
          child: _TransactionDetail(
            transaction: selected,
            onVoidSelected: onVoidSelected,
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.transactions,
    required this.selectedTransactionId,
    required this.onSelectTransaction,
  });

  final List<TransactionReport> transactions;
  final String selectedTransactionId;
  final ValueChanged<String> onSelectTransaction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final selected = transaction.id == selectedTransactionId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectTransaction(transaction.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? palette.accentSoft.withValues(alpha: 0.72) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        transaction.timeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        transaction.id,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textStrong,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text(
                        transaction.paymentMethod,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: transaction.voided
                            ? palette.danger.withValues(alpha: 0.12)
                            : palette.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.voided ? 'Anulada' : 'Completada',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: transaction.voided ? palette.danger : palette.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 88,
                      child: Text(
                        _money(transaction.total),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                        ),
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

class _TransactionDetail extends StatelessWidget {
  const _TransactionDetail({
    required this.transaction,
    required this.onVoidSelected,
  });

  final TransactionReport transaction;
  final VoidCallback onVoidSelected;

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
            'Detalle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'ID', value: transaction.id),
          _DetailRow(label: 'Momento', value: transaction.timeLabel),
          _DetailRow(label: 'Cajero', value: transaction.cashier),
          _DetailRow(label: 'Pago', value: transaction.paymentMethod),
          _DetailRow(label: 'Items', value: '${transaction.itemCount}'),
          _DetailRow(label: 'Total', value: _money(transaction.total)),
          _DetailRow(
            label: 'Estado',
            value: transaction.voided ? 'Anulada' : 'Completada',
          ),
          if (transaction.voidReason != null)
            _DetailRow(label: 'Motivo', value: transaction.voidReason!),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: transaction.voided ? null : onVoidSelected,
              style: FilledButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Anular venta',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
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
                color: palette.textStrong,
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
