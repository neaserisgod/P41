import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/provider_record.dart';

enum ProviderDetailSection { summary, orders, compose }

class ProviderDetailPanel extends StatelessWidget {
  const ProviderDetailPanel({
    super.key,
    required this.record,
    required this.section,
    required this.onSelectSection,
    required this.productCount,
    required this.balance,
    required this.lastDelivery,
    required this.catalog,
    required this.orders,
    required this.draftItems,
    required this.draftUnits,
    required this.draftTotal,
    required this.onAddToDraft,
    required this.onIncreaseDraftItem,
    required this.onDecreaseDraftItem,
    required this.onCreateOrder,
    required this.onCopyDraft,
    required this.onReceiveOrder,
    required this.onEditProvider,
  });

  final ProviderRecord record;
  final ProviderDetailSection section;
  final ValueChanged<ProviderDetailSection> onSelectSection;
  final int productCount;
  final double balance;
  final String lastDelivery;
  final List<ProviderCatalogItem> catalog;
  final List<ProviderOrder> orders;
  final List<DraftOrderItem> draftItems;
  final int draftUnits;
  final double draftTotal;
  final ValueChanged<ProviderCatalogItem> onAddToDraft;
  final ValueChanged<String> onIncreaseDraftItem;
  final ValueChanged<String> onDecreaseDraftItem;
  final Future<void> Function() onCreateOrder;
  final Future<void> Function() onCopyDraft;
  final Future<void> Function(String) onReceiveOrder;
  final VoidCallback onEditProvider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProviderTopBar(
            record: record,
            section: section,
            onSelectSection: onSelectSection,
            onEditProvider: onEditProvider,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: switch (section) {
              ProviderDetailSection.summary => _SummarySection(
                  record: record,
                  productCount: productCount,
                  balance: balance,
                  lastDelivery: lastDelivery,
                  orderCount: orders.length,
                ),
              ProviderDetailSection.orders => _OrdersSection(
                  orders: orders,
                  onReceiveOrder: onReceiveOrder,
                ),
              ProviderDetailSection.compose => _ComposeOrderSection(
                  catalog: catalog,
                  draftItems: draftItems,
                  draftUnits: draftUnits,
                  draftTotal: draftTotal,
                  onAddToDraft: onAddToDraft,
                  onIncreaseDraftItem: onIncreaseDraftItem,
                  onDecreaseDraftItem: onDecreaseDraftItem,
                  onCreateOrder: onCreateOrder,
                  onCopyDraft: onCopyDraft,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _ProviderTopBar extends StatelessWidget {
  const _ProviderTopBar({
    required this.record,
    required this.section,
    required this.onSelectSection,
    required this.onEditProvider,
  });

  final ProviderRecord record;
  final ProviderDetailSection section;
  final ValueChanged<ProviderDetailSection> onSelectSection;
  final VoidCallback onEditProvider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: palette.textStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.contact.isEmpty ? 'Sin contacto principal' : record.contact,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onEditProvider,
              child: const Text('Editar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TagPill(label: record.category),
            _TagPill(label: record.isActive ? 'Operativo' : 'Inactivo'),
            _TagPill(label: 'Pedido ${_dayLabels(record.orderDays)}'),
            _TagPill(label: 'Entrega ${_dayLabels(record.deliveryDays)}'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SectionTabs(
                section: section,
                onSelect: onSelectSection,
              ),
            ),
            if (section != ProviderDetailSection.compose) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => onSelectSection(ProviderDetailSection.compose),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.warning,
                  foregroundColor: palette.textStrong,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Nuevo pedido'),
              ),
            ] else ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => onSelectSection(ProviderDetailSection.summary),
                child: const Text('Cerrar pedido'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.section,
    required this.onSelect,
  });

  final ProviderDetailSection section;
  final ValueChanged<ProviderDetailSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Resumen', ProviderDetailSection.summary),
      ('Pedidos', ProviderDetailSection.orders),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in items)
          _SectionButton(
            label: label,
            selected: section == value,
            onTap: () => onSelect(value),
          ),
      ],
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft.withValues(alpha: 0.7) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? palette.accent : palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: palette.textStrong,
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.record,
    required this.productCount,
    required this.balance,
    required this.lastDelivery,
    required this.orderCount,
  });

  final ProviderRecord record;
  final int productCount;
  final double balance;
  final String lastDelivery;
  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(label: 'Productos', value: '$productCount'),
            _MetricCard(label: 'Pedidos', value: '$orderCount'),
            _MetricCard(label: 'Última entrega', value: lastDelivery),
            _MetricCard(label: 'Balance', value: _money(balance)),
          ],
        ),
        const SizedBox(height: 18),
        _InfoBlock(
          title: 'Contacto',
          rows: [
            ('Principal', record.contact.isEmpty ? 'Sin definir' : record.contact),
            ('Teléfono', record.phone.isEmpty ? 'Sin definir' : record.phone),
            ('Email', record.email.isEmpty ? 'Sin definir' : record.email),
          ],
        ),
        const SizedBox(height: 12),
        _InfoBlock(
          title: 'Ritmo de trabajo',
          rows: [
            ('Categoría', record.category),
            ('Días de pedido', _dayLabels(record.orderDays)),
            ('Días de entrega', _dayLabels(record.deliveryDays)),
            ('Estado', record.isActive ? 'Operativo' : 'Inactivo'),
          ],
        ),
      ],
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({
    required this.orders,
    required this.onReceiveOrder,
  });

  final List<ProviderOrder> orders;
  final Future<void> Function(String) onReceiveOrder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (orders.isEmpty) {
      return _EmptyPanel(
        icon: Icons.receipt_long_rounded,
        title: 'Todavía no hay pedidos',
        subtitle: 'Creá el primero desde "Nuevo pedido".',
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final received = order.isReceived;
        return Container(
          padding: const EdgeInsets.all(14),
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
                  Expanded(
                    child: Text(
                      'Pedido ${order.dateLabel}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                  _StatusBadge(label: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.items.length} productos · ${_money(order.total)}',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: order.items
                    .map(
                      (item) => _MiniItemPill(
                        label: '${item.item.name} x${item.quantity}',
                      ),
                    )
                    .toList(),
              ),
              if (!received) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => onReceiveOrder(order.id),
                    child: const Text('Marcar recibido'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ComposeOrderSection extends StatelessWidget {
  const _ComposeOrderSection({
    required this.catalog,
    required this.draftItems,
    required this.draftUnits,
    required this.draftTotal,
    required this.onAddToDraft,
    required this.onIncreaseDraftItem,
    required this.onDecreaseDraftItem,
    required this.onCreateOrder,
    required this.onCopyDraft,
  });

  final List<ProviderCatalogItem> catalog;
  final List<DraftOrderItem> draftItems;
  final int draftUnits;
  final double draftTotal;
  final ValueChanged<ProviderCatalogItem> onAddToDraft;
  final ValueChanged<String> onIncreaseDraftItem;
  final ValueChanged<String> onDecreaseDraftItem;
  final Future<void> Function() onCreateOrder;
  final Future<void> Function() onCopyDraft;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: _SimpleCard(
            title: 'Productos de este proveedor',
            child: catalog.isEmpty
                ? const _EmptyInlineMessage(
                    text: 'No hay productos vinculados a este proveedor.',
                  )
                : ListView.separated(
                    itemCount: catalog.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = catalog[index];
                      return InkWell(
                        onTap: () => onAddToDraft(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: palette.textStrong,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _money(item.lastPrice),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.add_circle_outline_rounded, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SimpleCard(
            title: 'Pedido actual',
            footer: draftItems.isEmpty
                ? null
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$draftUnits unidades',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            _money(draftTotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: palette.textStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onCreateOrder,
                              child: const Text('Emitir pedido'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: onCopyDraft,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.warning,
                                foregroundColor: palette.textStrong,
                              ),
                              child: const Text('Copiar texto'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            child: draftItems.isEmpty
                ? const _EmptyInlineMessage(
                    text: 'Agregá productos desde la izquierda.',
                  )
                : ListView.separated(
                    itemCount: draftItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = draftItems[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: palette.textStrong,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _money(item.total),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => onDecreaseDraftItem(item.item.id),
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                            ),
                            Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: palette.textStrong,
                              ),
                            ),
                            IconButton(
                              onPressed: () => onIncreaseDraftItem(item.item.id),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const SizedBox(height: 12),
          Expanded(child: child),
          if (footer != null) ...[footer!],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 12),
          for (var index = 0; index < rows.length; index++) ...[
            _InfoRow(label: rows[index].$1, value: rows[index].$2),
            if (index != rows.length - 1) const SizedBox(height: 10),
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
          width: 120,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textStrong,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: palette.textStrong,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final received = label == 'Recibido';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: received ? palette.success.withValues(alpha: 0.14) : palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: received ? palette.success : palette.textStrong,
        ),
      ),
    );
  }
}

class _MiniItemPill extends StatelessWidget {
  const _MiniItemPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: palette.textStrong,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInlineMessage extends StatelessWidget {
  const _EmptyInlineMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

String _dayLabels(List<int> days) {
  if (days.isEmpty) {
    return 'Sin definir';
  }
  const labels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };
  return days.map((day) => labels[day] ?? '?').join(' · ');
}

String _money(double value) => '\$${value.toStringAsFixed(0)}';
