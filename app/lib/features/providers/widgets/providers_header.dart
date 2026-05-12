import 'package:flutter/material.dart';

import '../../../app/app.dart';

class ProvidersHeader extends StatelessWidget {
  const ProvidersHeader({
    super.key,
    required this.onCreate,
    required this.count,
  });

  final VoidCallback onCreate;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proveedores',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == 0 ? 'Todavía no hay proveedores.' : '$count cargados en este local.',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Agregar'),
        ),
      ],
    );
  }
}
