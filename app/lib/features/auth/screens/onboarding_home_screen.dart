import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app.dart';

class OnboardingHomeScreen extends StatelessWidget {
  const OnboardingHomeScreen({
    super.key,
    required this.businessName,
    required this.branchName,
    required this.showBranchName,
    required this.hasTeam,
    required this.productCount,
    required this.hasOpenShift,
    required this.onRenameBranch,
    required this.onOpenTeam,
    required this.onOpenProducts,
    required this.onOpenCash,
    required this.onOpenPos,
  });

  final String businessName;
  final String branchName;
  final bool showBranchName;
  final bool hasTeam;
  final int productCount;
  final bool hasOpenShift;
  final Future<void> Function() onRenameBranch;
  final VoidCallback onOpenTeam;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenCash;
  final VoidCallback onOpenPos;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final readyToSell = hasTeam && productCount > 0 && hasOpenShift;

    return Container(
      color: palette.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: readyToSell ? palette.success.withValues(alpha: 0.12) : palette.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          readyToSell ? 'Listo para vender' : 'Falta muy poco',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: readyToSell ? palette.success : palette.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        businessName,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: palette.textStrong,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        readyToSell
                            ? (showBranchName
                                ? 'Todo listo para vender desde $branchName.'
                                : 'Todo listo para vender.')
                            : (showBranchName
                                ? 'Completá lo mínimo para arrancar desde $branchName.'
                                : 'Completá lo mínimo para arrancar.'),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatChip(
                            label: 'Local',
                            value: branchName,
                          ),
                          _StatChip(
                            label: 'Equipo',
                            value: hasTeam ? 'Activo' : 'Pendiente',
                          ),
                          _StatChip(
                            label: 'Productos',
                            value: '$productCount',
                          ),
                          _StatChip(
                            label: 'Caja',
                            value: hasOpenShift ? 'Abierta' : 'Cerrada',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: readyToSell ? onOpenPos : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.warning,
                            foregroundColor: palette.textStrong,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.point_of_sale_rounded),
                          label: const Text(
                            'Ir a vender',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onOpenProducts,
                          icon: const Icon(Icons.inventory_2_rounded),
                          label: const Text('Ver productos'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.15,
              children: [
                _StepCard(
                  title: 'Local',
                  subtitle: showBranchName
                      ? 'Revisá cómo querés que aparezca esta sucursal.'
                      : 'Poné el nombre con el que vas a trabajar todos los días.',
                  done: branchName.trim().isNotEmpty,
                  actionLabel: 'Cambiar nombre',
                  onTap: onRenameBranch,
                ),
                _StepCard(
                  title: 'Equipo',
                  subtitle: hasTeam ? 'Ya tenés al menos una persona para operar.' : 'Creá o revisá quién va a usar el sistema.',
                  done: hasTeam,
                  actionLabel: 'Abrir equipo',
                  onTap: onOpenTeam,
                ),
                _StepCard(
                  title: 'Productos',
                  subtitle: productCount > 0 ? '$productCount productos cargados.' : 'Cargá al menos un producto para empezar a vender.',
                  done: productCount > 0,
                  actionLabel: 'Abrir productos',
                  onTap: onOpenProducts,
                ),
                _StepCard(
                  title: 'Caja',
                  subtitle: hasOpenShift ? 'La caja ya está abierta.' : 'Abrí caja para habilitar el punto de venta.',
                  done: hasOpenShift,
                  actionLabel: 'Abrir caja',
                  onTap: onOpenCash,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final String actionLabel;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? palette.success.withValues(alpha: 0.35) : palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done ? palette.success.withValues(alpha: 0.14) : palette.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.arrow_forward_rounded,
              color: done ? palette.success : palette.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
