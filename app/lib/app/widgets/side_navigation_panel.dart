import 'package:flutter/material.dart';

import '../app.dart';
import '../models/session_context.dart';
import '../models/workspace_tab.dart';
import '../../features/cash_management/models/cash_shift.dart';
import '../../features/cash_management/widgets/cash_status_card.dart';

class SideNavigationPanel extends StatelessWidget {
  const SideNavigationPanel({
    super.key,
    required this.activeKind,
    required this.activeUser,
    required this.availableUsers,
    required this.onUserSelected,
    required this.activeBranch,
    required this.availableBranches,
    required this.showBranchSwitcher,
    required this.onBranchSelected,
    required this.shift,
    required this.onCashAction,
    required this.onSelect,
  });

  final WorkspaceKind activeKind;
  final SessionUser activeUser;
  final List<SessionUser> availableUsers;
  final ValueChanged<SessionUser> onUserSelected;
  final SessionBranch activeBranch;
  final List<SessionBranch> availableBranches;
  final bool showBranchSwitcher;
  final ValueChanged<SessionBranch> onBranchSelected;
  final CashShift shift;
  final VoidCallback onCashAction;
  final ValueChanged<WorkspaceKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 820;
        return Container(
          width: compact ? 228 : 244,
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(right: BorderSide(color: palette.border)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  14,
                  compact ? 12 : 16,
                  14,
                  compact ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: palette.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountBlock(
                      activeUser: activeUser,
                      availableUsers: availableUsers,
                      onUserSelected: onUserSelected,
                    ),
                    if (showBranchSwitcher) ...[
                      SizedBox(height: compact ? 8 : 10),
                      _BranchBlock(
                        activeBranch: activeBranch,
                        availableBranches: availableBranches,
                        onBranchSelected: onBranchSelected,
                      ),
                    ],
                    SizedBox(height: compact ? 8 : 10),
                    CashStatusCard(shift: shift, onPrimaryAction: onCashAction),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: primaryWorkspaceKinds.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: palette.border.withValues(alpha: 0.7),
                  ),
                  itemBuilder: (context, index) {
                    final destination = destinationForKind(
                      primaryWorkspaceKinds[index],
                    );
                    final isActive = destination.kind == activeKind;

                    return _NavigationRow(
                      destination: destination,
                      isActive: isActive,
                      compact: compact,
                      onTap: () => onSelect(destination.kind),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountBlock extends StatelessWidget {
  const _AccountBlock({
    required this.activeUser,
    required this.availableUsers,
    required this.onUserSelected,
  });

  final SessionUser activeUser;
  final List<SessionUser> availableUsers;
  final ValueChanged<SessionUser> onUserSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialsBadge(initials: activeUser.initials),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeUser.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activeUser.role,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<SessionUser>(
                tooltip: 'Cambiar usuario',
                onSelected: onUserSelected,
                color: Colors.white,
                itemBuilder: (context) => availableUsers
                    .map(
                      (user) => PopupMenuItem<SessionUser>(
                        value: user,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
                    )
                    .toList(),
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cambiar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.warning,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: palette.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BranchBlock extends StatelessWidget {
  const _BranchBlock({
    required this.activeBranch,
    required this.availableBranches,
    required this.onBranchSelected,
  });

  final SessionBranch activeBranch;
  final List<SessionBranch> availableBranches;
  final ValueChanged<SessionBranch> onBranchSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IconBadge(icon: Icons.storefront_rounded),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeBranch.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activeBranch.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<SessionBranch>(
                tooltip: 'Cambiar sucursal',
                onSelected: onBranchSelected,
                color: Colors.white,
                itemBuilder: (context) => availableBranches
                    .map(
                      (branch) => PopupMenuItem<SessionBranch>(
                        value: branch,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              branch.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              branch.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cambiar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.warning,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: palette.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: palette.accent,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: palette.textStrong),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.destination,
    required this.isActive,
    required this.compact,
    required this.onTap,
  });

  final WorkspaceDestination destination;
  final bool isActive;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: compact ? 38 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? palette.accentSoft.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: compact ? 16 : 17,
                color: isActive ? palette.accent : palette.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  destination.title,
                  style: TextStyle(
                    fontSize: compact ? 11.5 : 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? palette.textStrong : palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
