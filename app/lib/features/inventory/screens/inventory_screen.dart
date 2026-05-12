import 'package:flutter/material.dart';

import '../../../app/state/catalog_controller.dart';
import '../../catalog_products/screens/products_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    super.key,
    required this.catalogController,
  });

  final CatalogController catalogController;

  @override
  Widget build(BuildContext context) {
    return ProductsScreen(
      catalogController: catalogController,
      initialViewMode: MerchandiseViewMode.spaces,
    );
  }
}
