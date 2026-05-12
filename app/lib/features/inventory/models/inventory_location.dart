import 'package:flutter/material.dart';

import '../../../app/models/catalog_product.dart';
import '../../../app/models/inventory_space.dart';

class InventoryProduct {
  const InventoryProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.status,
  });

  final String id;
  final String name;
  final int stock;
  final String price;
  final String status;
}

class InventoryProvider {
  const InventoryProvider({
    required this.id,
    required this.name,
    required this.products,
  });

  final String id;
  final String name;
  final List<InventoryProduct> products;
}

class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.providers,
  });

  final String id;
  final String name;
  final String type;
  final IconData icon;
  final List<InventoryProvider> providers;
}

List<InventoryLocation> buildInventoryLocations(List<CatalogProduct> products) {
  return buildInventoryLocationsWithSpaces(products, const []);
}

List<InventoryLocation> buildInventoryLocationsWithSpaces(
  List<CatalogProduct> products,
  List<InventorySpace> spaces,
) {
  final groupedByLocation = <String, List<CatalogProduct>>{};
  for (final product in products.where((item) => item.isActive)) {
    groupedByLocation.putIfAbsent(product.locationId, () => []).add(product);
  }

  final locations = groupedByLocation.entries.map((entry) {
    final locationProducts = entry.value;
    final first = locationProducts.first;
    final groupedByProvider = <String, List<CatalogProduct>>{};
    for (final product in locationProducts) {
      groupedByProvider.putIfAbsent(product.supplierId, () => []).add(product);
    }

    return InventoryLocation(
      id: first.locationId,
      name: first.locationName,
      type: first.locationType,
      icon: first.locationType.toLowerCase() == 'heladera'
          ? Icons.kitchen_rounded
          : Icons.storefront_rounded,
      providers: groupedByProvider.entries.map((providerEntry) {
        final providerProducts = providerEntry.value;
        final providerFirst = providerProducts.first;
        return InventoryProvider(
          id: providerFirst.supplierId,
          name: providerFirst.supplierName,
          products: providerProducts
              .map(
                (product) => InventoryProduct(
                  id: product.id,
                  name: product.name,
                  stock: product.stock,
                  price: _money(product.price),
                  status: product.status,
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }).toList();

  for (final space in spaces) {
    final exists = locations.any((location) => location.id == space.id);
    if (exists) {
      continue;
    }
    locations.add(
      InventoryLocation(
        id: space.id,
        name: space.name,
        type: space.type,
        icon: space.icon,
        providers: const [],
      ),
    );
  }

  locations.sort((a, b) {
    final byType = a.type.toLowerCase().compareTo(b.type.toLowerCase());
    if (byType != 0) {
      return byType;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return locations;
}

String _money(double value) {
  final normalized = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < normalized.length; i++) {
    final remaining = normalized.length - i;
    buffer.write(normalized[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '\$$buffer';
}
