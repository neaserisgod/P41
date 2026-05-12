import 'package:flutter/material.dart';

import '../app.dart';
import '../models/workspace_tab.dart';
import 'desktop_viewport.dart';
import 'p41_logo.dart';

class TopTabBar extends StatelessWidget {
  const TopTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.headerTitle,
    required this.isSidebarOpen,
    required this.onToggleSidebar,
    required this.onSelect,
    required this.onReplaceSlot,
  });

  final List<WorkspaceTab> tabs;
  final String activeTabId;
  final String headerTitle;
  final bool isSidebarOpen;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String> onSelect;
  final void Function(int slotIndex, WorkspaceKind kind) onReplaceSlot;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.viewport;
        final compact = viewport.tightWidth;
        final leftInset = viewport.narrowWidth
            ? 140.0
            : (compact ? 180.0 : 280.0);
        return SizedBox(
          height: viewport.shortHeight ? 56 : (compact ? 60 : 64),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: viewport.narrowWidth ? 4 : 8),
                    P41Logo(size: compact ? 22 : 24),
                    SizedBox(width: viewport.narrowWidth ? 6 : 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: viewport.narrowWidth ? 164 : 244,
                      ),
                      child: TextButton.icon(
                        onPressed: onToggleSidebar,
                        style: TextButton.styleFrom(
                          foregroundColor: palette.textStrong,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 6 : 8,
                            vertical: compact ? 8 : 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.menu_rounded,
                          size: compact ? 18 : 20,
                          color: isSidebarOpen
                              ? palette.warning
                              : palette.textStrong,
                        ),
                        label: Text(
                          headerTitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w800,
                            color: palette.textStrong,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leftInset,
                      right: viewport.narrowWidth ? 12 : (compact ? 20 : 28),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0; index < tabs.length; index++) ...[
                            _ShellTab(
                              tab: tabs[index],
                              selected: tabs[index].id == activeTabId,
                              centered: index == 1,
                              compact: compact,
                              onTap: () => onSelect(tabs[index].id),
                              onReplace: index == 1
                                  ? null
                                  : (kind) => onReplaceSlot(index, kind),
                            ),
                            if (index != tabs.length - 1)
                              SizedBox(width: viewport.shortHeight ? 6 : 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellTab extends StatelessWidget {
  const _ShellTab({
    required this.tab,
    required this.selected,
    required this.centered,
    required this.compact,
    required this.onTap,
    required this.onReplace,
  });

  final WorkspaceTab tab;
  final bool selected;
  final bool centered;
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<WorkspaceKind>? onReplace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = centered
        ? (selected
              ? palette.warning
              : palette.accentSoft.withValues(alpha: 0.55))
        : (selected
              ? palette.accentSoft.withValues(alpha: 0.65)
              : Colors.transparent);

    final foreground = centered
        ? palette.textStrong
        : (selected ? palette.textStrong : palette.textMuted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(centered ? 18 : 16),
        child: Container(
          constraints: BoxConstraints(
            minWidth: centered ? (compact ? 138 : 180) : (compact ? 112 : 136),
            maxWidth: centered ? (compact ? 168 : 210) : (compact ? 140 : 166),
          ),
          height: centered ? (compact ? 42 : 46) : (compact ? 38 : 42),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(centered ? 18 : 16),
            border: Border.all(
              color: selected
                  ? (centered
                        ? palette.warning.withValues(alpha: 0.28)
                        : palette.border.withValues(alpha: 0.55))
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                tab.icon,
                size: centered ? (compact ? 18 : 20) : (compact ? 16 : 18),
                color: foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tab.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: centered
                        ? (compact ? 13 : 14)
                        : (compact ? 12 : 13),
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
              if (onReplace != null)
                PopupMenuButton<WorkspaceKind>(
                  tooltip: 'Cambiar vista',
                  onSelected: onReplace,
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  itemBuilder: (context) => workspaceDestinations
                      .where(
                        (destination) =>
                            destination.kind != WorkspaceKind.pos &&
                            destination.kind != WorkspaceKind.inventory,
                      )
                      .map(
                        (destination) => PopupMenuItem<WorkspaceKind>(
                          value: destination.kind,
                          child: Row(
                            children: [
                              Icon(
                                destination.icon,
                                size: 16,
                                color: palette.textStrong,
                              ),
                              const SizedBox(width: 10),
                              Text(destination.title),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: foreground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
