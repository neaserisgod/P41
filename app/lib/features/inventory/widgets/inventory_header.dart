import 'package:flutter/material.dart';

import '../../../app/app.dart';

class InventoryHeader extends StatelessWidget {
  const InventoryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.canGoBack,
    required this.onBack,
    this.showAddLocation = false,
    this.onAddLocation,
  });

  final String title;
  final String subtitle;
  final bool canGoBack;
  final VoidCallback onBack;
  final bool showAddLocation;
  final VoidCallback? onAddLocation;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        if (canGoBack) ...[
          IconButton.filledTonal(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: palette.surfaceMuted,
              foregroundColor: palette.textStrong,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (showAddLocation && onAddLocation != null) ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onAddLocation,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Agregar espacio'),
          ),
        ],
      ],
    );
  }
}
