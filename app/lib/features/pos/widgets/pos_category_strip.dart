import 'package:flutter/material.dart';

import '../../../app/app.dart';

class PosCategoryStrip extends StatelessWidget {
  const PosCategoryStrip({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = categories[index];
          final selected = label == selectedCategory;
          return GestureDetector(
            onTap: () => onSelect(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? palette.accentSoft : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? palette.accent : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? palette.textStrong : palette.textMuted,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: categories.length,
      ),
    );
  }
}
