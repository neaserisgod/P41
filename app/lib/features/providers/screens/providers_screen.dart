import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app.dart';
import '../models/provider_record.dart';
import '../state/providers_controller.dart';
import '../widgets/provider_detail_panel.dart';
import '../widgets/provider_form_dialog.dart';
import '../widgets/providers_header.dart';
import '../widgets/providers_list.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({
    super.key,
    required this.controller,
  });

  final ProvidersController controller;

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  ProviderDetailSection _section = ProviderDetailSection.summary;

  Future<void> _copyCurrentDraft() async {
    final text = widget.controller.draftMessageForSelectedProvider();
    if (text.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido copiado para enviar'),
      ),
    );
  }

  Future<void> _openProviderForm({ProviderRecord? record}) async {
    final result = await showDialog<ProviderFormResult>(
      context: context,
      builder: (context) => ProviderFormDialog(initialRecord: record),
    );
    if (result == null) {
      return;
    }
    if (record == null) {
      await widget.controller.createProvider(
        name: result.name,
        contact: result.contact,
        phone: result.phone,
        email: result.email,
        category: result.category,
        orderDays: result.orderDays,
        deliveryDays: result.deliveryDays,
        isActive: result.isActive,
      );
      return;
    }
    await widget.controller.updateProvider(
      record.copyWith(
        name: result.name,
        contact: result.contact,
        phone: result.phone,
        email: result.email,
        category: result.category,
        isActive: result.isActive,
        orderDays: result.orderDays,
        deliveryDays: result.deliveryDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selectedProvider = widget.controller.selectedProviderOrNull;

    return Container(
      key: const ValueKey('providers-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1180 || constraints.maxHeight < 760;
            return Padding(
              padding: EdgeInsets.all(stacked ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProvidersHeader(
                    onCreate: () => _openProviderForm(),
                    count: widget.controller.providers.length,
                  ),
                  const SizedBox(height: 14),
                  if (widget.controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        widget.controller.errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.danger,
                        ),
                      ),
                    ),
                  Expanded(
                    child: widget.controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : widget.controller.providers.isEmpty || selectedProvider == null
                            ? Center(
                                child: Text(
                                  'No hay proveedores.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                ),
                              )
                            : stacked
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: 220,
                                        child: ProvidersList(
                                          records: widget.controller.providers,
                                          selectedId: selectedProvider.id,
                                          onSelect: (record) {
                                            widget.controller.selectProvider(record.id);
                                            setState(() {
                                              _section = ProviderDetailSection.summary;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ProviderDetailPanel(
                                          record: selectedProvider,
                                          section: _section,
                                          onSelectSection: (section) {
                                            setState(() => _section = section);
                                          },
                                          productCount: widget.controller.productCountFor(selectedProvider.id),
                                          balance: widget.controller.balanceFor(selectedProvider.id),
                                          lastDelivery: widget.controller.lastDeliveryFor(selectedProvider.id),
                                          catalog: widget.controller.selectedCatalog,
                                          orders: widget.controller.selectedOrders,
                                          draftItems: widget.controller.draftItems,
                                          draftUnits: widget.controller.draftUnits,
                                          draftTotal: widget.controller.draftTotal,
                                          onAddToDraft: widget.controller.addToDraft,
                                          onIncreaseDraftItem: widget.controller.increaseDraftItem,
                                          onDecreaseDraftItem: widget.controller.decreaseDraftItem,
                                          onCreateOrder: widget.controller.createOrder,
                                          onCopyDraft: _copyCurrentDraft,
                                          onReceiveOrder: widget.controller.receiveOrder,
                                          onEditProvider: () => _openProviderForm(record: selectedProvider),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        flex: 40,
                                        child: ProvidersList(
                                          records: widget.controller.providers,
                                          selectedId: selectedProvider.id,
                                          onSelect: (record) {
                                            widget.controller.selectProvider(record.id);
                                            setState(() {
                                              _section = ProviderDetailSection.summary;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 60,
                                        child: ProviderDetailPanel(
                                          record: selectedProvider,
                                          section: _section,
                                          onSelectSection: (section) {
                                            setState(() => _section = section);
                                          },
                                          productCount: widget.controller.productCountFor(selectedProvider.id),
                                          balance: widget.controller.balanceFor(selectedProvider.id),
                                          lastDelivery: widget.controller.lastDeliveryFor(selectedProvider.id),
                                          catalog: widget.controller.selectedCatalog,
                                          orders: widget.controller.selectedOrders,
                                          draftItems: widget.controller.draftItems,
                                          draftUnits: widget.controller.draftUnits,
                                          draftTotal: widget.controller.draftTotal,
                                          onAddToDraft: widget.controller.addToDraft,
                                          onIncreaseDraftItem: widget.controller.increaseDraftItem,
                                          onDecreaseDraftItem: widget.controller.decreaseDraftItem,
                                          onCreateOrder: widget.controller.createOrder,
                                          onCopyDraft: _copyCurrentDraft,
                                          onReceiveOrder: widget.controller.receiveOrder,
                                          onEditProvider: () => _openProviderForm(record: selectedProvider),
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
