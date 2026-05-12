import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/inventory_location.dart';

class ProviderCardsPanel extends StatelessWidget {
  const ProviderCardsPanel({
    super.key,
    required this.location,
    required this.onSelect,
  });

  final InventoryLocation location;
  final ValueChanged<InventoryProvider> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: location.providers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final provider = location.providers[index];
        return _ProviderRow(
          provider: provider,
          onTap: () => onSelect(provider),
        );
      },
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.provider,
    required this.onTap,
  });

  final InventoryProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 18,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textStrong,
                  ),
                ),
              ),
              Text(
                '${provider.products.length}',
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
