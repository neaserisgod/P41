import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../models/inventory_location.dart';

class LocationCardsBoard extends StatelessWidget {
  const LocationCardsBoard({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onSelect,
  });

  final List<InventoryLocation> locations;
  final String? selectedLocationId;
  final ValueChanged<InventoryLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: locations.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final location = locations[index];
        return _LocationCard(
          location: location,
          selected: location.id == selectedLocationId,
          onTap: () => onSelect(location),
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final InventoryLocation location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? palette.accent : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  location.icon,
                  size: 14,
                  color: selected ? Colors.white : palette.textStrong,
                ),
              ),
              const Spacer(),
              Text(
                location.type.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                location.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                location.providers.isEmpty
                    ? 'Todavía no hay productos en esta ubicación.'
                    : location.providers.map((provider) => provider.name).join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: palette.textMuted,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    location.providers.isEmpty
                        ? 'Vacío'
                        : '${location.providers.length} proveedores',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 14, color: palette.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
