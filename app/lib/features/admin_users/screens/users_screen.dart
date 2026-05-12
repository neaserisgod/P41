import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/models/session_context.dart';
import '../../../app/state/session_controller.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String? _selectedUserId;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final users = widget.sessionController.allUsers;
    _selectedUserId = users.isNotEmpty ? users.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('users-screen'),
      color: palette.surface,
      child: AnimatedBuilder(
        animation: widget.sessionController,
        builder: (context, _) {
          final users = widget.sessionController.allUsers;
          if (!_creating && users.isNotEmpty && !users.any((user) => user.id == _selectedUserId)) {
            _selectedUserId = users.first.id;
          }
          final selectedUser = _creating || users.isEmpty
              ? null
              : users.firstWhere((user) => user.id == _selectedUserId);

          return Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UsersHeader(
                  onCreate: () {
                    setState(() {
                      _creating = true;
                      _selectedUserId = null;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 38,
                        child: _UsersList(
                          users: users,
                          selectedUserId: _selectedUserId,
                          onSelect: (userId) {
                            setState(() {
                              _creating = false;
                              _selectedUserId = userId;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 62,
                        child: UserEditorPanel(
                          key: ValueKey(_creating ? 'create-user' : _selectedUserId),
                          user: selectedUser,
                          branches: widget.sessionController.allBranches,
                          showBranchAssignments: widget.sessionController.allBranches.length > 1,
                          onSave: ({
                            required name,
                            required role,
                            required branchIds,
                            required pin,
                            required isActive,
                          }) async {
                            if (_creating || selectedUser == null) {
                              await widget.sessionController.createUser(
                                context: context,
                                name: name,
                                role: role,
                                branchIds: branchIds,
                                pin: pin,
                              );
                              setState(() {
                                _creating = false;
                                _selectedUserId = widget.sessionController.allUsers.isNotEmpty
                                    ? widget.sessionController.allUsers.last.id
                                    : null;
                              });
                              return;
                            }

                            await widget.sessionController.updateUser(
                              selectedUser.copyWith(
                                name: name,
                                role: role,
                                branchIds: branchIds,
                                initials: _initialsFor(name),
                                pin: pin,
                                isActive: isActive,
                              ),
                              pin: pin,
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

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({
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
                'Empleados',
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
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.selectedUserId,
    required this.onSelect,
  });

  final List<SessionUser> users;
  final String? selectedUserId;
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
        itemCount: users.length,
        separatorBuilder: (context, index) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final user = users[index];
          final selected = user.id == selectedUserId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(user.id),
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
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.role,
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
                        color: user.isActive
                            ? palette.success.withValues(alpha: 0.12)
                            : palette.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: user.isActive ? palette.success : palette.danger,
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

class UserEditorPanel extends StatefulWidget {
  const UserEditorPanel({
    super.key,
    required this.user,
    required this.branches,
    required this.showBranchAssignments,
    required this.onSave,
  });

  final SessionUser? user;
  final List<SessionBranch> branches;
  final bool showBranchAssignments;
  final Future<void> Function({
    required String name,
    required String role,
    required List<String> branchIds,
    required String pin,
    required bool isActive,
  }) onSave;

  @override
  State<UserEditorPanel> createState() => _UserEditorPanelState();
}

class _UserEditorPanelState extends State<UserEditorPanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _pinController;
  late bool _isActive;
  late Set<String> _selectedBranchIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _roleController = TextEditingController(text: widget.user?.role ?? '');
    _pinController = TextEditingController(text: widget.user?.pin ?? '');
    _isActive = widget.user?.isActive ?? true;
    _selectedBranchIds = {...?widget.user?.branchIds};
    if (_selectedBranchIds.isEmpty && widget.branches.length == 1) {
      _selectedBranchIds = {widget.branches.first.id};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isNew = widget.user == null;

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
            isNew ? 'Crear usuario' : 'Editar usuario',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
          ),
          const SizedBox(height: 16),
          _EditorField(controller: _nameController, label: 'Nombre'),
          const SizedBox(height: 12),
          _EditorField(controller: _roleController, label: 'Rol'),
          const SizedBox(height: 12),
          _EditorField(controller: _pinController, label: 'PIN', keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          if (widget.showBranchAssignments) ...[
            Text(
              'Sucursales asignadas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final branch in widget.branches)
                  FilterChip(
                    label: Text(branch.name),
                    selected: _selectedBranchIds.contains(branch.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBranchIds.add(branch.id);
                        } else {
                          _selectedBranchIds.remove(branch.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Usuario activo'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(
                  name: _nameController.text.trim(),
                  role: _roleController.text.trim().isEmpty ? 'Operador' : _roleController.text.trim(),
                  branchIds: _selectedBranchIds.isEmpty && widget.branches.length == 1
                      ? [widget.branches.first.id]
                      : _selectedBranchIds.toList(),
                  pin: _pinController.text.trim(),
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
                isNew ? 'Crear usuario' : 'Guardar cambios',
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'US';
  }
  if (parts.length == 1) {
    final single = parts.first;
    return single.substring(0, single.length > 1 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
