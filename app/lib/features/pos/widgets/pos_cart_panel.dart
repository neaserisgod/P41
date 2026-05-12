import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/sale_models.dart';

class PosCartPanel extends StatelessWidget {
  const PosCartPanel({
    super.key,
    required this.enabled,
    required this.isProcessing,
    required this.items,
    required this.cartUnits,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.onIncreaseItem,
    required this.onDecreaseItem,
    required this.onCheckout,
  });

  final bool enabled;
  final bool isProcessing;
  final List<SaleCartItem> items;
  final int cartUnits;
  final double subtotal;
  final double discount;
  final double total;
  final ValueChanged<String> onIncreaseItem;
  final ValueChanged<String> onDecreaseItem;
  final Future<void> Function(String) onCheckout;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 420 || constraints.maxWidth < 340;
        final buttonWidth = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Opacity(
          opacity: enabled ? 1 : 0.68,
          child: Container(
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venta',
                  style: TextStyle(
                    color: palette.textStrong,
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$cartUnits ítems',
                  style: TextStyle(
                    color: palette.textMuted,
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'No agregaste productos.',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: compact ? 8 : 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return CartRow(
                              item: item,
                              onIncrease: () => onIncreaseItem(item.product.id),
                              onDecrease: () => onDecreaseItem(item.product.id),
                            );
                          },
                        ),
                ),
                Divider(color: palette.border),
                SizedBox(height: compact ? 8 : 12),
                TotalLine(label: 'Subtotal', value: _money(subtotal)),
                const SizedBox(height: 8),
                TotalLine(
                  label: 'Descuento',
                  value: discount > 0 ? '- ${_money(discount)}' : '\$0',
                ),
                const SizedBox(height: 8),
                TotalLine(label: 'Total', value: _money(total), emphasized: true),
                SizedBox(height: compact ? 14 : 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: GhostAction(
                        label: 'Cobrar efectivo',
                        enabled: enabled && items.isNotEmpty && !isProcessing,
                        onPressed: () async => onCheckout('Efectivo'),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: GhostAction(
                        label: 'Cobrar transferencia',
                        enabled: enabled && items.isNotEmpty && !isProcessing,
                        onPressed: () async => onCheckout('Transferencia'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: GhostAction(
                        label: 'Cobrar tarjeta',
                        enabled: enabled && items.isNotEmpty && !isProcessing,
                        onPressed: () async => onCheckout('Tarjeta'),
                      ),
                    ),
                  ],
                ),
                if (isProcessing) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class CartRow extends StatelessWidget {
  const CartRow({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
  });

  final SaleCartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.product.name,
              style: TextStyle(
                color: palette.textStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          Text(
            'x${item.quantity}',
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            _money(item.total),
            style: TextStyle(
              color: palette.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TotalLine extends StatelessWidget {
  const TotalLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      color: palette.textStrong,
        fontSize: emphasized ? 24 : 14,
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
    );

    return Row(
      children: [
        Text(label, style: style.copyWith(color: palette.textMuted)),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

class GhostAction extends StatelessWidget {
  const GhostAction({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textStrong,
        side: BorderSide(color: enabled ? palette.accent : palette.border),
        backgroundColor: enabled ? palette.accentSoft : palette.surfaceMuted,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(label),
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
