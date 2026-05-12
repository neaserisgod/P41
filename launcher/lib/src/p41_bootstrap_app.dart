import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'p41_bootstrap_controller.dart';
import 'p41_update_manifest.dart';

class P41BootstrapApp extends StatelessWidget {
  const P41BootstrapApp({super.key, required this.updateMode});

  final bool updateMode;

  @override
  Widget build(BuildContext context) {
    const shell = Color(0xFFF5F1E8);
    const surface = Colors.white;
    const ink = Color(0xFF171717);
    const muted = Color(0xFF6D6A63);
    const gold = Color(0xFFC9972F);
    const border = Color(0xFFE7DDC7);
    const danger = Color(0xFFB42318);

    return MaterialApp(
      title: 'P41 Bootstrap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: shell,
        colorScheme: const ColorScheme.light(
          primary: gold,
          secondary: gold,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: ink,
        ),
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.questrial(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: GoogleFonts.questrial(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: GoogleFonts.nunitoSans(
            fontSize: 13,
            height: 1.35,
            color: muted,
          ),
        ),
        dividerColor: border,
      ),
      home: _P41BootstrapScreen(
        controller: P41BootstrapController(updateMode: updateMode)..bootstrap(),
      ),
    );
  }
}

class _P41BootstrapScreen extends StatefulWidget {
  const _P41BootstrapScreen({required this.controller});

  final P41BootstrapController controller;

  @override
  State<_P41BootstrapScreen> createState() => _P41BootstrapScreenState();
}

class _P41BootstrapScreenState extends State<_P41BootstrapScreen> {
  P41BootstrapController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 32,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _P41Badge(color: palette.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.headline,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bootstrap local y recursos globales',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (controller.isBusy)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: palette.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    controller.statusLine,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: controller.stage == P41BootstrapStage.failed
                          ? palette.error
                          : const Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: 'Instalada',
                          value:
                              controller.installedAppVersion ?? 'Sin detectar',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          label: 'Publicada',
                          value:
                              controller.manifest?.appVersion ?? 'Sin publicar',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StagePanel(controller: controller),
                  if (controller.errorMessage case final error?) ...[
                    const SizedBox(height: 14),
                    Text(
                      error,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: controller.progress,
                      backgroundColor: const Color(0xFFF1E7D2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.stage == P41BootstrapStage.failed)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: controller.isBusy
                                ? null
                                : controller.bootstrap,
                            child: const Text('Reintentar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: controller.closeLauncher,
                          child: const Text('Cerrar'),
                        ),
                      ],
                    )
                  else
                    Text(
                      controller.footerLine,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _P41Badge extends StatelessWidget {
  const _P41Badge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'P',
              style: GoogleFonts.nunitoSans(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF171717),
              ),
            ),
            TextSpan(
              text: '41',
              style: GoogleFonts.nunitoSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _StagePanel extends StatelessWidget {
  const _StagePanel({required this.controller});

  final P41BootstrapController controller;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, bool active})>[
      (
        label: 'App local ${controller.hasInstalledApp ? 'detectada' : 'pendiente'}',
        active: controller.stage.index >= P41BootstrapStage.inspecting.index,
      ),
      (
        label: 'Versión remota verificada',
        active: controller.stage.index >=
            P41BootstrapStage.checkingManifest.index,
      ),
      (
        label: 'Binarios sincronizados',
        active: controller.stage.index >= P41BootstrapStage.syncingApp.index,
      ),
      (
        label: 'Catálogo e imágenes listos',
        active: controller.stage.index >=
            P41BootstrapStage.syncingResources.index,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Row(
              children: [
                Icon(
                  items[index].active
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: items[index].active
                      ? const Color(0xFFC9972F)
                      : const Color(0xFFB8B3A8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[index].label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: items[index].active
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: const Color(0xFF171717),
                    ),
                  ),
                ),
              ],
            ),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
