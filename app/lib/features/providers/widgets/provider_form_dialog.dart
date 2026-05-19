import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/widgets/desktop_viewport.dart';
import '../models/provider_record.dart';

class ProviderFormResult {
  const ProviderFormResult({
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.category,
    required this.isActive,
    required this.orderDays,
    required this.deliveryDays,
  });

  final String name;
  final String contact;
  final String phone;
  final String email;
  final String category;
  final bool isActive;
  final List<int> orderDays;
  final List<int> deliveryDays;
}

class ProviderFormDialog extends StatefulWidget {
  const ProviderFormDialog({
    super.key,
    this.initialRecord,
  });

  final ProviderRecord? initialRecord;

  @override
  State<ProviderFormDialog> createState() => _ProviderFormDialogState();
}

class _ProviderFormDialogState extends State<ProviderFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _categoryController;
  late bool _isActive;
  late final Set<int> _orderDays;
  late final Set<int> _deliveryDays;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _nameController = TextEditingController(text: record?.name ?? '');
    _contactController = TextEditingController(text: record?.contact ?? '');
    _phoneController = TextEditingController(text: record?.phone ?? '');
    _emailController = TextEditingController(text: record?.email ?? '');
    _categoryController = TextEditingController(text: record?.category ?? 'General');
    _isActive = record?.isActive ?? true;
    _orderDays = {...?record?.orderDays};
    _deliveryDays = {...?record?.deliveryDays};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEditing = widget.initialRecord != null;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.viewport;
          final compact = constraints.maxWidth < 620;
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar proveedor' : 'Agregar proveedor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textStrong,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            controller: _nameController,
                            label: 'Nombre',
                            hint: 'Ej. Distribuidora Norte',
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _contactController,
                            label: 'Contacto',
                            hint: 'Ej. Juan Pérez',
                          ),
                          const SizedBox(height: 12),
                          if (compact) ...[
                            _buildField(
                              controller: _phoneController,
                              label: 'Teléfono',
                              hint: 'Ej. 387xxxxxxx',
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'Ej. ventas@proveedor.com',
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    controller: _phoneController,
                                    label: 'Teléfono',
                                    hint: 'Ej. 387xxxxxxx',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Ej. ventas@proveedor.com',
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (compact) ...[
                            _buildField(
                              controller: _categoryController,
                              label: 'Categoría',
                              hint: 'Ej. Bebidas',
                            ),
                            const SizedBox(height: 12),
                            _ActiveField(
                              isActive: _isActive,
                              onChanged: (value) =>
                                  setState(() => _isActive = value),
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    controller: _categoryController,
                                    label: 'Categoría',
                                    hint: 'Ej. Bebidas',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActiveField(
                                    isActive: _isActive,
                                    onChanged: (value) =>
                                        setState(() => _isActive = value),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),
                          _DaySelector(
                            title: 'Días de pedido',
                            selectedDays: _orderDays,
                            onToggle: (day) =>
                                setState(() => _toggleDay(_orderDays, day)),
                          ),
                          const SizedBox(height: 14),
                          _DaySelector(
                            title: 'Días de entrega',
                            selectedDays: _deliveryDays,
                            onToggle: (day) =>
                                setState(() => _toggleDay(_deliveryDays, day)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: viewport.sectionGap),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
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
                          Navigator.of(context).pop(
                            ProviderFormResult(
                              name: name,
                              contact: _contactController.text.trim(),
                              phone: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              category: _categoryController.text.trim().isEmpty
                                  ? 'General'
                                  : _categoryController.text.trim(),
                              isActive: _isActive,
                              orderDays: _orderDays.toList()..sort(),
                              deliveryDays: _deliveryDays.toList()..sort(),
                            ),
                          );
                        },
                        child: Text(isEditing ? 'Guardar' : 'Crear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  void _toggleDay(Set<int> target, int day) {
    if (target.contains(day)) {
      target.remove(day);
    } else {
      target.add(day);
    }
  }
}

class _ActiveField extends StatelessWidget {
  const _ActiveField({
    required this.isActive,
    required this.onChanged,
  });

  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isActive ? 'Operativo' : 'Inactivo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.textStrong,
              ),
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.title,
    required this.selectedDays,
    required this.onToggle,
  });

  final String title;
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const labels = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: palette.textStrong,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in labels.keys)
              FilterChip(
                selected: selectedDays.contains(day),
                label: Text(labels[day]!),
                onSelected: (_) => onToggle(day),
              ),
          ],
        ),
      ],
    );
  }
}
