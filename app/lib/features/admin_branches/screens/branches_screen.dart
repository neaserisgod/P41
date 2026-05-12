import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/session_context.dart';
import '../../../app/state/session_controller.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String? _selectedBranchId;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final branches = widget.sessionController.allBranches;
    _selectedBranchId = branches.isNotEmpty ? branches.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('branches-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: widget.sessionController,
        builder: (context, _) {
          final branches = widget.sessionController.allBranches;
          if (!_creating && branches.isNotEmpty && !branches.any((branch) => branch.id == _selectedBranchId)) {
            _selectedBranchId = branches.first.id;
          }
          final selectedBranch = _creating || branches.isEmpty
              ? null
              : branches.firstWhere((branch) => branch.id == _selectedBranchId);

          return Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BranchesHeader(
                  onCreate: () {
                    setState(() {
                      _creating = true;
                      _selectedBranchId = null;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 38,
                        child: _BranchesList(
                          branches: branches,
                          selectedBranchId: _selectedBranchId,
                          onSelect: (branchId) {
                            setState(() {
                              _creating = false;
                              _selectedBranchId = branchId;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 62,
                        child: BranchEditorPanel(
                          key: ValueKey(_creating ? 'create-branch' : _selectedBranchId),
                          branch: selectedBranch,
                          onSave: ({
                            required name,
                            required label,
                            required isActive,
                          }) async {
                            if (_creating || selectedBranch == null) {
                              await widget.sessionController.createBranch(
                                name: name,
                                label: label,
                              );
                              setState(() {
                                _creating = false;
                                _selectedBranchId = widget.sessionController.allBranches.isNotEmpty
                                    ? widget.sessionController.allBranches.last.id
                                    : null;
                              });
                              return;
                            }

                            await widget.sessionController.updateBranch(
                              selectedBranch.copyWith(
                                name: name,
                                label: label,
                                isActive: isActive,
                              ),
                            );
                          },
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

class _BranchesHeader extends StatelessWidget {
  const _BranchesHeader({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sucursales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alta, edicion y estado.',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_business_rounded),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _BranchesList extends StatelessWidget {
  const _BranchesList({
    required this.branches,
    required this.selectedBranchId,
    required this.onSelect,
  });

  final List<SessionBranch> branches;
  final String? selectedBranchId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: branches.length,
        separatorBuilder: (context, index) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final branch = branches[index];
          final selected = branch.id == selectedBranchId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(branch.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? palette.accentSoft.withValues(alpha: 0.72) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: palette.textStrong,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            branch.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: branch.isActive
                            ? palette.success.withValues(alpha: 0.12)
                            : palette.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        branch.isActive ? 'Activa' : 'Inactiva',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: branch.isActive ? palette.success : palette.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BranchEditorPanel extends StatefulWidget {
  const BranchEditorPanel({
    super.key,
    required this.branch,
    required this.onSave,
  });

  final SessionBranch? branch;
  final Future<void> Function({
    required String name,
    required String label,
    required bool isActive,
  }) onSave;

  @override
  State<BranchEditorPanel> createState() => _BranchEditorPanelState();
}

class _BranchEditorPanelState extends State<BranchEditorPanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _labelController = TextEditingController(text: widget.branch?.label ?? '');
    _isActive = widget.branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isNew = widget.branch == null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNew ? 'Crear sucursal' : 'Editar sucursal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 16),
          _EditorField(controller: _nameController, label: 'Nombre'),
          const SizedBox(height: 12),
          _EditorField(controller: _labelController, label: 'Descripcion corta'),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Sucursal activa'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(
                  name: _nameController.text.trim(),
                  label: _labelController.text.trim().isEmpty
                      ? 'Operacion diaria'
                      : _labelController.text.trim(),
                  isActive: _isActive,
                );
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
                isNew ? 'Crear sucursal' : 'Guardar cambios',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
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
