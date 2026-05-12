import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/catalog_product.dart';
import '../../../app/models/global_catalog_product.dart';
import '../../../app/models/inventory_space.dart';
import '../../../app/models/product_pricing_rules.dart';
import '../../../app/state/catalog_controller.dart';
import '../../../app/widgets/product_image.dart';
import '../../inventory/models/inventory_location.dart';
import '../../inventory/view_models/inventory_view_model.dart';
import '../../inventory/widgets/location_cards_board.dart';
import '../../inventory/widgets/provider_cards_panel.dart';
import '../../inventory/widgets/provider_products_grid.dart';

enum MerchandiseViewMode { products, spaces }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
    required this.catalogController,
    this.initialViewMode = MerchandiseViewMode.products,
  });

  final CatalogController catalogController;
  final MerchandiseViewMode initialViewMode;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  bool _isSaving = false;
  late MerchandiseViewMode _viewMode;
  late final InventoryViewModel _inventoryViewModel;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
    _inventoryViewModel = InventoryViewModel();
  }

  @override
  void dispose() {
    _inventoryViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('products-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: widget.catalogController,
        builder: (context, _) {
          final products = _filteredProducts(widget.catalogController.products);
          final locations = _filteredLocations(
            buildInventoryLocationsWithSpaces(
              widget.catalogController.activeProducts,
              widget.catalogController.inventorySpaces,
            ),
          );
          _inventoryViewModel.updateLocations(locations);

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 1180 || constraints.maxHeight < 760;
              return Padding(
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductsHeader(
                      compact: compact,
                      viewMode: _viewMode,
                      query: _query,
                      totalProducts: widget.catalogController.products.length,
                      totalLocations:
                          widget.catalogController.inventorySpaces.length,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onViewModeChanged: (mode) =>
                          setState(() => _viewMode = mode),
                      onCreate: () => _openEditor(),
                      onCreateSpace: _openLocationDialog,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _viewMode == MerchandiseViewMode.products
                          ? _ProductsListPanel(
                              products: products,
                              onCreate: () => _openEditor(),
                              onTapProduct: (product) =>
                                  _openEditor(product: product),
                            )
                          : _SpacesPanel(
                              viewModel: _inventoryViewModel,
                              onCreateSpace: _openLocationDialog,
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<CatalogProduct> _filteredProducts(List<CatalogProduct> products) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return products;
    }
    return products.where((product) {
      return product.name.toLowerCase().contains(normalized) ||
          product.sku.toLowerCase().contains(normalized) ||
          product.category.toLowerCase().contains(normalized) ||
          product.supplierName.toLowerCase().contains(normalized) ||
          product.locationName.toLowerCase().contains(normalized) ||
          product.locationType.toLowerCase().contains(normalized);
    }).toList();
  }

  List<InventoryLocation> _filteredLocations(
    List<InventoryLocation> locations,
  ) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return locations;
    }
    return locations.where((location) {
      if (location.name.toLowerCase().contains(normalized) ||
          location.type.toLowerCase().contains(normalized)) {
        return true;
      }
      for (final provider in location.providers) {
        if (provider.name.toLowerCase().contains(normalized)) {
          return true;
        }
        for (final product in provider.products) {
          if (product.name.toLowerCase().contains(normalized)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  Future<void> _openLocationDialog() async {
    final result = await showDialog<_InventoryLocationDraft>(
      context: context,
      builder: (context) => const _InventoryLocationDialog(),
    );
    if (result == null) {
      return;
    }
    await widget.catalogController.createInventorySpace(
      name: result.name,
      type: result.type,
    );
  }

  Future<void> _openEditor({CatalogProduct? product}) async {
    if (_isSaving) {
      return;
    }

    final result = await showDialog<_ProductDraft>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) {
        return _ProductEditorDialog(
          product: product,
          catalogController: widget.catalogController,
          supplierNames: widget.catalogController.supplierNames,
          categoryNames: widget.catalogController.categories,
          inventorySpaces: widget.catalogController.inventorySpaces,
          locationTypes: widget.catalogController.locationTypes,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (product == null) {
        await widget.catalogController.createProduct(
          name: result.name,
          sku: result.sku,
          barcode: result.barcode,
          imageUrl: result.imageUrl,
          category: result.category,
          supplierName: result.supplierName,
          locationName: result.locationName,
          locationType: result.locationType,
          price: result.price,
          cost: result.cost,
          stock: result.stock,
          minStock: result.minStock,
          pricingRules: result.pricingRules,
          expirationDate: result.expirationDate,
          isActive: true,
        );
      } else {
        await widget.catalogController.updateProduct(
          product.copyWith(
            name: result.name,
            sku: result.sku,
            barcode: result.barcode,
            category: result.category,
            supplierName: result.supplierName,
            locationName: result.locationName,
            locationType: result.locationType,
            price: result.price,
            cost: result.cost,
            stock: result.stock,
            minStock: result.minStock,
            pricingRules: result.pricingRules,
            expirationDate: result.expirationDate,
            clearExpirationDate: result.expirationDate == null,
            imageUrl: result.imageUrl,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({
    required this.compact,
    required this.viewMode,
    required this.query,
    required this.totalProducts,
    required this.totalLocations,
    required this.onQueryChanged,
    required this.onViewModeChanged,
    required this.onCreate,
    required this.onCreateSpace,
  });

  final bool compact;
  final MerchandiseViewMode viewMode;
  final String query;
  final int totalProducts;
  final int totalLocations;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MerchandiseViewMode> onViewModeChanged;
  final VoidCallback onCreate;
  final VoidCallback onCreateSpace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final statusText = viewMode == MerchandiseViewMode.products
        ? (totalProducts == 1
              ? '1 producto cargado.'
              : '$totalProducts productos cargados.')
        : (totalLocations == 1
              ? '1 espacio cargado.'
              : '$totalLocations espacios cargados.');

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mercaderia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          _ViewModeToggle(value: viewMode, onChanged: onViewModeChanged),
          const SizedBox(height: 12),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: viewMode == MerchandiseViewMode.products
                  ? 'Buscar por nombre, SKU o lugar'
                  : 'Buscar por mueble, heladera o producto',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (viewMode == MerchandiseViewMode.spaces)
                OutlinedButton.icon(
                  onPressed: onCreateSpace,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_home_work_rounded),
                  label: const Text(
                    'Agregar espacio',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.warning,
                  foregroundColor: palette.textStrong,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Agregar producto',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mercaderia',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            ],
          ),
        ),
        _ViewModeToggle(value: viewMode, onChanged: onViewModeChanged),
        const SizedBox(width: 12),
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: viewMode == MerchandiseViewMode.products
                  ? 'Buscar por nombre, SKU o lugar'
                  : 'Buscar por mueble, heladera o producto',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (viewMode == MerchandiseViewMode.spaces) ...[
          OutlinedButton.icon(
            onPressed: onCreateSpace,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              side: BorderSide(color: palette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_home_work_rounded),
            label: const Text(
              'Agregar espacio',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: palette.warning,
            foregroundColor: palette.textStrong,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Agregar producto',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.value, required this.onChanged});

  final MerchandiseViewMode value;
  final ValueChanged<MerchandiseViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget button({
      required MerchandiseViewMode mode,
      required String label,
      required IconData icon,
    }) {
      final selected = value == mode;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(mode),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? palette.warning : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? palette.textStrong : palette.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? palette.textStrong : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          button(
            mode: MerchandiseViewMode.products,
            label: 'Por producto',
            icon: Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 4),
          button(
            mode: MerchandiseViewMode.spaces,
            label: 'Por espacio',
            icon: Icons.kitchen_rounded,
          ),
        ],
      ),
    );
  }
}

class _ProductsListPanel extends StatelessWidget {
  const _ProductsListPanel({
    required this.products,
    required this.onCreate,
    required this.onTapProduct,
  });

  final List<CatalogProduct> products;
  final VoidCallback onCreate;
  final ValueChanged<CatalogProduct> onTapProduct;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: products.isEmpty
          ? _EmptyProductsState(onCreate: onCreate)
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (context, index) =>
                  Divider(color: palette.border),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductRow(
                  product: product,
                  onTap: () => onTapProduct(product),
                );
              },
            ),
    );
  }
}

class _SpacesPanel extends StatelessWidget {
  const _SpacesPanel({required this.viewModel, required this.onCreateSpace});

  final InventoryViewModel viewModel;
  final VoidCallback onCreateSpace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                if (viewModel.canGoBack) ...[
                  IconButton(
                    onPressed: viewModel.goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (viewModel.step) {
              InventoryStep.locations =>
                viewModel.locations.isEmpty
                    ? _EmptySpacesState(onCreateSpace: onCreateSpace)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: LocationCardsBoard(
                          locations: viewModel.locations,
                          selectedLocationId: viewModel.selectedLocation?.id,
                          onSelect: viewModel.enterLocation,
                        ),
                      ),
              InventoryStep.providers =>
                viewModel.selectedLocation == null
                    ? _EmptySpacesState(onCreateSpace: onCreateSpace)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ProviderCardsPanel(
                          location: viewModel.selectedLocation!,
                          onSelect: viewModel.enterProvider,
                        ),
                      ),
              InventoryStep.products =>
                viewModel.selectedProvider == null
                    ? _EmptySpacesState(onCreateSpace: onCreateSpace)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ProviderProductsGrid(
                          provider: viewModel.selectedProvider!,
                        ),
                      ),
            },
          ),
        ],
      ),
    );
  }
}

class _EmptySpacesState extends StatelessWidget {
  const _EmptySpacesState({required this.onCreateSpace});

  final VoidCallback onCreateSpace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen_rounded, size: 42, color: palette.textMuted),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay muebles ni heladeras.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Creá primero el espacio y después cargá productos adentro.',
              style: TextStyle(fontSize: 12.5, color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreateSpace,
              child: const Text('Crear espacio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryLocationDraft {
  const _InventoryLocationDraft({required this.name, required this.type});

  final String name;
  final String type;
}

class _InventoryLocationDialog extends StatefulWidget {
  const _InventoryLocationDialog();

  @override
  State<_InventoryLocationDialog> createState() =>
      _InventoryLocationDialogState();
}

class _InventoryLocationDialogState extends State<_InventoryLocationDialog> {
  static const List<String> _types = ['Mueble', 'Heladera'];

  late final TextEditingController _nameController;
  String _type = _types.first;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Agregar espacio'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: 'Tipo',
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
              items: _types
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: _type == 'Heladera' ? 'Ej. Bebidas' : 'Ej. Entrada',
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(
              context,
            ).pop(_InventoryLocationDraft(name: name, type: _type));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final CatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: palette.surface,
        ),
        child: Row(
          children: [
            _ProductThumbnail(product: product),
            const SizedBox(width: 14),
            Expanded(
              flex: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.sku} • ${product.category}',
                    style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 22,
              child: Text(
                product.supplierName,
                style: TextStyle(fontSize: 12, color: palette.textStrong),
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                '${product.locationType} ${product.locationName}',
                style: TextStyle(fontSize: 12, color: palette.textStrong),
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                '${product.stock}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.textStrong,
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Text(
                _money(product.price),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ProductStatusChip(product: product),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: product.imageUrl.trim().isEmpty
          ? Icon(Icons.inventory_2_rounded, color: palette.textMuted)
          : ProductImage(
              source: product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.inventory_2_rounded, color: palette.textMuted),
            ),
    );
  }
}

class _ProductStatusChip extends StatelessWidget {
  const _ProductStatusChip({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isLow = product.status == 'Stock bajo';
    final isEmpty = product.status == 'Sin stock';
    final color = isEmpty
        ? palette.danger
        : isLow
        ? palette.warning
        : palette.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        product.status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_rounded, size: 42, color: palette.textMuted),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay productos.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cargá el primero con nombre, SKU, categoría, proveedor y lugar.',
              style: TextStyle(fontSize: 12.5, color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Crear producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({
    required this.catalogController,
    required this.product,
    required this.supplierNames,
    required this.categoryNames,
    required this.inventorySpaces,
    required this.locationTypes,
  });

  final CatalogController catalogController;
  final CatalogProduct? product;
  final List<String> supplierNames;
  final List<String> categoryNames;
  final List<InventorySpace> inventorySpaces;
  final List<String> locationTypes;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  static const _baseLocationTypes = [
    'Mueble',
    'Heladera',
    'Freezer',
    'Deposito',
  ];
  static const _customCategoryValue = '__custom_category__';
  static const _customLocationValue = '__custom_location__';

  late final TextEditingController _globalSearchController;
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _customLocationController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _markupController;
  late final TextEditingController _bonusController;
  late final TextEditingController _vatController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late String _locationType;
  late String _supplierName;
  late String _categoryValue;
  late String _locationValue;
  late String _barcodeValue;
  late String _imageUrlValue;
  late bool _bonusEnabled;
  late bool _vatEnabled;
  DateTime? _expirationDate;
  List<GlobalCatalogProduct> _globalSuggestions = const [];
  Timer? _globalSearchDebounce;
  bool _isSearchingGlobal = false;
  String? _globalLookupError;
  bool _isUpdatingPricing = false;
  _PricingField? _expandedPricingField = _PricingField.markup;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final defaultCategory = widget.categoryNames.isNotEmpty
        ? widget.categoryNames.first
        : 'Almacen';
    _globalSearchController = TextEditingController();
    _nameController = TextEditingController(text: product?.name ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _customCategoryController = TextEditingController();
    _customLocationController = TextEditingController();
    final pricing =
        product?.pricingRules ?? widget.catalogController.pricingDefaults;
    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(0) : '',
    );
    _costController = TextEditingController(
      text: product != null ? product.cost.toStringAsFixed(0) : '',
    );
    _markupController = TextEditingController(
      text: _formatPercent(pricing.markupPercent),
    );
    _bonusController = TextEditingController(
      text: _formatPercent(pricing.bonusPercent),
    );
    _vatController = TextEditingController(
      text: _formatPercent(pricing.vatPercent),
    );
    _stockController = TextEditingController(
      text: product != null ? product.stock.toString() : '',
    );
    _minStockController = TextEditingController(
      text: product != null ? product.minStock.toString() : '',
    );
    _locationType =
        product?.locationType ??
        (widget.locationTypes.isNotEmpty
            ? widget.locationTypes.first
            : 'Mueble');
    _supplierName = _resolveSupplierName(product?.supplierName);
    _barcodeValue = product?.barcode ?? '';
    _imageUrlValue = product?.imageUrl ?? '';
    _bonusEnabled = pricing.bonusEnabled;
    _vatEnabled = pricing.vatEnabled;
    final category = product?.category.trim();
    if (category != null &&
        category.isNotEmpty &&
        !widget.categoryNames.contains(category)) {
      _categoryValue = _customCategoryValue;
      _customCategoryController.text = category;
    } else {
      _categoryValue = category != null && category.isNotEmpty
          ? category
          : defaultCategory;
    }
    _syncLocationSelection(
      preferredName: product?.locationName,
      preserveCustomText: product?.locationName,
    );
    _expirationDate = product?.expirationDate;
    if ((product?.barcode.trim().isNotEmpty ?? false) ||
        (product?.name.trim().isNotEmpty ?? false)) {
      _globalSearchController.text = product?.barcode.trim().isNotEmpty ?? false
          ? product!.barcode
          : product!.name;
    }
    _bindPricingListeners();
    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recalculateFromCost(),
      );
    }
  }

  @override
  void dispose() {
    _globalSearchDebounce?.cancel();
    _globalSearchController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _customCategoryController.dispose();
    _customLocationController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _markupController.dispose();
    _bonusController.dispose();
    _vatController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = widget.product == null
        ? 'Agregar producto'
        : 'Editar producto';
    final locationTypes = {
      ..._baseLocationTypes,
      ...widget.locationTypes.where((item) => item.trim().isNotEmpty),
    }.toList()..sort();
    final categoryOptions = [...widget.categoryNames];
    final categoryDropdownValue = categoryOptions.contains(_categoryValue)
        ? _categoryValue
        : _customCategoryValue;
    final spacesForType = _spacesForSelectedType();
    final locationDropdownValue =
        spacesForType.any((space) => space.id == _locationValue)
        ? _locationValue
        : _customLocationValue;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: palette.textStrong,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solo lo importante para vender y reponer.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _GlobalLookupCard(
                        controller: _globalSearchController,
                        suggestions: _globalSuggestions,
                        isLoading: _isSearchingGlobal,
                        imageUrl: _imageUrlValue,
                        helperText: _globalLookupError,
                        onChanged: _onGlobalSearchChanged,
                        onSelected: _applyGlobalProduct,
                        onLookupBarcode: _lookupBarcode,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _EditorField(
                              controller: _nameController,
                              label: 'Nombre',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EditorField(
                              controller: _skuController,
                              label: 'SKU',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField(
                              value: categoryDropdownValue,
                              label: 'Categoría',
                              options: categoryOptions,
                              emptyLabel: 'Seleccionar categoría',
                              customValue: _customCategoryValue,
                              customLabel: 'Nueva categoría',
                              onChanged: (value) {
                                setState(() {
                                  _categoryValue = value;
                                  if (value != _customCategoryValue) {
                                    _customCategoryController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SelectionField(
                              value: _supplierName,
                              label: 'Proveedor',
                              options: widget.supplierNames,
                              emptyLabel: 'Sin proveedor',
                              onChanged: (value) =>
                                  setState(() => _supplierName = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_categoryValue == _customCategoryValue) ...[
                        _EditorField(
                          controller: _customCategoryController,
                          label: 'Nombre de la categoría',
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _LocationTypeField(
                              value: _locationType,
                              options: locationTypes,
                              onChanged: (value) => setState(() {
                                _locationType = value;
                                _syncLocationSelection();
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _DropdownField(
                              value: locationDropdownValue,
                              label: 'Lugar',
                              options: spacesForType
                                  .map((space) => space.id)
                                  .toList(),
                              optionLabels: {
                                for (final space in spacesForType)
                                  space.id: space.name,
                              },
                              emptyLabel: 'Seleccionar lugar',
                              customValue: _customLocationValue,
                              customLabel: 'Crear lugar nuevo',
                              onChanged: (value) {
                                setState(() {
                                  _locationValue = value;
                                  if (value != _customLocationValue) {
                                    _customLocationController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_locationValue == _customLocationValue) ...[
                        _EditorField(
                          controller: _customLocationController,
                          label: 'Nombre del lugar',
                        ),
                        const SizedBox(height: 12),
                      ],
                      _PricingRulesCard(
                        markupController: _markupController,
                        bonusController: _bonusController,
                        vatController: _vatController,
                        bonusEnabled: _bonusEnabled,
                        vatEnabled: _vatEnabled,
                        expandedField: _expandedPricingField,
                        onExpandField: (field) => setState(() {
                          _expandedPricingField = _expandedPricingField == field
                              ? null
                              : field;
                        }),
                        onBonusEnabledChanged: (value) {
                          setState(() => _bonusEnabled = value);
                          _recalculateFromCost();
                        },
                        onVatEnabledChanged: (value) {
                          setState(() => _vatEnabled = value);
                          _recalculateFromCost();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _EditorField(
                              controller: _costController,
                              label: 'Precio costo',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EditorField(
                              controller: _priceController,
                              label: 'Precio venta',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _EditorField(
                              controller: _stockController,
                              label: 'Stock',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EditorField(
                              controller: _minStockController,
                              label: 'Stock mínimo',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: 'Vencimiento',
                              value: _expirationDate,
                              onPick: _pickDate,
                              onClear: () =>
                                  setState(() => _expirationDate = null),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.warning,
                      foregroundColor: palette.textStrong,
                    ),
                    child: Text(
                      widget.product == null
                          ? 'Guardar producto'
                          : 'Guardar cambios',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onGlobalSearchChanged(String value) {
    _globalLookupError = null;
    _globalSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _globalSuggestions = const [];
        _isSearchingGlobal = false;
      });
      return;
    }
    _globalSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingGlobal = true);
      try {
        final results = await widget.catalogController.searchGlobalProducts(
          query,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _globalSuggestions = results;
          _isSearchingGlobal = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _globalSuggestions = const [];
          _isSearchingGlobal = false;
          _globalLookupError = 'No se pudo buscar en el catálogo global.';
        });
      }
    });
  }

  Future<void> _lookupBarcode() async {
    final barcode = _globalSearchController.text.trim();
    if (barcode.length < 3) {
      return;
    }
    setState(() {
      _isSearchingGlobal = true;
      _globalLookupError = null;
    });
    try {
      final product = await widget.catalogController.lookupGlobalProduct(
        barcode,
      );
      if (!mounted) {
        return;
      }
      if (product == null) {
        setState(() {
          _isSearchingGlobal = false;
          _globalLookupError = 'No encontré ese código.';
        });
        return;
      }
      _applyGlobalProduct(product);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearchingGlobal = false;
        _globalLookupError = 'No se pudo consultar el catálogo global.';
      });
    }
  }

  void _applyGlobalProduct(GlobalCatalogProduct product) {
    final suggestedCategory = product.category.trim();
    final localCategoryMatch = widget.categoryNames.where(
      (item) => item.trim().toLowerCase() == suggestedCategory.toLowerCase(),
    );
    final selectedCategory = localCategoryMatch.isNotEmpty
        ? localCategoryMatch.first
        : _customCategoryValue;
    setState(() {
      _globalSearchController.text = product.barcode.isNotEmpty
          ? product.barcode
          : product.name;
      _globalSuggestions = const [];
      _isSearchingGlobal = false;
      _globalLookupError = null;
      _nameController.text = product.name;
      _skuController.text = product.barcode.isNotEmpty
          ? product.barcode
          : _skuController.text;
      _barcodeValue = product.barcode;
      _imageUrlValue = product.imageUrl;
      if (selectedCategory == _customCategoryValue) {
        _categoryValue = _customCategoryValue;
        _customCategoryController.text = suggestedCategory;
      } else {
        _categoryValue = selectedCategory;
        _customCategoryController.clear();
      }
      if ((product.suggestedPrice ?? 0) > 0 &&
          _priceController.text.trim().isEmpty) {
        _priceController.text = product.suggestedPrice!.toStringAsFixed(0);
      }
    });
  }

  void _bindPricingListeners() {
    _costController.addListener(() {
      if (_isUpdatingPricing) return;
      _recalculateFromCost();
    });
    _priceController.addListener(() {
      if (_isUpdatingPricing) return;
      _recalculateFromPrice();
    });
    for (final controller in [
      _markupController,
      _bonusController,
      _vatController,
    ]) {
      controller.addListener(() {
        if (_isUpdatingPricing) return;
        _recalculateFromCost();
      });
    }
  }

  void _recalculateFromCost() {
    final cost = _doubleFromController(_costController);
    final price = _pricingRules().salePriceFromCost(cost);
    _setControllerValue(_priceController, _formatMoneyInput(price));
  }

  void _recalculateFromPrice() {
    final price = _doubleFromController(_priceController);
    final cost = _pricingRules().costFromSalePrice(price);
    _setControllerValue(_costController, _formatMoneyInput(cost));
  }

  ProductPricingRules _pricingRules() {
    return ProductPricingRules(
      markupPercent: _doubleFromController(_markupController),
      bonusPercent: _doubleFromController(_bonusController),
      bonusEnabled: _bonusEnabled,
      vatPercent: _doubleFromController(_vatController),
      vatEnabled: _vatEnabled,
    );
  }

  double _doubleFromController(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    _isUpdatingPricing = true;
    controller.text = value;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    _isUpdatingPricing = false;
  }

  String _formatMoneyInput(double value) {
    final rounded = value.toStringAsFixed(2);
    if (rounded.endsWith('.00')) {
      return rounded.substring(0, rounded.length - 3);
    }
    if (rounded.endsWith('0')) {
      return rounded.substring(0, rounded.length - 1);
    }
    return rounded;
  }

  String _formatPercent(double value) {
    final rounded = value.toStringAsFixed(2);
    if (rounded.endsWith('.00')) {
      return rounded.substring(0, rounded.length - 3);
    }
    if (rounded.endsWith('0')) {
      return rounded.substring(0, rounded.length - 1);
    }
    return rounded;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final category = _selectedCategory();
    final locationName = _selectedLocationName();

    if (name.isEmpty ||
        sku.isEmpty ||
        category.isEmpty ||
        locationName.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _ProductDraft(
        name: name,
        sku: sku,
        barcode: _barcodeValue.trim(),
        category: category,
        supplierName: _supplierName,
        locationName: locationName,
        locationType: _locationType,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        cost: double.tryParse(_costController.text.trim()) ?? 0,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        minStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        pricingRules: _pricingRules(),
        expirationDate: _expirationDate,
        imageUrl: _imageUrlValue.trim(),
      ),
    );
  }

  String _resolveSupplierName(String? currentValue) {
    final normalized = currentValue?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }
    return widget.supplierNames.contains(normalized) ? normalized : '';
  }

  List<InventorySpace> _spacesForSelectedType() {
    final normalizedType = _locationType.trim().toLowerCase();
    return widget.inventorySpaces
        .where((space) => space.type.trim().toLowerCase() == normalizedType)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _syncLocationSelection({
    String? preferredName,
    String? preserveCustomText,
  }) {
    final spaces = _spacesForSelectedType();
    final normalizedName = preferredName?.trim().toLowerCase();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      for (final space in spaces) {
        if (space.name.trim().toLowerCase() == normalizedName) {
          _locationValue = space.id;
          _customLocationController.clear();
          return;
        }
      }
    }
    _locationValue = _customLocationValue;
    if (preserveCustomText != null && preserveCustomText.trim().isNotEmpty) {
      _customLocationController.text = preserveCustomText.trim();
    }
  }

  String _selectedCategory() {
    if (_categoryValue == _customCategoryValue) {
      return _customCategoryController.text.trim();
    }
    return _categoryValue.trim();
  }

  String _selectedLocationName() {
    if (_locationValue == _customLocationValue) {
      return _customLocationController.text.trim();
    }
    for (final space in _spacesForSelectedType()) {
      if (space.id == _locationValue) {
        return space.name;
      }
    }
    return '';
  }
}

class _GlobalLookupCard extends StatelessWidget {
  const _GlobalLookupCard({
    required this.controller,
    required this.suggestions,
    required this.isLoading,
    required this.imageUrl,
    required this.helperText,
    required this.onChanged,
    required this.onSelected,
    required this.onLookupBarcode,
  });

  final TextEditingController controller;
  final List<GlobalCatalogProduct> suggestions;
  final bool isLoading;
  final String imageUrl;
  final String? helperText;
  final ValueChanged<String> onChanged;
  final ValueChanged<GlobalCatalogProduct> onSelected;
  final VoidCallback onLookupBarcode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo global',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buscá por código o nombre y precargá el producto.',
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LookupPreview(imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            onChanged: onChanged,
                            decoration: InputDecoration(
                              labelText: 'Buscar por código o nombre',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: palette.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: palette.border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: onLookupBarcode,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.warning,
                            foregroundColor: palette.textStrong,
                            minimumSize: const Size(0, 54),
                          ),
                          child: const Text(
                            'Traer',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          helperText!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                    if (isLoading) ...[
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ] else if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.border),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: suggestions.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: palette.border, height: 1),
                            itemBuilder: (context, index) {
                              final product = suggestions[index];
                              final subtitle = [
                                if (product.brand.trim().isNotEmpty)
                                  product.brand.trim(),
                                if (product.category.trim().isNotEmpty)
                                  product.category.trim(),
                              ].join(' • ');
                              return ListTile(
                                dense: true,
                                leading: _LookupPreview(
                                  imageUrl: product.imageUrl,
                                  size: 42,
                                ),
                                title: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${product.barcode}${subtitle.isEmpty ? '' : ' • $subtitle'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(product),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LookupPreview extends StatelessWidget {
  const _LookupPreview({required this.imageUrl, this.size = 72});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl.trim().isEmpty
          ? Icon(
              Icons.image_outlined,
              color: palette.textMuted,
              size: size * 0.4,
            )
          : ProductImage(
              source: imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_outlined,
                color: palette.textMuted,
                size: size * 0.4,
              ),
            ),
    );
  }
}

enum _PricingField { markup, bonus, vat }

class _PricingRulesCard extends StatelessWidget {
  const _PricingRulesCard({
    required this.markupController,
    required this.bonusController,
    required this.vatController,
    required this.bonusEnabled,
    required this.vatEnabled,
    required this.expandedField,
    required this.onExpandField,
    required this.onBonusEnabledChanged,
    required this.onVatEnabledChanged,
  });

  final TextEditingController markupController;
  final TextEditingController bonusController;
  final TextEditingController vatController;
  final bool bonusEnabled;
  final bool vatEnabled;
  final _PricingField? expandedField;
  final ValueChanged<_PricingField> onExpandField;
  final ValueChanged<bool> onBonusEnabledChanged;
  final ValueChanged<bool> onVatEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cálculo del precio',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El precio final se calcula desde costo, margen, bonificación e IVA. Si cambiás el precio final, recalcula el costo.',
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _PricingAccordionItem(
                title: 'Markup / margen',
                summary:
                    '${markupController.text.trim().isEmpty ? '0' : markupController.text.trim()}%',
                isExpanded: expandedField == _PricingField.markup,
                onTap: () => onExpandField(_PricingField.markup),
                child: _EditorField(
                  controller: markupController,
                  label: 'Markup / margen %',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  filledColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _PricingAccordionItem(
                title: 'Bonificación',
                summary: bonusEnabled
                    ? '${bonusController.text.trim().isEmpty ? '0' : bonusController.text.trim()}%'
                    : 'Desactivada',
                isExpanded: expandedField == _PricingField.bonus,
                onTap: () => onExpandField(_PricingField.bonus),
                child: _TogglePercentField(
                  controller: bonusController,
                  label: 'Bonificación %',
                  value: bonusEnabled,
                  onChanged: onBonusEnabledChanged,
                ),
              ),
              const SizedBox(height: 8),
              _PricingAccordionItem(
                title: 'IVA',
                summary: vatEnabled
                    ? '${vatController.text.trim().isEmpty ? '0' : vatController.text.trim()}%'
                    : 'Desactivado',
                isExpanded: expandedField == _PricingField.vat,
                onTap: () => onExpandField(_PricingField.vat),
                child: _TogglePercentField(
                  controller: vatController,
                  label: 'IVA %',
                  value: vatEnabled,
                  onChanged: onVatEnabledChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingAccordionItem extends StatelessWidget {
  const _PricingAccordionItem({
    required this.title,
    required this.summary,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String summary;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.filledColor,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final Color? filledColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(
            palette,
            label,
            filledColor: filledColor,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    AppPalette palette,
    String label, {
    Color? filledColor,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: filledColor ?? palette.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
    );
  }
}

class _TogglePercentField extends StatelessWidget {
  const _TogglePercentField({
    required this.controller,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textStrong,
                ),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Porcentaje',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.value,
    required this.label,
    required this.options,
    required this.emptyLabel,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> options;
  final String emptyLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolvedValue = options.contains(value) ? value : '';

    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      onChanged: (selected) => onChanged(selected ?? ''),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      items: [
        DropdownMenuItem<String>(value: '', child: Text(emptyLabel)),
        ...options.map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.options,
    required this.emptyLabel,
    required this.onChanged,
    this.customValue,
    this.customLabel,
    this.optionLabels = const {},
  });

  final String value;
  final String label;
  final List<String> options;
  final String emptyLabel;
  final ValueChanged<String> onChanged;
  final String? customValue;
  final String? customLabel;
  final Map<String, String> optionLabels;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolvedValue = options.contains(value) || value == customValue
        ? value
        : '';

    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      onChanged: (selected) => onChanged(selected ?? ''),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      items: [
        DropdownMenuItem<String>(value: '', child: Text(emptyLabel)),
        ...options.map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(optionLabels[item] ?? item),
          ),
        ),
        if (customValue != null && customLabel != null)
          DropdownMenuItem<String>(
            value: customValue,
            child: Text(customLabel!),
          ),
      ],
    );
  }
}

class _LocationTypeField extends StatelessWidget {
  const _LocationTypeField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
      decoration: InputDecoration(
        labelText: 'Lugar',
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      items: options
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: palette.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border),
          ),
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_rounded, size: 18)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
        child: Text(
          value == null ? 'Sin fecha' : _formatDate(value!),
          style: TextStyle(
            color: value == null ? palette.textMuted : palette.textStrong,
          ),
        ),
      ),
    );
  }
}

class _ProductDraft {
  const _ProductDraft({
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.supplierName,
    required this.locationName,
    required this.locationType,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minStock,
    required this.pricingRules,
    required this.expirationDate,
    required this.imageUrl,
  });

  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String supplierName;
  final String locationName;
  final String locationType;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final ProductPricingRules pricingRules;
  final DateTime? expirationDate;
  final String imageUrl;
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
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
