import 'package:flutter/material.dart';

import '../models/workspace_tab.dart';

class TabManager extends ChangeNotifier {
  TabManager._(this._tabs, this._activeTabId);

  factory TabManager.initial({
    WorkspaceKind activeKind = WorkspaceKind.pos,
  }) {
    final left = destinationForKind(WorkspaceKind.home);
    final center = destinationForKind(WorkspaceKind.pos);
    final right = destinationForKind(WorkspaceKind.products);
    final activeTabId = switch (activeKind) {
      WorkspaceKind.home => 'slot-left',
      WorkspaceKind.pos => 'slot-pos',
      WorkspaceKind.products => 'slot-right',
      _ => 'slot-pos',
    };
    return TabManager._(
      [
        WorkspaceTab(
          id: 'slot-left',
          kind: left.kind,
          title: left.title,
          icon: left.icon,
          pinned: true,
          closable: false,
        ),
        WorkspaceTab(
          id: 'slot-pos',
          kind: center.kind,
          title: center.title,
          icon: center.icon,
          pinned: true,
          closable: false,
        ),
        WorkspaceTab(
          id: 'slot-right',
          kind: right.kind,
          title: right.title,
          icon: right.icon,
          pinned: true,
          closable: false,
        ),
      ],
      activeTabId,
    );
  }

  final List<WorkspaceTab> _tabs;
  String _activeTabId;

  List<WorkspaceTab> get tabs => List.unmodifiable(_tabs);

  WorkspaceTab get activeTab => _tabs.firstWhere((tab) => tab.id == _activeTabId, orElse: () => _tabs.first);

  void activateWorkspace(WorkspaceKind kind) {
    openWorkspace(kind);
  }

  void activate(String tabId) {
    if (_activeTabId == tabId) {
      return;
    }
    _activeTabId = tabId;
    notifyListeners();
  }

  void openWorkspace(WorkspaceKind kind) {
    final existingIndex = _tabs.indexWhere((tab) => tab.kind == kind);
    if (existingIndex != -1) {
      _activeTabId = _tabs[existingIndex].id;
      notifyListeners();
      return;
    }

    if (kind == WorkspaceKind.pos) {
      _activeTabId = 'slot-pos';
      notifyListeners();
      return;
    }

    final replaceIndex = _replaceableIndexForActive();
    _tabs[replaceIndex] = _tabForKind(
      kind: kind,
      slotId: replaceIndex == 0 ? 'slot-left' : 'slot-right',
    );
    _activeTabId = _tabs[replaceIndex].id;
    notifyListeners();
  }

  void replaceSlot({
    required int slotIndex,
    required WorkspaceKind kind,
  }) {
    if (slotIndex == 1 || kind == WorkspaceKind.pos) {
      return;
    }

    final existingIndex = _tabs.indexWhere((tab) => tab.kind == kind);
    if (existingIndex != -1) {
      final swapped = _tabs[slotIndex];
      _tabs[slotIndex] = _tabs[existingIndex];
      _tabs[existingIndex] = swapped;
      _activeTabId = _tabs[slotIndex].id;
      notifyListeners();
      return;
    }

    _tabs[slotIndex] = _tabForKind(
      kind: kind,
      slotId: slotIndex == 0 ? 'slot-left' : 'slot-right',
    );
    _activeTabId = _tabs[slotIndex].id;
    notifyListeners();
  }

  void close(String tabId) {}

  void togglePinned(String tabId) {}

  int _replaceableIndexForActive() {
    final activeIndex = _tabs.indexWhere((tab) => tab.id == _activeTabId);
    if (activeIndex == 0 || activeIndex == 2) {
      return activeIndex;
    }
    return 2;
  }

  WorkspaceTab _tabForKind({
    required WorkspaceKind kind,
    required String slotId,
  }) {
    final destination = destinationForKind(kind);
    return WorkspaceTab(
      id: slotId,
      kind: destination.kind,
      title: destination.title,
      icon: destination.icon,
      pinned: true,
      closable: false,
    );
  }
}
