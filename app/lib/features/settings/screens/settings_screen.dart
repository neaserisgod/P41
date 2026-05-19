import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/product_pricing_rules.dart';
import '../../../app/services/local_backup_service.dart';
import '../../../app/state/catalog_controller.dart';
import '../../../app/state/session_controller.dart';

enum SettingsSection {
  local('Negocio'),
  people('Equipo'),
  sales('Operación'),
  system('Cuenta');

  const SettingsSection(this.label);
  final String label;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.sessionController,
    required this.catalogController,
    required this.onOpenUsers,
    required this.onOpenBranches,
    required this.onRestoreBackup,
  });

  final SessionController sessionController;
  final CatalogController catalogController;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenBranches;
  final VoidCallback onRestoreBackup;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsSection _selectedSection = SettingsSection.local;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('settings-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: widget.sessionController,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajustes del local y de la operación diaria.',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 260,
                        child: _SettingsSectionList(
                          selectedSection: _selectedSection,
                          hasSingleBranch: widget.sessionController.hasSingleBranch,
                          onSelect: (section) => setState(() => _selectedSection = section),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SettingsPanel(
                          section: _selectedSection,
                          sessionController: widget.sessionController,
                          catalogController: widget.catalogController,
                          onOpenUsers: widget.onOpenUsers,
                          onOpenBranches: widget.onOpenBranches,
                          onRestoreBackup: widget.onRestoreBackup,
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
    );
  }
}

class _SettingsSectionList extends StatelessWidget {
  const _SettingsSectionList({
    required this.selectedSection,
    required this.hasSingleBranch,
    required this.onSelect,
  });

  final SettingsSection selectedSection;
  final bool hasSingleBranch;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sections = [
      SettingsSection.local,
      SettingsSection.people,
      SettingsSection.sales,
      SettingsSection.system,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: sections.length,
        separatorBuilder: (context, index) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final section = sections[index];
          final selected = section == selectedSection;
          final subtitle = switch (section) {
            SettingsSection.local => hasSingleBranch ? 'Nombre comercial del local.' : 'Locales, nombres y sucursales.',
            SettingsSection.people => 'Quién puede entrar y operar.',
            SettingsSection.sales => 'Reglas base de operación diaria.',
            SettingsSection.system => 'Cuenta activa, respaldo y estado general.',
          };

          return InkWell(
            onTap: () => onSelect(section),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? palette.accentSoft.withValues(alpha: 0.72) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.section,
    required this.sessionController,
    required this.catalogController,
    required this.onOpenUsers,
    required this.onOpenBranches,
    required this.onRestoreBackup,
  });

  final SettingsSection section;
  final SessionController sessionController;
  final CatalogController catalogController;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenBranches;
  final VoidCallback onRestoreBackup;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case SettingsSection.local:
        return _LocalSettingsPanel(
          sessionController: sessionController,
          onOpenBranches: onOpenBranches,
        );
      case SettingsSection.people:
        return _PeopleSettingsPanel(
          sessionController: sessionController,
          onOpenUsers: onOpenUsers,
        );
      case SettingsSection.sales:
        return _SalesSettingsPanel(
          catalogController: catalogController,
        );
      case SettingsSection.system:
        return _SystemSettingsPanel(
          sessionController: sessionController,
          onRestoreBackup: onRestoreBackup,
        );
    }
  }
}

class _LocalSettingsPanel extends StatefulWidget {
  const _LocalSettingsPanel({
    required this.sessionController,
    required this.onOpenBranches,
  });

  final SessionController sessionController;
  final VoidCallback onOpenBranches;

  @override
  State<_LocalSettingsPanel> createState() => _LocalSettingsPanelState();
}

class _LocalSettingsPanelState extends State<_LocalSettingsPanel> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.sessionController.activeBranch?.name ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _LocalSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latestName = widget.sessionController.activeBranch?.name ?? '';
    if (_nameController.text != latestName) {
      _nameController.text = latestName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final session = widget.sessionController;
    final branch = session.activeBranch;

    return _SettingsCard(
      title: session.hasSingleBranch ? 'Nombre del local' : 'Sucursal activa',
      subtitle: session.hasSingleBranch
          ? 'Este nombre se usa en toda la app.'
          : 'Podés editar el nombre del local actual o administrar sucursales.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: session.hasSingleBranch ? 'Nombre del local' : 'Nombre de la sucursal',
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: branch == null
                    ? null
                    : () => widget.sessionController.renameActiveBranch(_nameController.text.trim()),
                child: const Text('Guardar nombre'),
              ),
              if (!session.hasSingleBranch)
                OutlinedButton(
                  onPressed: widget.onOpenBranches,
                  child: const Text('Administrar sucursales'),
                ),
            ],
          ),
          if (session.sessionError != null) ...[
            const SizedBox(height: 12),
            Text(
              session.sessionError!,
              style: TextStyle(
                color: palette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeopleSettingsPanel extends StatelessWidget {
  const _PeopleSettingsPanel({
    required this.sessionController,
    required this.onOpenUsers,
  });

  final SessionController sessionController;
  final VoidCallback onOpenUsers;

  @override
  Widget build(BuildContext context) {
    final activeUsers = sessionController.allUsers.where((user) => user.isActive).toList();

    return _SettingsCard(
      title: 'Equipo',
      subtitle: 'Personas habilitadas para entrar y operar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeUsers.isEmpty
                ? 'Todavía no hay personas activas.'
                : '${activeUsers.length} personas activas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeUsers
                .map(
                  (user) => Chip(
                    label: Text('${user.name} • ${user.role}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onOpenUsers,
            child: const Text('Administrar equipo'),
          ),
        ],
      ),
    );
  }
}

class _SalesSettingsPanel extends StatefulWidget {
  const _SalesSettingsPanel({
    required this.catalogController,
  });

  final CatalogController catalogController;

  @override
  State<_SalesSettingsPanel> createState() => _SalesSettingsPanelState();
}

class _SalesSettingsPanelState extends State<_SalesSettingsPanel> {
  late final TextEditingController _markupController;
  late final TextEditingController _bonusController;
  late final TextEditingController _vatController;
  late bool _bonusEnabled;
  late bool _vatEnabled;

  @override
  void initState() {
    super.initState();
    final defaults = widget.catalogController.pricingDefaults;
    _markupController = TextEditingController(text: _formatPercent(defaults.markupPercent));
    _bonusController = TextEditingController(text: _formatPercent(defaults.bonusPercent));
    _vatController = TextEditingController(text: _formatPercent(defaults.vatPercent));
    _bonusEnabled = defaults.bonusEnabled;
    _vatEnabled = defaults.vatEnabled;
  }

  @override
  void dispose() {
    _markupController.dispose();
    _bonusController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = widget.catalogController.pricingDefaults;
    return _SettingsCard(
      title: 'Venta diaria',
      subtitle: 'Definí cómo se calcula el precio por defecto al cargar o editar productos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ValueRow(label: 'Regla actual', value: _pricingSummary(defaults)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SettingsInput(
                  controller: _markupController,
                  label: 'Markup / margen %',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SettingsInput(
                  controller: _bonusController,
                  label: 'Bonificación %',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SettingsInput(
                  controller: _vatController,
                  label: 'IVA %',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Usar bonificación'),
                selected: _bonusEnabled,
                onSelected: (value) => setState(() => _bonusEnabled = value),
              ),
              FilterChip(
                label: const Text('Usar IVA'),
                selected: _vatEnabled,
                onSelected: (value) => setState(() => _vatEnabled = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar cálculo'),
              ),
              OutlinedButton(
                onPressed: _reset,
                child: const Text('Usar valores base'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SettingBullet(text: 'Bonificación suma margen operativo: mejora tu costo, pero no baja el precio de venta.'),
          const _SettingBullet(text: 'IVA y bonificación se pueden activar o desactivar también dentro de cada producto.'),
          const _SettingBullet(text: 'En el modal de producto, cambiar costo recalcula precio final y cambiar precio final recalcula costo.'),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final rules = ProductPricingRules(
      markupPercent: _parse(_markupController.text, fallback: ProductPricingRules.defaults.markupPercent),
      bonusPercent: _parse(_bonusController.text, fallback: ProductPricingRules.defaults.bonusPercent),
      bonusEnabled: _bonusEnabled,
      vatPercent: _parse(_vatController.text, fallback: ProductPricingRules.defaults.vatPercent),
      vatEnabled: _vatEnabled,
    );
    await widget.catalogController.updatePricingDefaults(rules);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cálculo por defecto guardado.')),
    );
    setState(() {});
  }

  void _reset() {
    final defaults = ProductPricingRules.defaults;
    setState(() {
      _markupController.text = _formatPercent(defaults.markupPercent);
      _bonusController.text = _formatPercent(defaults.bonusPercent);
      _vatController.text = _formatPercent(defaults.vatPercent);
      _bonusEnabled = defaults.bonusEnabled;
      _vatEnabled = defaults.vatEnabled;
    });
  }

  double _parse(String raw, {required double fallback}) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? fallback;
  }

  String _pricingSummary(ProductPricingRules rules) {
    final bonus = rules.bonusEnabled ? ' + bonif ${_formatPercent(rules.bonusPercent)}%' : '';
    final vat = rules.vatEnabled ? ' + IVA ${_formatPercent(rules.vatPercent)}%' : '';
    return 'Costo + markup ${_formatPercent(rules.markupPercent)}%$bonus$vat';
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
}

class _SystemSettingsPanel extends StatelessWidget {
  const _SystemSettingsPanel({
    required this.sessionController,
    required this.onRestoreBackup,
  });

  final SessionController sessionController;
  final VoidCallback onRestoreBackup;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Sistema',
      subtitle: 'Datos generales de la cuenta actual.',
      child: _SystemPanelBody(
        sessionController: sessionController,
        onRestoreBackup: onRestoreBackup,
      ),
    );
  }
}

class _SystemPanelBody extends StatefulWidget {
  const _SystemPanelBody({
    required this.sessionController,
    required this.onRestoreBackup,
  });

  final SessionController sessionController;
  final VoidCallback onRestoreBackup;

  @override
  State<_SystemPanelBody> createState() => _SystemPanelBodyState();
}

class _SystemPanelBodyState extends State<_SystemPanelBody> {
  final LocalBackupService _backupService = LocalBackupService();
  bool _isWorking = false;
  LocalBackupSummary? _latestBackup;
  List<LocalBackupSummary> _backups = const [];

  String get _backupScopeKey =>
      widget.sessionController.account?.ownerEmail ??
      widget.sessionController.accountName ??
      'default';

  String get _backupAccountName =>
      widget.sessionController.accountName ?? 'p41';

  @override
  void initState() {
    super.initState();
    _loadLatestBackup();
  }

  Future<void> _loadLatestBackup() async {
    final latest = await _backupService.latestBackup(
      scopeKey: _backupScopeKey,
    );
    final backups = await _backupService.listBackups(
      scopeKey: _backupScopeKey,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _latestBackup = latest;
      _backups = backups;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _isWorking = true);
    final summary = await _backupService.createBackup(
      scopeKey: _backupScopeKey,
      accountName: _backupAccountName,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _latestBackup = summary;
      _backups = [summary, ..._backups.where((item) => item.path != summary.path)];
      _isWorking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Respaldo creado en ${summary.fileName}')),
    );
  }

  Future<void> _restoreBackup(String path) async {
    setState(() => _isWorking = true);
    final restored = await _backupService.restoreBackup(path);
    final latest = await _backupService.latestBackup(
      scopeKey: _backupScopeKey,
    );
    final backups = await _backupService.listBackups(
      scopeKey: _backupScopeKey,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _latestBackup = latest;
      _backups = backups;
      _isWorking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Respaldo restaurado.'
              : 'No hay respaldo para restaurar.',
        ),
      ),
    );
    if (restored) {
      widget.onRestoreBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValueRow(label: 'Cuenta', value: widget.sessionController.accountName ?? '-'),
        _ValueRow(label: 'Email', value: widget.sessionController.account?.ownerEmail ?? '-'),
        _ValueRow(label: 'Usuarios', value: '${widget.sessionController.allUsers.length}'),
        _ValueRow(label: 'Locales', value: '${widget.sessionController.allBranches.length}'),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 18),
        Text(
          'Respaldo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _latestBackup == null
              ? 'Todavía no hay respaldo creado en este equipo.'
              : 'Último respaldo: ${_latestBackup!.fileName}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Modo local: los respaldos quedan sólo en este equipo y dentro del SQLite exportado.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Estos respaldos quedan asociados a la cuenta ${widget.sessionController.account?.ownerEmail ?? '-'} en este equipo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: _isWorking ? null : _createBackup,
              child: Text(_isWorking ? 'Procesando...' : 'Crear respaldo'),
            ),
            OutlinedButton(
              onPressed: _isWorking || _latestBackup == null
                  ? null
                  : () => _restoreBackup(_latestBackup!.path),
              child: const Text('Restaurar último'),
            ),
          ],
        ),
        if (_backups.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Respaldos recientes',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          ..._backups.take(5).map(
            (backup) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      backup.fileName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _isWorking ? null : () => _restoreBackup(backup.path),
                    child: const Text('Restaurar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
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
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: palette.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsInput extends StatelessWidget {
  const _SettingsInput({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }
}

class _SettingBullet extends StatelessWidget {
  const _SettingBullet({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: palette.warning,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: palette.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
