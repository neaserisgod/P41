import 'package:flutter/material.dart';

class InventorySpace {
  const InventorySpace({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type;

  IconData get icon => type.toLowerCase() == 'heladera'
      ? Icons.kitchen_rounded
      : Icons.storefront_rounded;

  InventorySpace copyWith({
    String? id,
    String? name,
    String? type,
  }) {
    return InventorySpace(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}
