import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/widgets/p41_logo.dart';

class SetupAdminScreen extends StatefulWidget {
  const SetupAdminScreen({
    super.key,
    required this.onCreateAccount,
    this.errorMessage,
  });

  final Future<void> Function({
    required String accountName,
    required String ownerEmail,
    required String password,
  }) onCreateAccount;
  final String? errorMessage;

  @override
  State<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends State<SetupAdminScreen> {
  final _accountController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AccessScaffold(
      eyebrow: 'Configuracion inicial',
      title: 'Prepará el local y arrancá.',
      subtitle: 'Dejá creada la cuenta principal y seguí con la operación.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crear cuenta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completá estos tres datos y seguí.',
            style: TextStyle(
              fontSize: 13,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          AccessInputField(controller: _accountController, label: 'Nombre del negocio'),
          const SizedBox(height: 12),
          AccessInputField(controller: _emailController, label: 'Email del administrador'),
          const SizedBox(height: 12),
          AccessInputField(
            controller: _passwordController,
            label: 'Clave de acceso',
            obscureText: true,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.errorMessage!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.danger,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      await widget.onCreateAccount(
                        accountName: _accountController.text.trim().isEmpty
                            ? 'HorsePos Cuenta'
                            : _accountController.text.trim(),
                        ownerEmail: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                      if (!mounted) {
                        return;
                      }
                      setState(() => _isSubmitting = false);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isSubmitting ? 'Creando...' : 'Crear cuenta',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccessScaffold extends StatelessWidget {
  const AccessScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.shell,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180 && constraints.maxHeight >= 760;
          final compact = constraints.maxWidth < 980 || constraints.maxHeight < 820;
          final horizontalPadding = constraints.maxWidth < 720 ? 18.0 : 28.0;
          final verticalPadding = constraints.maxHeight < 780 ? 18.0 : 28.0;

          return Stack(
            children: [
              Positioned(
                top: -100,
                left: -60,
                child: Container(
                  width: compact ? 220 : 320,
                  height: compact ? 220 : 320,
                  decoration: BoxDecoration(
                    color: palette.accentSoft.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(160),
                  ),
                ),
              ),
              Positioned(
                right: -80,
                bottom: -100,
                child: Container(
                  width: compact ? 210 : 280,
                  height: compact ? 210 : 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(140),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: wide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _AccessHero(
                                      eyebrow: eyebrow,
                                      title: title,
                                      subtitle: subtitle,
                                      compact: false,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: _AccessPanel(
                                      compact: compact,
                                      child: child,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                _AccessHero(
                                  eyebrow: eyebrow,
                                  title: title,
                                  subtitle: subtitle,
                                  compact: true,
                                ),
                                const SizedBox(height: 18),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 620),
                                  child: _AccessPanel(
                                    compact: true,
                                    child: child,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccessHero extends StatelessWidget {
  const _AccessHero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.all(compact ? 22 : 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.78 : 0.68),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              eyebrow,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
                color: palette.warning,
              ),
            ),
          ),
          SizedBox(height: compact ? 18 : 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              P41Logo(size: compact ? 34 : 44),
              const SizedBox(width: 14),
              Text(
                'HorsePos',
                style: TextStyle(
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 30 : 52,
              height: compact ? 1.02 : 0.96,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                height: 1.4,
                color: palette.textMuted,
              ),
            ),
          ),
          SizedBox(height: compact ? 20 : 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _HeroChip(icon: Icons.point_of_sale_rounded, label: 'Venta directa'),
              const _HeroChip(icon: Icons.inventory_2_rounded, label: 'Stock claro'),
              const _HeroChip(icon: Icons.lock_clock_rounded, label: 'Caja simple'),
              if (!compact) const _HeroChip(icon: Icons.cloud_off_rounded, label: 'Trabajo local'),
            ],
          ),
          SizedBox(height: compact ? 18 : 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _HeroMetric(value: '3 pasos', label: 'para entrar y vender'),
              _HeroMetric(value: '1 equipo', label: 'con datos guardados'),
              _HeroMetric(value: '0 fricción', label: 'si la cuenta ya existe'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.warning),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class AccessInputField extends StatelessWidget {
  const AccessInputField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
