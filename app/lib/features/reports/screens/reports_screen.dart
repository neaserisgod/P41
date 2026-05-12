import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/state/catalog_controller.dart';
import '../../cash_management/state/cash_controller.dart';
import '../../pos/state/sales_controller.dart';
import '../../providers/state/providers_controller.dart';
import '../models/report_models.dart';
import '../view_models/reports_view_model.dart';
import '../widgets/report_margin_section.dart';
import '../widgets/report_summary_section.dart';
import '../widgets/report_top_products_section.dart';
import '../widgets/report_transactions_section.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_section_list.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.activeBranchName,
    required this.catalogController,
    required this.providersController,
    required this.salesController,
    required this.cashController,
  });

  final String activeBranchName;
  final CatalogController catalogController;
  final ProvidersController providersController;
  final SalesController salesController;
  final CashController cashController;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportsViewModel(
      catalogController: widget.catalogController,
      providersController: widget.providersController,
      salesController: widget.salesController,
      cashController: widget.cashController,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('reports-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 1180 || constraints.maxHeight < 760;
            return Padding(
              padding: EdgeInsets.all(stacked ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportsHeader(
                    activeBranchName: widget.activeBranchName,
                    period: _viewModel.selectedPeriod,
                    onSelectPeriod: _viewModel.selectPeriod,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: stacked
                        ? Column(
                            children: [
                              SizedBox(
                                height: 184,
                                child: ReportsSectionList(
                                  selectedSection: _viewModel.selectedSection,
                                  onSelect: _viewModel.selectSection,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _ReportWorkspace(viewModel: _viewModel),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 24,
                                child: ReportsSectionList(
                                  selectedSection: _viewModel.selectedSection,
                                  onSelect: _viewModel.selectSection,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 76,
                                child: _ReportWorkspace(viewModel: _viewModel),
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

class _ReportWorkspace extends StatelessWidget {
  const _ReportWorkspace({required this.viewModel});

  final ReportsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    switch (viewModel.selectedSection) {
      case ReportsSection.summary:
        return ReportSummarySection(snapshot: viewModel.summary);
      case ReportsSection.purchasesMargin:
        if (!viewModel.hasSupplierReports) {
          return const _ReportsEmptyState(
            title: 'Sin compras en el período',
            message:
                'Todavía no hay pedidos recibidos o pendientes para construir margen por proveedor.',
          );
        }
        return ReportMarginSection(
          reports: viewModel.supplierReports,
          selectedSupplierId: viewModel.selectedSupplier.id,
          onSelectSupplier: viewModel.selectSupplier,
        );
      case ReportsSection.transactions:
        if (!viewModel.hasTransactions) {
          return const _ReportsEmptyState(
            title: 'Sin ventas en el período',
            message: 'Cuando entren ventas reales, se van a listar acá.',
          );
        }
        return ReportTransactionsSection(
          transactions: viewModel.transactions,
          selectedTransactionId: viewModel.selectedTransaction.id,
          onSelectTransaction: viewModel.selectTransaction,
          onVoidSelected: () {
            unawaited(viewModel.voidSelectedTransaction());
          },
        );
      case ReportsSection.topProducts:
        if (!viewModel.hasTopProducts) {
          return const _ReportsEmptyState(
            title: 'Sin ranking todavía',
            message:
                'Faltan ventas con detalle de productos dentro del período seleccionado.',
          );
        }
        return ReportTopProductsSection(products: viewModel.topProducts);
    }
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 32,
                color: palette.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
