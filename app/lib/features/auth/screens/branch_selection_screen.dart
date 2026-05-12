import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/session_context.dart';

class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({
    super.key,
    required this.branches,
    required this.onSelectBranch,
  });

  final List<SessionBranch> branches;
  final ValueChanged<SessionBranch> onSelectBranch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.shell,
      body: Center(
        child: Container(
          width: 680,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elegí una sucursal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tocá una opción para seguir.',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  for (final branch in branches) ...[
                    _SelectionCard(
                      icon: Icons.storefront_rounded,
                      title: branch.name,
                      subtitle: branch.label,
                      onTap: () => onSelectBranch(branch),
                    ),
                    if (branch != branches.last) const SizedBox(height: 12),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: palette.accent, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
