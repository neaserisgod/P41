import 'package:flutter/material.dart';

import '../../../app/app.dart';

class PosSearchBar extends StatelessWidget {
  const PosSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: palette.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmit,
              decoration: InputDecoration.collapsed(
                hintText: 'Buscar producto o código',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: palette.textMuted,
                ),
              ),
              style: TextStyle(
                fontSize: 15,
                color: palette.textStrong,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                controller.clear();
                onChanged('');
                focusNode.requestFocus();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: palette.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
