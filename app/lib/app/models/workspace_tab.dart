import 'package:flutter/material.dart';

enum WorkspaceKind { home, pos, inventory, providers, reports, users, branches, products, cash, settings }

class WorkspaceDestination {
  const WorkspaceDestination({
    required this.kind,
    required this.title,
    required this.icon,
  });

  final WorkspaceKind kind;
  final String title;
  final IconData icon;
}

const workspaceDestinations = <WorkspaceDestination>[
  WorkspaceDestination(
    kind: WorkspaceKind.home,
    title: 'Inicio',
    icon: Icons.home_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.pos,
    title: 'POS',
    icon: Icons.point_of_sale_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.providers,
    title: 'Proveedores',
    icon: Icons.local_shipping_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.reports,
    title: 'Reportes',
    icon: Icons.insights_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.users,
    title: 'Usuarios',
    icon: Icons.group_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.branches,
    title: 'Sucursales',
    icon: Icons.store_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.products,
    title: 'Mercadería',
    icon: Icons.inventory_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.cash,
    title: 'Caja',
    icon: Icons.point_of_sale_rounded,
  ),
  WorkspaceDestination(
    kind: WorkspaceKind.settings,
    title: 'Configuración',
    icon: Icons.settings_rounded,
  ),
];

const primaryWorkspaceKinds = <WorkspaceKind>[
  WorkspaceKind.home,
  WorkspaceKind.pos,
  WorkspaceKind.products,
  WorkspaceKind.providers,
  WorkspaceKind.cash,
  WorkspaceKind.reports,
  WorkspaceKind.settings,
];

WorkspaceDestination destinationForKind(WorkspaceKind kind) {
  return workspaceDestinations.firstWhere((destination) => destination.kind == kind);
}

class WorkspaceTab {
  const WorkspaceTab({
    required this.id,
    required this.kind,
    required this.title,
    required this.icon,
    this.pinned = false,
    this.closable = true,
  });

  final String id;
  final WorkspaceKind kind;
  final String title;
  final IconData icon;
  final bool pinned;
  final bool closable;

  WorkspaceTab copyWith({
    String? id,
    WorkspaceKind? kind,
    String? title,
    IconData? icon,
    bool? pinned,
    bool? closable,
  }) {
    return WorkspaceTab(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      pinned: pinned ?? this.pinned,
      closable: closable ?? this.closable,
    );
  }
}
