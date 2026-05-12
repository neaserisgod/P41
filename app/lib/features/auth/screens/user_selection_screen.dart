import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/session_context.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({
    super.key,
    required this.users,
    required this.branchName,
    required this.onSelectUser,
  });

  final List<SessionUser> users;
  final String branchName;
  final ValueChanged<SessionUser> onSelectUser;

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
                'Elegí quién va a usar la caja',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                branchName.isEmpty ? 'Elegí quién entra al sistema.' : branchName,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  for (final user in users) ...[
                    _UserCard(
                      user: user,
                      onTap: () => onSelectUser(user),
                    ),
                    if (user != users.last) const SizedBox(height: 12),
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onTap,
  });

  final SessionUser user;
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.role,
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
