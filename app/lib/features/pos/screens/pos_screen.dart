import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/catalog_product.dart';
import '../../../app/models/session_context.dart';
import '../../../app/state/catalog_controller.dart';
import '../../../app/widgets/desktop_viewport.dart';
import '../../cash_management/models/cash_shift.dart';
import '../models/sale_models.dart';
import '../state/sales_controller.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_category_strip.dart';
import '../widgets/pos_header.dart';
import '../widgets/pos_product_grid.dart';
import '../widgets/pos_search_bar.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({
    super.key,
    required this.shift,
    required this.activeUserName,
    required this.activeBranchName,
    required this.onCashAction,
    required this.catalogController,
    required this.salesController,
    required this.activeUser,
    required this.activeBranch,
    required this.onCheckout,
  });

  final CashShift shift;
  final String activeUserName;
  final String activeBranchName;
  final VoidCallback onCashAction;
  final CatalogController catalogController;
  final SalesController salesController;
  final SessionUser activeUser;
  final SessionBranch activeBranch;
  final ValueChanged<SaleTransaction> onCheckout;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.salesController.query,
    );
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('pos-screen'),
      color: palette.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.viewport;
          final roomy = constraints.maxWidth >= 1500;
          final stacked =
              constraints.maxWidth < 1180 ||
              (constraints.maxWidth < 1360 && constraints.maxHeight < 760);
          final outerPadding = roomy ? 26.0 : viewport.pagePadding;

          return AnimatedBuilder(
            animation: Listenable.merge([
              widget.catalogController,
              widget.salesController,
            ]),
            builder: (context, _) {
              final categories = widget.salesController.categoriesFor(
                widget.catalogController.activeProducts,
              );
              final visibleProducts = widget.salesController.visibleProducts(
                widget.catalogController.activeProducts,
              );

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(outerPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosHeader(
                          shift: widget.shift,
                          activeUserName: widget.activeUserName,
                        ),
                        SizedBox(height: stacked ? 12 : 18),
                        Expanded(
                          child: stacked
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _ProductPane(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        salesController: widget.salesController,
                                        categories: categories,
                                        visibleProducts: visibleProducts,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: viewport.shortHeight ? 276 : 300,
                                      child: _buildCartPanel(context),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 60,
                                      child: _ProductPane(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        salesController: widget.salesController,
                                        categories: categories,
                                        visibleProducts: visibleProducts,
                                      ),
                                    ),
                                    SizedBox(width: roomy ? 22 : 18),
                                    Expanded(
                                      flex: 40,
                                      child: _buildCartPanel(context),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.shift.isOpen)
                    Positioned.fill(
                      child: Container(
                        color: palette.surface.withValues(alpha: 0.76),
                        padding: EdgeInsets.all(outerPadding),
                        child: Center(
                          child: _ClosedCashState(
                            branchName: widget.activeBranchName,
                            registerName: widget.shift.registerName,
                            onOpenCash: widget.onCashAction,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCartPanel(BuildContext context) {
    return PosCartPanel(
      enabled: widget.shift.isOpen,
      isProcessing: widget.salesController.isCheckingOut,
      items: widget.salesController.cartItems,
      cartUnits: widget.salesController.cartUnits,
      subtotal: widget.salesController.subtotal,
      discount: widget.salesController.discount,
      total: widget.salesController.total,
      onIncreaseItem: widget.salesController.increaseItem,
      onDecreaseItem: widget.salesController.decreaseItem,
      onCheckout: (paymentMethod) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final transaction = await widget.salesController.checkout(
            paymentMethod: paymentMethod,
            cashier: widget.activeUser,
            branch: widget.activeBranch,
            shift: widget.shift,
          );
          if (transaction != null) {
            widget.onCheckout(transaction);
            if (mounted) {
              final message =
                  widget.salesController.errorMessage ?? 'Venta registrada.';
              messenger.showSnackBar(SnackBar(content: Text(message)));
            }
          } else if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('La venta no se pudo guardar. Revisá caja y productos del carrito.'),
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('La venta falló antes de registrarse.'),
              ),
            );
          }
        }
      },
    );
  }
}

class _ProductPane extends StatelessWidget {
  const _ProductPane({
    required this.controller,
    required this.focusNode,
    required this.salesController,
    required this.categories,
    required this.visibleProducts,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SalesController salesController;
  final List<String> categories;
  final List<CatalogProduct> visibleProducts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.viewport;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosSearchBar(
              controller: controller,
              focusNode: focusNode,
              onChanged: salesController.setQuery,
              onSubmit: (_) {
                if (visibleProducts.isEmpty) {
                  return;
                }
                salesController.addProduct(visibleProducts.first);
                focusNode.requestFocus();
              },
            ),
            SizedBox(height: viewport.shortHeight ? 10 : 12),
            SizedBox(
              height: viewport.shortHeight ? 40 : 44,
              child: PosCategoryStrip(
                categories: categories,
                selectedCategory: salesController.selectedCategory,
                onSelect: salesController.selectCategory,
              ),
            ),
            SizedBox(height: viewport.shortHeight ? 10 : 12),
            Expanded(
              child: PosProductGrid(
                products: visibleProducts,
                onSelectProduct: salesController.addProduct,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClosedCashState extends StatelessWidget {
  const _ClosedCashState({
    required this.branchName,
    required this.registerName,
    required this.onOpenCash,
  });

  final String branchName;
  final String registerName;
  final VoidCallback onOpenCash;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: palette.warning,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Caja cerrada',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            branchName.isEmpty
                ? 'Abrí $registerName para habilitar el punto de venta.'
                : 'Abrí $registerName en $branchName para habilitar el punto de venta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.textMuted),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onOpenCash,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: const Text(
              'Abrir caja',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
